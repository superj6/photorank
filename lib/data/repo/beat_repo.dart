import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/dealer/photo_state.dart';
import '../../core/rating/glicko.dart';
import '../../core/beats/beat.dart';
import '../../core/beats/beat_engine.dart';
import '../../core/beats/recap.dart';
import '../../core/rating/observation.dart';
import '../db/database.dart';

/// Two photos that have faced each other directly, with the head-to-head record.
class PairRecord {
  const PairRecord({required this.a, required this.b, required this.aWins, required this.bWins});
  final int a;
  final int b;
  final int aWins;
  final int bWins;
  int get duels => aWins + bWins;
  bool get contested => duels >= 2 && (aWins - bWins).abs() <= 1;
}

/// How far a photo moved since a point in time.
class Mover {
  const Mover({required this.photoId, required this.before, required this.after});
  final int photoId;
  final Rating before;
  final Rating after;
  double get delta => after.score - before.score;
}

/// Data behind beats: pair records, movers, snapshots, the beat log, and
/// session-derived stats (streak, minutes).
class BeatRepo {
  BeatRepo(this.db);

  final AppDatabase db;

  static const _dealtModes = ['duel', 'vibeCheck', 'rate', 'bestOfBurst', 'sort3', 'challenger', 'rerankTop'];

  /// Lifetime answered cards (Pass and browse hearts excluded).
  Future<int> decisionCount() async {
    final row = await db
        .customSelect(
          "SELECT COUNT(DISTINCT card_id) AS n FROM observations WHERE mode IN (${_dealtModes.map((m) => "'$m'").join(',')})",
          readsFrom: {db.observations},
        )
        .getSingle();
    return row.read<int>('n');
  }

  /// Answered cards whose first observation falls in [start, end).
  Future<int> decisionCountBetween(DateTime start, DateTime end) async {
    final row = await db
        .customSelect(
          "SELECT COUNT(DISTINCT card_id) AS n FROM observations WHERE mode IN (${_dealtModes.map((m) => "'$m'").join(',')}) "
          'AND created_at >= ? AND created_at < ?',
          variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
          readsFrom: {db.observations},
        )
        .getSingle();
    return row.read<int>('n');
  }

  /// Period keys of calendar recaps already generated.
  Future<Set<String>> savedRecapKeys() async {
    final rows = await (db.select(db.beats)
          ..where((b) => b.kind.isIn([BeatKind.weekly.name, BeatKind.monthly.name, BeatKind.yearly.name])))
        .get();
    final keys = <String>{};
    for (final r in rows) {
      final j = jsonDecode(r.payloadJson) as Map<String, dynamic>;
      for (final p in (j['pages'] as List)) {
        if (p['type'] == 'periodCover') {
          keys.add(Period(BeatKind.values.byName(p['kind'] as String), DateTime.parse(p['start'] as String), DateTime.parse(p['end'] as String)).key);
        }
      }
    }
    return keys;
  }

  /// Everything the recap engine needs for [period].
  Future<RecapInput> recapInput(int axisId, Period period, List<PhotoState> states, {DateTime? now}) async {
    final ts = now ?? DateTime.now();
    final all = await sessions();
    final inPeriod = all.where((s) => period.contains(s.startedAt)).toList();
    final ratingsAtStart = await ratingsAsOf(axisId, period.start);
    final settledAtStart = states.where((s) => (ratingsAtStart[s.id] ?? Rating.initial).confidence >= 0.5).length;
    final movers = await moversSince(axisId, period.start);
    final pairs = await pairRecords(axisId, since: period.start);
    return RecapInput(
      period: period,
      states: states,
      decisions: await decisionCountBetween(period.start, period.end),
      sessions: inPeriod.length,
      minutes: minutesPlayed(inPeriod).inMinutes,
      streak: streak(all.map((s) => s.startedAt), ts),
      ratingsAtStart: ratingsAtStart,
      settledAtStart: settledAtStart,
      movers: [for (final m in movers) MoverInfo(photoId: m.photoId, before: m.before, after: m.after)],
      pairs: [for (final p in pairs) PairInfo(a: p.a, b: p.b, aWins: p.aWins, bWins: p.bWins)],
      now: ts,
    );
  }

  /// Ratings as they stood at [t]: the pre-update snapshot of each photo's
  /// first observation at/after [t], else its current rating.
  Future<Map<int, Rating>> ratingsAsOf(int axisId, DateTime t, {Map<int, Rating>? current}) async {
    final rows = await (db.select(db.observations)
          ..where((o) => o.axisId.equals(axisId) & o.createdAt.isBiggerOrEqualValue(t))
          ..orderBy([(o) => OrderingTerm.asc(o.id)]))
        .get();
    final asOf = <int, Rating>{};
    for (final r in rows) {
      asOf.putIfAbsent(r.subjectId, () => Rating(mu: r.subjectMuBefore, rd: r.subjectRdBefore));
      if (r.opponentId != null) {
        asOf.putIfAbsent(r.opponentId!, () => Rating(mu: r.opponentMuBefore!, rd: r.opponentRdBefore!));
      }
    }
    final now = current ?? await _currentRatings(axisId);
    return {for (final e in now.entries) e.key: asOf[e.key] ?? e.value};
  }

  Future<Map<int, Rating>> _currentRatings(int axisId) async {
    final rows = await (db.select(db.ratings)..where((r) => r.axisId.equals(axisId))).get();
    return {for (final r in rows) r.photoId: Rating(mu: r.mu, rd: r.rd)};
  }

  /// Photos observed since [since], with their rating then vs now, largest
  /// gain first.
  Future<List<Mover>> moversSince(int axisId, DateTime since) async {
    final now = await _currentRatings(axisId);
    final then = await ratingsAsOf(axisId, since, current: now);
    final rows = await (db.select(db.observations)
          ..where((o) => o.axisId.equals(axisId) & o.createdAt.isBiggerOrEqualValue(since)))
        .get();
    final touched = <int>{for (final r in rows) ...[r.subjectId, if (r.opponentId != null) r.opponentId!]};
    final movers = [
      for (final id in touched)
        if (now[id] != null) Mover(photoId: id, before: then[id]!, after: now[id]!),
    ]..sort((a, b) => b.delta.compareTo(a.delta));
    return movers;
  }

  /// Head-to-head records for pairs that duelled at least [minDuels] times.
  Future<List<PairRecord>> pairRecords(int axisId, {int minDuels = 2, DateTime? since}) async {
    final rows = await (db.select(db.observations)
          ..where((o) {
            final base = o.axisId.equals(axisId) & o.opponentId.isNotNull() & o.mode.isIn(['duel', 'challenger']);
            return since == null ? base : base & o.createdAt.isBiggerOrEqualValue(since);
          }))
        .get();
    final wins = <(int, int), List<int>>{}; // key (lo, hi) -> [loWins, hiWins]
    for (final r in rows) {
      final s = r.subjectId, o = r.opponentId!;
      final lo = s < o ? s : o, hi = s < o ? o : s;
      final rec = wins.putIfAbsent((lo, hi), () => [0, 0]);
      final subjectWon = r.outcome == 'win';
      final loWon = (s == lo) == subjectWon;
      if (r.outcome != 'draw') rec[loWon ? 0 : 1]++;
    }
    return [
      for (final e in wins.entries)
        if (e.value[0] + e.value[1] >= minDuels)
          PairRecord(a: e.key.$1, b: e.key.$2, aWins: e.value[0], bWins: e.value[1]),
    ]..sort((x, y) => y.duels.compareTo(x.duels));
  }

  /// Rank (1-based) among rated photos, or null if unrated.
  int? rankOf(List<PhotoState> states, int photoId) {
    final rated = states.where((s) => s.observations > 0).toList()
      ..sort((a, b) => b.mu.compareTo(a.mu));
    final i = rated.indexWhere((s) => s.id == photoId);
    return i < 0 ? null : i + 1;
  }

  // ---- beat log -----------------------------------------------------------

  Future<int> saveBeat({
    required String kind,
    required int decisionCount,
    required Map<String, dynamic> payload,
    DateTime? now,
  }) =>
      db.into(db.beats).insert(BeatsCompanion.insert(
            kind: kind,
            decisionCount: decisionCount,
            createdAt: now ?? DateTime.now(),
            payloadJson: jsonEncode(payload),
          ));

  Future<List<BeatRow>> listBeats({int limit = 100}) =>
      (db.select(db.beats)..orderBy([(b) => OrderingTerm.desc(b.id)])..limit(limit)).get();

  Future<List<String>> recentBeatKinds({int limit = 6}) async =>
      (await listBeats(limit: limit)).map((b) => b.kind).toList();

  Future<void> markSeen(int id, {DateTime? now}) => (db.update(db.beats)..where((b) => b.id.equals(id)))
      .write(BeatsCompanion(seenAt: Value(now ?? DateTime.now())));

  Future<void> markShared(int id, {DateTime? now}) => (db.update(db.beats)..where((b) => b.id.equals(id)))
      .write(BeatsCompanion(sharedAt: Value(now ?? DateTime.now())));

  // ---- daily snapshots ----------------------------------------------------

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Writes today's row if missing. Returns true when a new row was written.
  Future<bool> writeDailySnapshot(List<PhotoState> states, {DateTime? now}) async {
    final ts = now ?? DateTime.now();
    final key = dayKey(ts);
    final exists = await (db.select(db.dailySnapshots)..where((s) => s.day.equals(key))).getSingleOrNull();
    if (exists != null) return false;
    final rated = states.where((s) => s.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu));
    final obs = await db.customSelect('SELECT COUNT(*) AS n FROM observations', readsFrom: {db.observations}).getSingle();
    await db.into(db.dailySnapshots).insert(DailySnapshotsCompanion.insert(
          day: key,
          photos: states.length,
          settled: states.where((s) => s.rating.confidence >= 0.5).length,
          observations: obs.read<int>('n'),
          top10Json: jsonEncode(rated.take(10).map((s) => s.id).toList()),
          createdAt: ts,
        ));
    return true;
  }

  Future<List<DailySnapshotRow>> snapshots({int limit = 60}) =>
      (db.select(db.dailySnapshots)..orderBy([(s) => OrderingTerm.desc(s.day)])..limit(limit)).get();

  static List<int> top10Of(DailySnapshotRow row) => (jsonDecode(row.top10Json) as List).cast<int>();

  // ---- session-derived stats ---------------------------------------------

  Future<List<SessionRow>> sessions() =>
      (db.select(db.sessions)..orderBy([(s) => OrderingTerm.asc(s.startedAt)])).get();

  /// Consecutive days (ending today or yesterday) with at least one session.
  static int streak(Iterable<DateTime> sessionStarts, DateTime now) {
    final days = {for (final d in sessionStarts) dayKey(d)};
    if (days.isEmpty) return 0;
    var cursor = DateTime(now.year, now.month, now.day);
    if (!days.contains(dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(dayKey(cursor))) return 0;
    }
    var n = 0;
    while (days.contains(dayKey(cursor))) {
      n++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return n;
  }

  static Duration minutesPlayed(Iterable<SessionRow> rows) => rows.fold(
        Duration.zero,
        (acc, s) => s.endedAt == null ? acc : acc + s.endedAt!.difference(s.startedAt),
      );
}

/// Which dealt mode a raw `observations.mode` string names, if any.
GameMode? modeFromName(String name) {
  for (final m in GameMode.values) {
    if (m.name == name) return m;
  }
  return null;
}
