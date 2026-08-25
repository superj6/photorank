import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/rating/observation.dart';
import 'package:photorank/data/db/database.dart';
import 'package:photorank/data/media/scanned_asset.dart';
import 'package:photorank/data/repo/axis_repo.dart';
import 'package:photorank/data/repo/photo_repo.dart';
import 'package:photorank/data/repo/ranking_repo.dart';

void main() {
  test('axes: add, switch, rank independently, delete cleans up', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final axes = AxisRepo(db);
    final ranking = RankingRepo(db);
    await PhotoRepo(db).upsertAssets([const ScannedAsset(mediaId: 'a'), const ScannedAsset(mediaId: 'b')]);
    final love = await db.defaultAxisId();
    expect(await axes.current(), love);
    final funny = await axes.add('Funny');
    await axes.setCurrent(funny);
    expect(await axes.current(), funny);
    final now = DateTime(2026, 8, 24);
    await ranking.applyCard(Decompose.rate(axisId: funny, cardId: 'f', photoId: 1, stars: 5, now: now));
    await ranking.applyCard(Decompose.rate(axisId: love, cardId: 'l', photoId: 1, stars: 1, now: now));
    expect((await ranking.ratingOf(funny, 1)).mu, greaterThan((await ranking.ratingOf(love, 1)).mu));
    expect((await axes.all()).length, 2);
    expect(await axes.delete(love), isFalse, reason: 'default axis cannot be deleted');
    expect(await axes.delete(funny), isTrue);
    expect((await axes.all()).length, 1);
    expect(await axes.current(), love, reason: 'falls back to the default after deletion');
    expect(await ranking.observationCount(), 5, reason: 'only the deleted axis\'s observations are gone');
  });
}
