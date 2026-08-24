import 'package:drift/drift.dart';

import '../../core/dealer/photo_state.dart';
import '../../core/rating/engine.dart';
import '../../core/rating/glicko.dart';
import '../../core/rating/observation.dart';
import '../db/database.dart';

/// Ratings and the observation log. Every write goes through [applyCard] so
/// snapshots for [undoCard] are always present.
class RankingRepo {
  // ignore: prefer_initializing_formals
  RankingRepo(this.db, {RatingEngine engine = const RatingEngine()}) : _engine = engine;


  final AppDatabase db;
  final RatingEngine _engine;

  Future<Map<int, RatingRow>> _rows(int axisId, Iterable<int> ids) async {
    final rows = await (db.select(db.ratings)
          ..where((r) => r.axisId.equals(axisId) & r.photoId.isIn(ids.toList())))
        .get();
    return {for (final r in rows) r.photoId: r};
  }

  Future<Rating> ratingOf(int axisId, int photoId) async {
    final r = (await _rows(axisId, [photoId]))[photoId];
    return r == null ? Rating.initial : Rating(mu: r.mu, rd: r.rd);
  }

  /// Applies a card's observations atomically and marks its photos as shown.
  Future<RatingDelta> applyCard(List<Observation> observations,
      {int? sessionId, DateTime? now}) async {
    if (observations.isEmpty) return const RatingDelta(before: {}, after: {});
    final axisId = observations.first.axisId;
    final ids = <int>{
      for (final o in observations) ...[o.subjectId, if (o.opponentId != null) o.opponentId!],
    };
    final ts = now ?? DateTime.now();
    return db.transaction(() async {
      final existing = await _rows(axisId, ids);
      final current = <int, Rating>{
        for (final e in existing.entries) e.key: Rating(mu: e.value.mu, rd: e.value.rd),
      };
      final before = <int, Rating>{};
      final added = <int, int>{};
      Rating look(int id) => current[id] ?? Rating.initial;

      for (final o in observations) {
        final d = _engine.apply(o, look);
        final sb = d.before[o.subjectId]!;
        final ob = o.opponentId == null ? null : d.before[o.opponentId!]!;
        await db.into(db.observations).insert(ObservationsCompanion.insert(
              axisId: axisId,
              sessionId: Value(sessionId),
              cardId: o.cardId,
              mode: o.mode.name,
              subjectId: o.subjectId,
              opponentId: Value(o.opponentId),
              anchorMu: Value(o.anchorMu),
              outcome: o.outcome.name,
              weight: Value(o.weight),
              createdAt: o.createdAt,
              subjectMuBefore: sb.mu,
              subjectRdBefore: sb.rd,
              opponentMuBefore: Value(ob?.mu),
              opponentRdBefore: Value(ob?.rd),
            ));
        for (final e in d.before.entries) {
          before.putIfAbsent(e.key, () => e.value);
        }
        current.addAll(d.after);
        for (final id in d.after.keys) {
          added[id] = (added[id] ?? 0) + 1;
        }
      }

      for (final id in ids) {
        final r = current[id]!;
        await db.into(db.ratings).insertOnConflictUpdate(RatingsCompanion(
              photoId: Value(id),
              axisId: Value(axisId),
              mu: Value(r.mu),
              rd: Value(r.rd),
              observations: Value((existing[id]?.observations ?? 0) + (added[id] ?? 0)),
              updatedAt: Value(ts),
            ));
      }
      await (db.update(db.photos)..where((p) => p.id.isIn(ids.toList())))
          .write(PhotosCompanion(lastShownAt: Value(ts)));
      return RatingDelta(before: before, after: {for (final id in ids) id: current[id]!});
    });
  }

  /// Restores every rating touched by [cardId] to its pre-card value.
  Future<void> undoCard(String cardId) => db.transaction(() async {
        final rows = await (db.select(db.observations)
              ..where((o) => o.cardId.equals(cardId))
              ..orderBy([(o) => OrderingTerm.desc(o.id)]))
            .get();
        for (final r in rows) {
          await _restore(r.axisId, r.subjectId, r.subjectMuBefore, r.subjectRdBefore);
          if (r.opponentId != null) {
            await _restore(r.axisId, r.opponentId!, r.opponentMuBefore!, r.opponentRdBefore!);
          }
          await (db.delete(db.observations)..where((o) => o.id.equals(r.id))).go();
        }
      });

  Future<void> _restore(int axisId, int photoId, double mu, double rd) =>
      db.customUpdate(
        'UPDATE ratings SET mu = ?, rd = ?, observations = MAX(observations - 1, 0) '
        'WHERE photo_id = ? AND axis_id = ?',
        variables: [
          Variable.withReal(mu),
          Variable.withReal(rd),
          Variable.withInt(photoId),
          Variable.withInt(axisId),
        ],
        updates: {db.ratings},
      );

  /// Id of the most recently applied card, if any.
  Future<String?> lastCardId() async {
    final row = await (db.select(db.observations)
          ..orderBy([(o) => OrderingTerm.desc(o.id)])
          ..limit(1))
        .getSingleOrNull();
    return row?.cardId;
  }

  JoinedSelectStatement<HasResultSet, dynamic> _stateQuery(int axisId) =>
      db.select(db.photos).join([
        leftOuterJoin(
          db.ratings,
          db.ratings.photoId.equalsExp(db.photos.id) & db.ratings.axisId.equals(axisId),
        ),
      ])
        ..where(db.photos.missing.equals(false));

  PhotoState _toState(TypedResult row) {
    final p = row.readTable(db.photos);
    final r = row.readTableOrNull(db.ratings);
    return PhotoState(
      id: p.id,
      rating: r == null ? Rating.initial : Rating(mu: r.mu, rd: r.rd),
      takenAt: p.takenAt,
      addedAt: p.addedAt,
      lastShownAt: p.lastShownAt,
      clusterId: p.clusterId,
      observations: r?.observations ?? 0,
      views: p.views,
    );
  }

  /// Every present photo with its rating on [axisId] (initial if unrated).
  Future<List<PhotoState>> photoStates(int axisId) async =>
      (await _stateQuery(axisId).get()).map(_toState).toList();

  /// Live ranking, best first.
  Stream<List<PhotoState>> watchRanking(int axisId) {
    final q = _stateQuery(axisId)
      ..orderBy([OrderingTerm.desc(coalesce([db.ratings.mu, Constant(Rating.initialMu)]))]);
    return q.watch().map((rows) => rows.map(_toState).toList());
  }

  /// Burst clusters nobody has won yet, as lists of states.
  Future<List<List<PhotoState>>> eligibleBursts(int axisId) async {
    final open = await (db.select(db.clusters)..where((c) => c.resolved.equals(false))).get();
    if (open.isEmpty) return const [];
    final openIds = open.map((c) => c.id).toSet();
    final states = await photoStates(axisId);
    final grouped = <int, List<PhotoState>>{};
    for (final s in states) {
      if (s.clusterId != null && openIds.contains(s.clusterId)) {
        grouped.putIfAbsent(s.clusterId!, () => []).add(s);
      }
    }
    return grouped.values.where((c) => c.length >= 3).toList();
  }

  /// Share of photos whose rating has settled (confidence ≥ 0.5).
  Future<double> sortedFraction(int axisId) async {
    final states = await photoStates(axisId);
    if (states.isEmpty) return 0;
    final settled = states.where((s) => s.rating.confidence >= 0.5).length;
    return settled / states.length;
  }

  Future<int> observationCount() async {
    final q = db.selectOnly(db.observations)..addColumns([db.observations.id.count()]);
    return (await q.getSingle()).read(db.observations.id.count()) ?? 0;
  }
}
