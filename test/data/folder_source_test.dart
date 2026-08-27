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
import 'package:photorank/data/repo/photo_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
