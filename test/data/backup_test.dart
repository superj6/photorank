import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/rating/observation.dart';
import 'package:photorank/data/db/backup.dart';
import 'package:photorank/data/db/database.dart';
import 'package:photorank/data/media/scanned_asset.dart';
import 'package:photorank/data/repo/photo_repo.dart';
import 'package:photorank/data/repo/ranking_repo.dart';

void main() {
  test('backup: snapshot via VACUUM INTO, validate counts, reject junk and newer versions', () async {
    final dir = Directory.systemTemp.createTempSync('prbk');
    addTearDown(() => dir.deleteSync(recursive: true));
    final live = File('${dir.path}/live.sqlite');
    final db = AppDatabase(NativeDatabase(live));
    await PhotoRepo(db).upsertAssets([const ScannedAsset(mediaId: 'a'), const ScannedAsset(mediaId: 'b')]);
    final axis = await db.defaultAxisId();
    await RankingRepo(db).applyCard(Decompose.duel(axisId: axis, cardId: 'c', winnerId: 1, loserId: 2, now: DateTime(2026)));
    final out = File('${dir.path}/snap.sqlite');
    await db.customStatement('VACUUM INTO ?', [out.path]);
    await db.close();
    final info = await DbBackup.validate(out);
    expect(info.photos, 2);
    expect(info.decisions, 1);
    expect(info.schemaVersion, 4);

    final junk = File('${dir.path}/junk.bin')..writeAsBytesSync(List.filled(64, 7));
    await expectLater(DbBackup.validate(junk), throwsA(predicate((e) => '$e'.contains('not a PhotoRank backup'))));

    final future = AppDatabase(NativeDatabase(File('${dir.path}/future.sqlite')));
    await future.customStatement('PRAGMA user_version = 99');
    await future.close();
    await expectLater(DbBackup.validate(File('${dir.path}/future.sqlite')), throwsA(predicate((e) => '$e'.contains('newer version'))));

    // Restored file opens as a working database.
    final restored = AppDatabase(NativeDatabase(out));
    expect((await restored.customSelect('SELECT count(*) AS n FROM observations').getSingle()).read<int>('n'), 1);
    await restored.close();
  });
}
