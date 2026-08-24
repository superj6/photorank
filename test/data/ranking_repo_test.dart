import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/rating/glicko.dart';
import 'package:photorank/core/rating/observation.dart';
import 'package:photorank/data/db/database.dart';
import 'package:photorank/data/media/scanned_asset.dart';
import 'package:photorank/data/repo/photo_repo.dart';
import 'package:photorank/data/repo/ranking_repo.dart';

void main() {
  late AppDatabase db;
  late PhotoRepo photos;
  late RankingRepo ranking;
  late int axis;
  final now = DateTime(2026, 8, 24, 10);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    photos = PhotoRepo(db);
    ranking = RankingRepo(db);
    axis = await db.defaultAxisId();
    await photos.upsertAssets([
      for (var i = 0; i < 12; i++)
        ScannedAsset(
          mediaId: 'm$i',
          takenAt: now.subtract(Duration(seconds: i < 4 ? i * 3 : i * 3600)),
          width: 100,
          height: 100,
        ),
    ], now: now);
  });

  tearDown(() => db.close());

  test('default axis exists and photos are unrated at initial', () async {
    final states = await ranking.photoStates(axis);
    expect(states.length, 12);
    expect(states.every((s) => s.rating == Rating.initial), isTrue);
  });

  test('upsert is idempotent and preserves lastShownAt', () async {
    await ranking.applyCard(
        Decompose.vibe(axisId: axis, cardId: 'c1', photoId: 1, feelingIt: true, now: now),
        now: now);
    await photos.upsertAssets([const ScannedAsset(mediaId: 'm0', width: 200, height: 50)]);
    expect(await photos.count(), 12);
    final p = await photos.byId(1);
    expect(p!.width, 200);
    expect(p.lastShownAt, now);
  });

  test('applyCard updates both sides, logs snapshots, marks shown', () async {
    final delta = await ranking.applyCard(
        Decompose.duel(axisId: axis, cardId: 'd1', winnerId: 1, loserId: 2, now: now),
        now: now);
    expect(delta.after[1]!.mu, greaterThan(delta.after[2]!.mu));
    expect((await ranking.ratingOf(axis, 1)).mu, delta.after[1]!.mu);
    expect(await ranking.observationCount(), 1);
    expect((await photos.byId(1))!.lastShownAt, now);
    expect((await photos.byId(3))!.lastShownAt, isNull);
  });

  test('undoCard restores exactly, even across chained cards', () async {
    await ranking.applyCard(
        Decompose.rate(axisId: axis, cardId: 'r1', photoId: 1, stars: 5, now: now));
    final afterFirst = await ranking.ratingOf(axis, 1);
    await ranking.applyCard(
        Decompose.sort(axisId: axis, cardId: 's1', orderedIds: [2, 1, 3], now: now));
    expect(await ranking.lastCardId(), 's1');
    await ranking.undoCard('s1');
    expect(await ranking.ratingOf(axis, 1), afterFirst);
    expect(await ranking.ratingOf(axis, 2), Rating.initial);
    expect(await ranking.ratingOf(axis, 3), Rating.initial);
    expect(await ranking.observationCount(), 5);
    expect(await ranking.lastCardId(), 'r1');
  });

  test('ranking stream orders best first', () async {
    await ranking.applyCard(
        Decompose.rate(axisId: axis, cardId: 'a', photoId: 5, stars: 5, now: now));
    await ranking.applyCard(
        Decompose.rate(axisId: axis, cardId: 'b', photoId: 6, stars: 1, now: now));
    final ranked = await ranking.watchRanking(axis).first;
    expect(ranked.first.id, 5);
    expect(ranked.last.id, 6);
  });

  test('clusters bursts once and exposes only unresolved ones', () async {
    expect(await photos.clusterNewPhotos(), 1); // photos 1-4 are 3s apart
    expect(await photos.clusterNewPhotos(), 0);
    final bursts = await ranking.eligibleBursts(axis);
    expect(bursts.length, 1);
    expect(bursts.single.map((s) => s.id).toSet(), {1, 2, 3, 4});
    await photos.resolveCluster(bursts.single.first.clusterId!);
    expect(await ranking.eligibleBursts(axis), isEmpty);
  });

  test('sortedFraction grows with evidence', () async {
    expect(await ranking.sortedFraction(axis), 0);
    for (var i = 0; i < 6; i++) {
      await ranking.applyCard(
          Decompose.rate(axisId: axis, cardId: 'k$i', photoId: 7, stars: 3, now: now));
    }
    expect(await ranking.sortedFraction(axis), closeTo(1 / 12, 1e-9));
  });

  test('recordView bumps views and prefs round-trip', () async {
    await photos.recordView(3, source: 'flow');
    await photos.recordView(3, source: 'flow');
    expect((await photos.byId(3))!.views, 2);
    await photos.setPref('streak', '4');
    expect(await photos.pref('streak'), '4');
  });
}
