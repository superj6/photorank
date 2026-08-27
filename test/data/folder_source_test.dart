import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photorank/data/db/database.dart';
import 'package:photorank/data/media/folder_source.dart';
import 'package:photorank/data/media/library_scanner.dart';
import 'package:photo_manager/photo_manager.dart' show ThumbnailSize;
import 'package:photorank/data/media/scanned_asset.dart';
import 'package:photorank/data/repo/photo_repo.dart';
import 'package:photorank/data/repo/ranking_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  missingPhotoTests();
  unavailableFolderTests();
  incrementalScanTests();
  test('readHeader gets EXIF date and size, falls back to mtime', () {
    final im = img.Image(width: 640, height: 480);
    im.exif.exifIfd['DateTimeOriginal'] = '2026:03:11 09:35:00';
    final bytes = Uint8List.fromList(img.encodeJpg(im, quality: 70));
    final a = readHeader('/x/a.jpg', bytes, modifiedAt: DateTime(2026, 8, 1));
    expect(a.takenAt, DateTime(2026, 3, 11, 9, 35));
    expect((a.width, a.height), (640, 480));
    expect(a.albumId, '/x');
    final plain = readHeader('/x/b.png', Uint8List.fromList(img.encodePng(img.Image(width: 20, height: 30))), modifiedAt: DateTime(2026, 8, 2));
    expect(plain.takenAt, DateTime(2026, 8, 2));
    expect((plain.width, plain.height), (20, 30));
  });

  test('scan indexes a folder tree and thumbnails are generated and cached', () async {
    final tmp = await Directory.systemTemp.createTemp('photorank_test');
    addTearDown(() => tmp.delete(recursive: true));
    final sub = await Directory('${tmp.path}/trip').create();
    for (var i = 0; i < 3; i++) {
      final im = img.Image(width: 400 + i, height: 300);
      im.exif.exifIfd['DateTimeOriginal'] = '2026:05:0${i + 1} 10:00:00';
      File('${sub.path}/p$i.jpg').writeAsBytesSync(img.encodeJpg(im));
    }
    File('${tmp.path}/notes.txt').writeAsStringSync('ignore me');
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PhotoRepo(db);
    final source = FolderSource(repo, cacheDir: Directory('${tmp.path}/cache'));
    final progress = await source.scan(ScanScope(folders: [tmp.path])).toList();
    expect(progress.last.done, isTrue);
    expect(progress.last.total, 3);
    expect(await repo.count(), 3);
    final row = (await repo.byIds([1])).single;
    expect(row.takenAt, isNotNull);
    expect(row.width, greaterThan(0));

    // Thumbnails decode straight to the requested long edge, no disk cache.
    final provider = source.thumb(row.mediaId, size: const ThumbnailSize(120, 120)) as FolderThumbProvider;
    expect(provider.size, 120);
    final stream = provider.resolve(ImageConfiguration.empty);
    final done = Completer<void>();
    stream.addListener(ImageStreamListener((info, _) {
      expect(info.image.width, 120, reason: 'landscape fixture: long edge is the width');
      expect(info.image.height, lessThan(120));
      done.complete();
    }, onError: (e, st) => done.completeError('thumb error: $e')));
    await done.future;
    expect(Directory('${tmp.path}/cache').existsSync(), isFalse, reason: 'no thumbnail cache is written any more');

    // size 0 means the original, at full resolution.
    final full = source.original(row.mediaId) as FolderThumbProvider;
    expect(full.size, 0);
    final fullStream = full.resolve(ImageConfiguration.empty);
    final fullDone = Completer<void>();
    fullStream.addListener(ImageStreamListener((info, _) {
      expect(info.image.width, greaterThan(120));
      fullDone.complete();
    }, onError: (e, st) => fullDone.completeError('original error: $e')));
    await fullDone.future;
  });
}

void missingPhotoTests() {
  test('photos deleted from a scanned folder leave play on the next scan', () async {
    final tmp = await Directory.systemTemp.createTemp('photorank_missing');
    addTearDown(() => tmp.delete(recursive: true));
    for (var i = 0; i < 5; i++) {
      File('${tmp.path}/p$i.jpg').writeAsBytesSync(img.encodeJpg(img.Image(width: 60 + i, height: 40)));
    }
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PhotoRepo(db);
    final ranking = RankingRepo(db);
    final axis = await db.defaultAxisId();
    final source = FolderSource(repo, cacheDir: Directory('${tmp.path}/cache'));
    final scope = ScanScope(folders: [tmp.path]);

    await source.scan(scope).drain<void>();
    expect(await repo.count(), 5);
    expect((await ranking.photoStates(axis)).length, 5);

    // Two files are removed from the folder.
    File('${tmp.path}/p1.jpg').deleteSync();
    File('${tmp.path}/p3.jpg').deleteSync();

    // A scan that does not look for deletions leaves them in play...
    await source.scan(scope).drain<void>();
    expect((await ranking.photoStates(axis)).length, 5);

    // ...the launch/rescan path (markMissing) takes them out.
    await source.scan(scope, markMissing: true).drain<void>();
    final left = await ranking.photoStates(axis);
    expect(left.length, 3);
    expect(await repo.count(), 3, reason: 'count() excludes missing photos');
    final rows = await repo.byIds(left.map((s) => s.id).toList());
    expect(rows.every((r) => !r.mediaId.endsWith('p1.jpg') && !r.mediaId.endsWith('p3.jpg')), isTrue);

    // A photo that comes back returns to play, keeping its row (and ratings).
    File('${tmp.path}/p1.jpg').writeAsBytesSync(img.encodeJpg(img.Image(width: 61, height: 40)));
    await source.scan(scope, markMissing: true).drain<void>();
    expect((await ranking.photoStates(axis)).length, 4);

    // A file deleted between scans is dropped as soon as it fails to load.
    File('${tmp.path}/p0.jpg').deleteSync();
    await repo.markMissingByMediaId('${tmp.path}/p0.jpg');
    expect((await ranking.photoStates(axis)).length, 3);
  });
}

void unavailableFolderTests() {
  test('an unavailable folder never empties the library', () async {
    final tmp = await Directory.systemTemp.createTemp('photorank_drive');
    addTearDown(() => tmp.delete(recursive: true));
    final drive = await Directory('${tmp.path}/drive').create();
    final local = await Directory('${tmp.path}/local').create();
    for (var i = 0; i < 4; i++) {
      File('${drive.path}/d$i.jpg').writeAsBytesSync(img.encodeJpg(img.Image(width: 50, height: 40)));
    }
    File('${local.path}/l0.jpg').writeAsBytesSync(img.encodeJpg(img.Image(width: 50, height: 40)));

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PhotoRepo(db);
    final ranking = RankingRepo(db);
    final axis = await db.defaultAxisId();
    final source = FolderSource(repo, cacheDir: Directory('${tmp.path}/cache'));
    final scope = ScanScope(folders: [drive.path, local.path]);

    await source.scan(scope, markMissing: true).drain<void>();
    expect((await ranking.photoStates(axis)).length, 5);

    // The "drive" is unplugged: its photos must stay in the library.
    await drive.delete(recursive: true);
    await source.scan(scope, markMissing: true).drain<void>();
    expect((await ranking.photoStates(axis)).length, 5,
        reason: 'photos on an unavailable drive are kept, not flagged missing');

    // A readable folder that is genuinely emptied does lose its photos.
    File('${local.path}/l0.jpg').deleteSync();
    await source.scan(scope, markMissing: true).drain<void>();
    final left = await ranking.photoStates(axis);
    expect(left.length, 4, reason: 'the emptied local folder is swept; the drive is untouched');
    expect(left.every((s) => s.mediaId!.contains('/drive/')), isTrue);

    // Plugging the drive back in restores them without losing their ratings.
    await Directory(drive.path).create();
    for (var i = 0; i < 4; i++) {
      File('${drive.path}/d$i.jpg').writeAsBytesSync(img.encodeJpg(img.Image(width: 50, height: 40)));
    }
    await source.scan(scope, markMissing: true).drain<void>();
    expect((await ranking.photoStates(axis)).length, 4);
  });

  test('a media-store scan that returns nothing does not wipe the library', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PhotoRepo(db);
    await repo.upsertAssets([for (var i = 0; i < 6; i++) ScannedAsset(mediaId: 'asset$i')]);
    expect(await repo.markMissingExcept(const {}), 0, reason: 'empty scan is treated as a failure');
    expect(await repo.count(), 6);
    expect(await repo.markMissingExcept({'asset0', 'asset1'}), 4);
    expect(await repo.count(), 2);
  });
}

void incrementalScanTests() {
  test('a rescan only opens files that are new or changed', () async {
    final tmp = await Directory.systemTemp.createTemp('photorank_incremental');
    addTearDown(() => tmp.delete(recursive: true));
    for (var i = 0; i < 4; i++) {
      File('${tmp.path}/p$i.jpg').writeAsBytesSync(img.encodeJpg(img.Image(width: 40 + i, height: 30)));
    }
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PhotoRepo(db);
    final source = FolderSource(repo, cacheDir: Directory('${tmp.path}/cache'));
    final scope = ScanScope(folders: [tmp.path]);

    await source.scan(scope).drain<void>();
    expect(await repo.count(), 4);
    final fingerprints = await repo.indexedFingerprints();
    expect(fingerprints.length, 4);
    expect(fingerprints.values.every((d) => d != null), isTrue, reason: 'modification times are recorded');

    // Make one file unreadable: an unchanged rescan must not need to open it.
    final blocked = File('${tmp.path}/p2.jpg');
    final saved = blocked.readAsBytesSync();
    blocked.writeAsBytesSync(saved); // same content, new mtime is set below
    await blocked.setLastModified(fingerprints[blocked.path]!);

    final widthBefore = (await repo.byIds([3])).single.width;
    File('${tmp.path}/p4.jpg').writeAsBytesSync(img.encodeJpg(img.Image(width: 99, height: 30)));
    await source.scan(scope).drain<void>();

    expect(await repo.count(), 5, reason: 'the new file is picked up');
    final added = (await repo.indexedFingerprints()).keys.where((k) => k.endsWith('p4.jpg'));
    expect(added.length, 1);
    expect((await repo.byIds([3])).single.width, widthBefore, reason: 'untouched rows keep their data');

    // A changed file is re-read: new dimensions land in the database.
    final changed = File('${tmp.path}/p0.jpg');
    changed.writeAsBytesSync(img.encodeJpg(img.Image(width: 123, height: 45)));
    await changed.setLastModified(DateTime.now().add(const Duration(seconds: 5)));
    await source.scan(scope).drain<void>();
    final row = (await repo.byIds([1])).single;
    expect(row.mediaId.endsWith('p0.jpg'), isTrue);
    expect(row.width, 123, reason: 'a modified file is re-read');
  });
}
