import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/beats/beat.dart';
import 'package:photorank/core/beats/beat_engine.dart';
import 'package:photorank/core/beats/recap.dart';
import 'package:photorank/core/dealer/photo_state.dart';
import 'package:photorank/core/rating/glicko.dart';

void main() {
  group('RecapScheduler', () {
    test('lastWeek is the completed Monday–Sunday before now', () {
      final p = RecapScheduler.lastWeek(DateTime(2026, 8, 26, 10)); // Wednesday
      expect(p.start, DateTime(2026, 8, 17));
      expect(p.end, DateTime(2026, 8, 24));
      expect(p.label, 'Aug 17 – Aug 23');
      final monday = RecapScheduler.lastWeek(DateTime(2026, 8, 24, 0, 5));
      expect(monday.start, DateTime(2026, 8, 17));
    });

    test('monthly and wrapped windows', () {
      expect(RecapScheduler.lastMonth(DateTime(2026, 8, 3)).label, 'Jul 2026');
      expect(RecapScheduler.lastMonth(DateTime(2026, 1, 3)).start, DateTime(2025, 12, 1));
      expect(RecapScheduler.wrappedYear(DateTime(2026, 12, 20)), 2026);
      expect(RecapScheduler.wrappedYear(DateTime(2027, 1, 5)), 2026);
      expect(RecapScheduler.wrappedYear(DateTime(2026, 6, 5)), isNull);
    });

    test('due requires enough sessions and skips saved periods; yearly wins', () {
      final now = DateTime(2026, 12, 20, 9);
      final sessions = [for (var d = 1; d <= 40; d++) DateTime(2026, 11, 1).add(Duration(days: d))];
      final due = RecapScheduler.due(now: now, sessionStarts: sessions, savedKeys: {});
      expect(due?.kind, BeatKind.yearly);
      final due2 = RecapScheduler.due(now: now, sessionStarts: sessions, savedKeys: {RecapScheduler.year(2026).key});
      expect(due2?.kind, BeatKind.monthly);
      final due3 = RecapScheduler.due(
          now: now, sessionStarts: sessions, savedKeys: {RecapScheduler.year(2026).key, RecapScheduler.lastMonth(now).key});
      expect(due3?.kind, BeatKind.weekly);
      expect(RecapScheduler.due(now: now, sessionStarts: sessions.take(2), savedKeys: {}), isNull);
    });
  });

  group('RecapEngine', () {
    final now = DateTime(2026, 8, 26);
    final period = RecapScheduler.lastWeek(now);
    List<PhotoState> lib(int n, {int inPeriod = 12}) => [
          for (var i = 0; i < n; i++)
            PhotoState(
              id: i,
              rating: Rating(mu: 1900 - i * 15, rd: 45),
              observations: 4,
              takenAt: i < inPeriod ? period.start.add(Duration(hours: i * 10)) : DateTime(2026, 3, 1 + i % 20, 14),
              addedAt: i < inPeriod ? period.start.add(Duration(hours: i * 10)) : DateTime(2026, 3, 1),
              landscape: i.isEven,
            ),
        ];

    test('weekly recap: cover, numbers, top 9 of the week, standings', () {
      final beat = RecapEngine.build(RecapInput(
        period: period,
        states: lib(40),
        decisions: 120,
        sessions: 5,
        minutes: 14,
        streak: 3,
        ratingsAtStart: const {},
        settledAtStart: 10,
        now: now,
      ));
      expect(beat, isNotNull);
      expect(beat!.kind, BeatKind.weekly);
      expect(beat.shareable, isTrue);
      expect(beat.pages.first, isA<PeriodCoverPage>());
      expect(beat.pages.whereType<TopNinePage>().single.title, contains('week'));
      expect(beat.pages.whereType<TopNinePage>().single.ids.every((id) => id < 12), isTrue);
      expect(beat.pages.last, isA<StandingsPage>());
      expect(beat.pages.whereType<BestOfPeriodPage>(), isEmpty);
    });

    test('yearly recap adds best-of, months strip, taste and trend', () {
      final year = RecapScheduler.year(2026);
      final states = [
        for (var i = 0; i < 60; i++)
          PhotoState(
            id: i,
            rating: Rating(mu: 1900 - i * 10, rd: 45),
            observations: 3,
            takenAt: DateTime(2026, 1 + i % 8, 2 + i % 20, 8 + i % 12),
            addedAt: DateTime(2026, 1 + i % 8, 2),
            landscape: i % 3 == 0,
          ),
      ];
      final beat = RecapEngine.build(RecapInput(
        period: year,
        states: states,
        decisions: 900,
        sessions: 80,
        minutes: 120,
        streak: 5,
        ratingsAtStart: const {},
        settledAtStart: 5,
        movers: [MoverInfo(photoId: 7, before: const Rating(mu: 1500, rd: 300), after: const Rating(mu: 1830, rd: 45))],
        now: DateTime(2026, 12, 20),
      ));
      expect(beat, isNotNull);
      final types = beat!.pages.map((p) => p.runtimeType).toList();
      expect(types, containsAll([PeriodCoverPage, NumbersPage, BestOfPeriodPage, TopNinePage, BestOfMonthsPage, MoverPage, TrendPage, TastePage, StandingsPage]));
      final months = beat.pages.whereType<BestOfMonthsPage>().single.entries;
      expect(months.map((e) => e.$1), [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(beat.pages.whereType<TastePage>().single.favoriteMonth, isNotNull);
      expect(beat.pages.whereType<BestOfPeriodPage>().single.label, '#1 of 2026');
    });

    test('too little material yields no recap', () {
      expect(
        RecapEngine.build(RecapInput(
          period: period,
          states: const [],
          decisions: 3,
          sessions: 3,
          minutes: 2,
          streak: 1,
          ratingsAtStart: const {},
          settledAtStart: 0,
          now: now,
        )),
        isNull,
      );
    });

    test('calendar pages round-trip through JSON', () {
      final pages = <BeatPage>[
        PeriodCoverPage(kind: BeatKind.weekly, label: 'Aug 17 – Aug 23', start: DateTime(2026, 8, 17), end: DateTime(2026, 8, 24)),
        const NumbersPage(decisions: 1, sessions: 2, minutes: 3, streak: 4, newPhotos: 5),
        const TopNinePage(ids: [1, 2, 3, 4, 5, 6, 7, 8, 9], title: 't'),
        const BestOfPeriodPage(photoId: 3, label: 'b'),
        const BestOfMonthsPage(entries: [(1, 4), (3, 9)]),
        const TastePage(portraitPct: 70, favoriteMonth: 7, favoriteHour: 18, photosTaken: 40, photosRanked: 30),
        const TrendPage(settledBefore: 3, settledAfter: 9, total: 20),
      ];
      final beat = Beat(kind: BeatKind.yearly, tier: BeatTier.major, pages: pages, decisionCount: 1);
      final back = Beat.fromJson(beat.toJson(), decisionCount: 1);
      expect(back.pages.map((p) => p.toJson()), pages.map((p) => p.toJson()));
    });
  });
}
