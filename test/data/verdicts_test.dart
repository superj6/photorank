import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/rating/observation.dart';
import 'package:photorank/data/db/database.dart';
import 'package:photorank/data/media/scanned_asset.dart';
import 'package:photorank/data/repo/photo_repo.dart';
import 'package:photorank/data/repo/ranking_repo.dart';

void main() {
  test('verdicts: latest stars and vibe per photo, none when never asked', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final photos = PhotoRepo(db);
    final ranking = RankingRepo(db);
    await photos.upsertAssets([const ScannedAsset(mediaId: 'a'), const ScannedAsset(mediaId: 'b')]);
    final axis = await db.defaultAxisId();
    final t = DateTime(2026, 8, 28);
    expect((await photos.verdicts(axis, 1)).any, isFalse);
    await ranking.applyCard(Decompose.rate(axisId: axis, cardId: 'r1', photoId: 1, stars: 2, now: t));
    await ranking.applyCard(Decompose.rate(axisId: axis, cardId: 'r2', photoId: 1, stars: 4, now: t.add(const Duration(minutes: 1))));
    await ranking.applyCard(Decompose.vibe(axisId: axis, cardId: 'v1', photoId: 1, feelingIt: false, now: t.add(const Duration(minutes: 2))));
    await ranking.applyCard(Decompose.vibe(axisId: axis, cardId: 'v2', photoId: 1, feelingIt: true, now: t.add(const Duration(minutes: 3))));
    await ranking.applyCard(Decompose.duel(axisId: axis, cardId: 'd1', winnerId: 1, loserId: 2, now: t.add(const Duration(minutes: 4))));
    final v = await photos.verdicts(axis, 1);
    expect(v.stars, 4, reason: 'latest rating wins');
    expect(v.timesRated, 2);
    expect(v.latestVibe, isTrue);
    expect(v.feeling, 1);
    expect(v.notFeeling, 1);
    final other = await photos.verdicts(axis, 2);
    expect(other.any, isFalse, reason: 'a duel is not a star or vibe verdict');
    // Undo the last vibe: the earlier "not feeling it" is the latest again.
    await ranking.undoCard('v2');
    expect((await photos.verdicts(axis, 1)).latestVibe, isFalse);
  });
}
