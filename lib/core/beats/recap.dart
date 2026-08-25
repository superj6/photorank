import '../dealer/photo_state.dart';
import '../rating/glicko.dart';
import 'beat.dart';
import 'beat_engine.dart';

/// A calendar period a recap covers. [end] is exclusive.
class Period {
  const Period(this.kind, this.start, this.end);
  final BeatKind kind;
  final DateTime start;
  final DateTime end;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  String get key => '${kind.name}:${start.toIso8601String().substring(0, 10)}';

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String get label {
    final last = end.subtract(const Duration(days: 1));
    return switch (kind) {
      BeatKind.weekly => '${_months[start.month - 1]} ${start.day} – ${_months[last.month - 1]} ${last.day}',
      BeatKind.monthly => '${_months[start.month - 1]} ${start.year}',
      _ => '${start.year}',
    };
  }

  static String monthName(int m) => _months[m - 1];
}

/// Decides which calendar recap (if any) is due.
class RecapScheduler {
  RecapScheduler._();

  static const weeklyMinSessions = 3;
  static const monthlyMinSessions = 8;
  static const yearlyMinSessions = 10;

  /// Last completed Monday–Sunday week before [now].
  static Period lastWeek(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return Period(BeatKind.weekly, monday.subtract(const Duration(days: 7)), monday);
  }

  static Period lastMonth(DateTime now) {
    final first = DateTime(now.year, now.month, 1);
    final prev = DateTime(now.year, now.month - 1, 1);
    return Period(BeatKind.monthly, prev, first);
  }

  static Period year(int y) => Period(BeatKind.yearly, DateTime(y, 1, 1), DateTime(y + 1, 1, 1));

  /// The year a scheduled Wrapped would cover right now, if any: this year
  /// from Dec 15, or last year during January.
  static int? wrappedYear(DateTime now) {
    if (now.month == 12 && now.day >= 15) return now.year;
    if (now.month == 1) return now.year - 1;
    return null;
  }

  /// Highest-value recap that is due and not yet saved. Yearly beats
  /// monthly beats weekly.
  static Period? due({
    required DateTime now,
    required Iterable<DateTime> sessionStarts,
    required Set<String> savedKeys,
  }) {
    int count(Period p) => sessionStarts.where(p.contains).length;
    final wy = wrappedYear(now);
    if (wy != null) {
      final p = year(wy);
      if (!savedKeys.contains(p.key) && count(p) >= yearlyMinSessions) return p;
    }
    final m = lastMonth(now);
    if (!savedKeys.contains(m.key) && count(m) >= monthlyMinSessions) return m;
    final w = lastWeek(now);
    if (!savedKeys.contains(w.key) && count(w) >= weeklyMinSessions) return w;
    return null;
  }
}

/// Inputs for one period; the repo layer fills this.
class RecapInput {
  const RecapInput({
    required this.period,
    required this.states,
    required this.decisions,
    required this.sessions,
    required this.minutes,
    required this.streak,
    required this.ratingsAtStart,
    required this.settledAtStart,
    this.movers = const [],
    this.pairs = const [],
    required this.now,
  });

  final Period period;
  final List<PhotoState> states;
  final int decisions;
  final int sessions;
  final int minutes;
  final int streak;
  final Map<int, Rating> ratingsAtStart;
  final int settledAtStart;
  final List<MoverInfo> movers;
  final List<PairInfo> pairs;
  final DateTime now;

  List<PhotoState> get rated => states.where((s) => s.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu));
  List<PhotoState> get takenInPeriod => states.where((s) => s.takenAt != null && period.contains(s.takenAt!)).toList();
  List<PhotoState> get addedInPeriod => states.where((s) => s.addedAt != null && period.contains(s.addedAt!)).toList();
  int get settledNow => states.where((s) => s.rating.confidence >= 0.5).length;
}

/// Builds weekly / monthly / yearly recaps from period data.
class RecapEngine {
  RecapEngine._();

  static const minPages = 3;

  static Beat? build(RecapInput i) {
    final p = i.period;
    final pages = <BeatPage>[
      PeriodCoverPage(kind: p.kind, label: p.label, start: p.start, end: p.end),
      NumbersPage(decisions: i.decisions, sessions: i.sessions, minutes: i.minutes, streak: i.streak, newPhotos: i.addedInPeriod.length),
    ];
    final rated = i.rated;
    final takenRanked = i.takenInPeriod.where((s) => s.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu));

    if (p.kind != BeatKind.weekly && takenRanked.isNotEmpty) {
      pages.add(BestOfPeriodPage(photoId: takenRanked.first.id, label: p.kind == BeatKind.yearly ? '#1 of ${p.start.year}' : 'Best of ${p.label}'));
    }
    if (takenRanked.length >= 9) {
      pages.add(TopNinePage(ids: takenRanked.take(9).map((s) => s.id).toList(), title: p.kind == BeatKind.weekly ? 'This week\'s top 9' : 'Top 9 of ${p.label}'));
    } else if (rated.length >= 9) {
      pages.add(TopNinePage(ids: rated.take(9).map((s) => s.id).toList(), title: 'Your top 9'));
    }
    if (p.kind == BeatKind.yearly) {
      final byMonth = <int, PhotoState>{};
      for (final s in takenRanked) {
        byMonth.putIfAbsent(s.takenAt!.month, () => s);
      }
      if (byMonth.length >= 4) {
        final entries = byMonth.entries.map((e) => (e.key, e.value.id)).toList()..sort((a, b) => a.$1.compareTo(b.$1));
        pages.add(BestOfMonthsPage(entries: entries));
      }
    }
    final climb = i.movers.where((m) => m.delta >= BeatEngine.moverMinDelta).toList()..sort((a, b) => b.delta.compareTo(a.delta));
    if (climb.isNotEmpty) {
      final m = climb.first;
      pages.add(MoverPage(photoId: m.photoId, scoreBefore: m.before.score, scoreAfter: m.after.score));
    }
    if (p.kind != BeatKind.weekly && i.states.isNotEmpty && i.settledNow > i.settledAtStart) {
      pages.add(TrendPage(settledBefore: i.settledAtStart, settledAfter: i.settledNow, total: i.states.length));
    }
    if (p.kind != BeatKind.weekly && i.takenInPeriod.length >= 10) {
      pages.add(_taste(i));
    }
    final contested = i.pairs.where((x) => x.contested).toList()..sort((a, b) => b.duels.compareTo(a.duels));
    if (p.kind == BeatKind.weekly && contested.isNotEmpty) {
      final c = contested.first;
      pages.add(HeadToHeadPage(a: c.a, b: c.b, aWins: c.aWins, bWins: c.bWins));
    }
    if (rated.length >= 3) {
      pages.add(StandingsPage(top: rated.take(3).map((s) => s.id).toList(), settled: i.settledNow, total: i.states.length));
    }
    if (pages.length < minPages) return null;
    return Beat(kind: p.kind, tier: BeatTier.major, pages: pages, decisionCount: i.decisions, shareable: true);
  }

  static TastePage _taste(RecapInput i) {
    final taken = i.takenInPeriod;
    final portrait = taken.where((s) => !s.landscape).length;
    final byMonth = <int, int>{};
    final byHour = <int, int>{};
    for (final s in taken) {
      byMonth[s.takenAt!.month] = (byMonth[s.takenAt!.month] ?? 0) + 1;
      byHour[s.takenAt!.hour] = (byHour[s.takenAt!.hour] ?? 0) + 1;
    }
    int? argmax(Map<int, int> m) {
      if (m.isEmpty) return null;
      var best = m.keys.first;
      for (final e in m.entries) {
        if (e.value > m[best]!) best = e.key;
      }
      return best;
    }
    return TastePage(
      portraitPct: taken.isEmpty ? 0 : portrait * 100 ~/ taken.length,
      favoriteMonth: i.period.kind == BeatKind.yearly ? argmax(byMonth) : null,
      favoriteHour: argmax(byHour),
      photosTaken: taken.length,
      photosRanked: taken.where((s) => s.observations > 0).length,
    );
  }
}
