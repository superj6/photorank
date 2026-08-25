import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/rating/glicko.dart';
import 'package:photorank/core/rating/observation.dart';
import 'package:photorank/data/db/database.dart';
import 'package:photorank/data/media/scanned_asset.dart';
import 'package:photorank/data/repo/beat_repo.dart';
import 'package:photorank/data/repo/photo_repo.dart';
import 'package:photorank/data/repo/ranking_repo.dart';

void main() {
  late AppDatabase db;
  late PhotoRepo photos;
  late RankingRepo ranking;
  late BeatRepo beats;
  late int axis;
  final t0 = DateTime(2026, 8, 20, 10);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    photos = PhotoRepo(db);
    ranking = RankingRepo(db);
    beats = BeatRepo(db);
    axis = await db.defaultAxisId();
    await photos.upsertAssets([
      for (var i = 0; i < 10; i++) ScannedAsset(mediaId: 'm$i', takenAt: t0, width: 1, height: 1),
    ], now: t0);
  });

  tearDown(() => db.close());

  test('decisionCount counts answered cards, not hearts or passes', () async {
    await ranking.applyCard(Decompose.rate(axisId: axis, cardId: 'a', photoId: 1, stars: 4, now: t0));
    await ranking.applyCard(Decompose.duel(axisId: axis, cardId: 'b', winnerId: 1, loserId: 2, now: t0));
    await ranking.applyCard(Decompose.heart(axisId: axis, cardId: 'h', photoId: 3, now: t0));
    expect(await beats.decisionCount(), 2);
  });

  test('ratingsAsOf reproduces the rating a photo had at a point in time', () async {
    await ranking.applyCard(Decompose.rate(axisId: axis, cardId: 'a', photoId: 1, stars: 5, now: t0));
    final afterA = await ranking.ratingOf(axis, 1);
    final t1 = t0.add(const Duration(hours: 1));
    await ranking.applyCard(Decompose.duel(axisId: axis, cardId: 'b', winnerId: 2, loserId: 1, now: t1));
    await ranking.applyCard(Decompose.duel(axisId: axis, cardId: 'c', winnerId: 3, loserId: 1, now: t1.add(const Duration(minutes: 5))));
    final asOf = await beats.ratingsAsOf(axis, t1);
    expect(asOf[1], afterA);
    expect(asOf[2], Rating.initial);
    expect(asOf[1]!.mu, greaterThan((await ranking.ratingOf(axis, 1)).mu));
    // Photos untouched since t1 report their current rating.
    final asOfLater = await beats.ratingsAsOf(axis, t1.add(const Duration(days: 1)));
    expect(asOfLater[1], await ranking.ratingOf(axis, 1));
  });

  test('moversSince ranks biggest gains first', () async {
    final t1 = t0.add(const Duration(hours: 1));
    await ranking.applyCard(Decompose.rate(axisId: axis, cardId: 'a', photoId: 4, stars: 5, now: t1));
    await ranking.applyCard(Decompose.rate(axisId: axis, cardId: 'b', photoId: 5, stars: 3, now: t1));
    final movers = await beats.moversSince(axis, t1);
    expect(movers.first.photoId, 4);
    expect(movers.first.delta, greaterThan(0));
    expect(movers.map((m) => m.photoId), containsAll([4, 5]));
  });

  test('pairRecords aggregates head-to-head duels regardless of order', () async {
    await ranking.applyCard(Decompose.duel(axisId: axis, cardId: 'a', winnerId: 1, loserId: 2, now: t0));
    await ranking.applyCard(Decompose.duel(axisId: axis, cardId: 'b', winnerId: 2, loserId: 1, now: t0));
    await ranking.applyCard(Decompose.duel(axisId: axis, cardId: 'c', winnerId: 1, loserId: 2, now: t0));
    await ranking.applyCard(Decompose.duel(axisId: axis, cardId: 'd', winnerId: 3, loserId: 4, now: t0));
    final records = await beats.pairRecords(axis);
    expect(records.length, 1);
    expect((records.single.a, records.single.b, records.single.aWins, records.single.bWins), (1, 2, 2, 1));
    expect(records.single.contested, isTrue);
  });

  test('daily snapshot is written once per day and stores the top 10', () async {
    await ranking.applyCard(Decompose.rate(axisId: axis, cardId: 'a', photoId: 6, stars: 5, now: t0));
    final states = await ranking.photoStates(axis);
    expect(await beats.writeDailySnapshot(states, now: t0), isTrue);
    expect(await beats.writeDailySnapshot(states, now: t0.add(const Duration(hours: 3))), isFalse);
    final rows = await beats.snapshots();
    expect(rows.single.photos, 10);
    expect(BeatRepo.top10Of(rows.single), [6]);
  });

  test('beat log round-trips and rankOf counts rated photos only', () async {
    final id = await beats.saveBeat(kind: 'standings', decisionCount: 20, payload: {'top': [1]}, now: t0);
    await beats.markSeen(id, now: t0);
    final rows = await beats.listBeats();
    expect(rows.single.kind, 'standings');
    expect(rows.single.seenAt, t0);
    expect(await beats.recentBeatKinds(), ['standings']);
    await ranking.applyCard(Decompose.rate(axisId: axis, cardId: 'a', photoId: 7, stars: 5, now: t0));
    await ranking.applyCard(Decompose.rate(axisId: axis, cardId: 'b', photoId: 8, stars: 2, now: t0));
    final states = await ranking.photoStates(axis);
    expect(beats.rankOf(states, 7), 1);
    expect(beats.rankOf(states, 8), 2);
    expect(beats.rankOf(states, 9), isNull);
  });

  test('streak and minutes derive from sessions', () {
    final now = DateTime(2026, 8, 24, 20);
    expect(BeatRepo.streak([], now), 0);
    expect(
      BeatRepo.streak([
        DateTime(2026, 8, 24, 8),
        DateTime(2026, 8, 23, 9),
        DateTime(2026, 8, 22, 9),
        DateTime(2026, 8, 19, 9),
      ], now),
      3,
    );
    // Yesterday counts if today has no session yet.
    expect(BeatRepo.streak([DateTime(2026, 8, 23, 9), DateTime(2026, 8, 22, 9)], now), 2);
    expect(BeatRepo.streak([DateTime(2026, 8, 21, 9)], now), 0);
  });

  test('schema v2 migration path opens on a fresh database with unlock_all unset', () async {
    expect(await photos.pref('unlock_all'), isNull);
  });
}
