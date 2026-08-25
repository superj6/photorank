import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/beats/beat.dart';
import 'package:photorank/core/beats/beat_engine.dart';
import 'package:photorank/core/beats/beat_scheduler.dart';
import 'package:photorank/core/beats/late_game.dart';
import 'package:photorank/core/dealer/dealer.dart';
import 'package:photorank/core/rating/glicko.dart';
import 'package:photorank/core/rating/observation.dart';

void main() {
  final now = DateTime(2026, 8, 24, 12);

  List<PhotoState> rated(int n, {int unratedExtra = 0, DateTime? lastShown}) => [
        for (var i = 0; i < n; i++)
          PhotoState(
            id: i,
            rating: Rating(mu: 1900 - i * 10, rd: 40),
            observations: 5,
            takenAt: now.subtract(Duration(days: i)),
            lastShownAt: lastShown ?? now,
          ),
        for (var i = 0; i < unratedExtra; i++)
          PhotoState(id: n + i, rating: Rating.initial, takenAt: now),
      ];

  group('BeatScheduler', () {
    final s = BeatScheduler(rng: Random(1));

    test('nothing before decision 12, then a guaranteed first beat', () {
      final st = s.initial();
      expect(s.due(previous: 10, decisions: 11, state: st, changes: const StateChanges()), isNull);
      final d = s.due(previous: 11, decisions: 12, state: st, changes: const StateChanges());
      expect(d?.tier, BeatTier.minor);
    });

    test('minor cadence lands within 20–35 and respects the gap', () {
      for (var i = 0; i < 200; i++) {
        final n = s.nextMinorAfter(100);
        expect(n, inInclusiveRange(120, 135));
      }
      var st = s.fired(s.initial(), 12, BeatTier.minor);
      expect(st.everFired, isTrue);
      expect(st.nextMinorAt, inInclusiveRange(32, 47));
      expect(s.due(previous: 15, decisions: 16, state: st, changes: const StateChanges()), isNull);
      final d = s.due(previous: st.nextMinorAt - 1, decisions: st.nextMinorAt, state: st, changes: const StateChanges());
      expect(d?.tier, BeatTier.minor);
    });

    test('majors: unlock pre-empts everything; milestone waits for the gap', () {
      final st = s.fired(s.initial(), 45, BeatTier.minor);
      final unlock = s.due(previous: 49, decisions: 50, state: st, changes: const StateChanges(unlocked: [GameMode.rate]));
      expect(unlock?.kind, BeatKind.modeUnlocked);
      final blocked = s.due(previous: 49, decisions: 50, state: st, changes: const StateChanges());
      expect(blocked, isNull, reason: 'milestone 50 falls inside the 10-decision gap');
      final st2 = s.fired(s.initial(), 30, BeatTier.minor);
      final ms = s.due(previous: 49, decisions: 50, state: st2, changes: const StateChanges());
      expect(ms?.kind, BeatKind.milestone);
      final top = s.due(previous: 60, decisions: 61, state: st2, changes: const StateChanges(newTopId: 3));
      expect(top?.kind, BeatKind.newTop);
    });
  });

  group('BeatEngine', () {
    final e = BeatEngine(rng: Random(2));

    test('first minor beat is standings with the top 3', () {
      final b = e.build(const BeatDue.minor(), BeatInput(decisions: 12, states: rated(5), now: now));
      expect(b?.kind, BeatKind.standings);
      expect((b!.pages.single as StandingsPage).top, [0, 1, 2]);
    });

    test('the very first beat is standings even when a mover is available', () {
      final b = e.build(
        const BeatDue.minor(),
        BeatInput(
          decisions: 12,
          states: rated(5),
          now: now,
          firstBeat: true,
          moversThisHand: [MoverInfo(photoId: 3, before: Rating.initial, after: const Rating(mu: 1870, rd: 40))],
        ),
      );
      expect(b?.kind, BeatKind.standings);
    });

    test('standings needs three rated photos', () {
      expect(e.build(const BeatDue.minor(), BeatInput(decisions: 12, states: rated(2, unratedExtra: 5), now: now)), isNull);
    });

    test('mover beats standings when a photo climbed enough', () {
      final b = e.build(
        const BeatDue.minor(),
        BeatInput(
          decisions: 40,
          states: rated(20),
          now: now,
          moversThisHand: [
            MoverInfo(photoId: 3, before: const Rating(mu: 1500, rd: 300), after: const Rating(mu: 1870, rd: 40)),
            MoverInfo(photoId: 4, before: const Rating(mu: 1850, rd: 40), after: const Rating(mu: 1860, rd: 40)),
          ],
        ),
      );
      expect(b?.kind, BeatKind.mover);
      final p = b!.pages.single as MoverPage;
      expect(p.photoId, 3);
      expect(p.delta, greaterThanOrEqualTo(BeatEngine.moverMinDelta));
      expect(p.rankBefore, greaterThan(p.rankAfter!));
    });

    test('recently shown kinds are avoided when something else is available', () {
      final input = BeatInput(
        decisions: 60,
        states: rated(20),
        now: now,
        pairs: const [PairInfo(a: 1, b: 2, aWins: 2, bWins: 1)],
        recentKinds: const [BeatKind.headToHead],
      );
      expect(e.build(const BeatDue.minor(), input)?.kind, BeatKind.standings);
      final fresh = BeatInput(decisions: 60, states: rated(20), now: now, pairs: const [PairInfo(a: 1, b: 2, aWins: 2, bWins: 1)]);
      final b = e.build(const BeatDue.minor(), fresh);
      expect(b?.kind, BeatKind.headToHead);
      expect(b?.cta, isA<SettleDuelCta>());
    });

    test('deep cut needs a settled top photo unseen for 14 days', () {
      final states = rated(30, lastShown: now.subtract(const Duration(days: 20)));
      final b = e.build(const BeatDue.minor(), BeatInput(decisions: 80, states: states, now: now, recentKinds: const [BeatKind.standings]));
      expect(b?.kind, BeatKind.deepCut);
      expect((b!.pages.single as DeepCutPage).daysUnseen, 20);
      expect(b.cta, isA<VibeCheckCta>());
    });

    test('themed hand every fourth minor beat once allowed', () {
      final b = e.build(const BeatDue.minor(), BeatInput(decisions: 120, states: rated(20), now: now, themedAllowed: true, minorBeatsSoFar: 3));
      expect(b?.kind, BeatKind.themedHand);
      expect(b?.cta, isA<ThemedDeckCta>());
      final not = e.build(const BeatDue.minor(), BeatInput(decisions: 120, states: rated(20), now: now, themedAllowed: true, minorBeatsSoFar: 2));
      expect(not?.kind, isNot(BeatKind.themedHand));
    });

    test('majors produce their pages and shareability', () {
      final unlock = e.build(const BeatDue.major(BeatKind.modeUnlocked),
          BeatInput(decisions: 30, states: rated(5), now: now, changes: const StateChanges(unlocked: [GameMode.rate])));
      expect(unlock?.cta, isA<TryModeCta>());
      final ms = e.build(const BeatDue.major(BeatKind.milestone), BeatInput(decisions: 101, states: rated(5), now: now, minutesPlayed: 9, streak: 2));
      expect(ms?.shareable, isTrue);
      expect((ms!.pages.first as MilestonePage).decisions, 100);
      expect(ms.pages.length, 2);
      final top = e.build(const BeatDue.major(BeatKind.topTenOfficial), BeatInput(decisions: 200, states: rated(12), now: now));
      expect((top!.pages.single as TopTenPage).ids.length, 10);
      expect(e.build(const BeatDue.major(BeatKind.topTenOfficial), BeatInput(decisions: 200, states: rated(6), now: now)), isNull);
    });
  });

  test('Beat JSON round-trips every page type and CTA', () {
    final pages = <BeatPage>[
      const StandingsPage(top: [1, 2, 3], settled: 4, total: 9),
      const MoverPage(photoId: 1, scoreBefore: 40, scoreAfter: 61.5, rankBefore: 9, rankAfter: 2),
      const ThenVsNowPage(photoId: 2, scoreThen: 50, scoreNow: 70, decisionsBetween: 120, daysBetween: 9),
      const HeadToHeadPage(a: 1, b: 2, aWins: 2, bWins: 1),
      const DeepCutPage(photoId: 5, rank: 3, daysUnseen: 21),
      const BurstClearedPage(winnerId: 7, siblingIds: [8, 9]),
      const SettledPage(settled: 50, total: 100, crossed: 50),
      const NewTopPage(photoId: 1, previousId: 2),
      const TopTenPage(ids: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
      const MilestonePage(decisions: 250, minutes: 31, streak: 4),
      const ModeUnlockedPage(GameMode.sort3),
      const ThemedHandPage(DeckTheme.oneTrip, count: 10),
      const WelcomeBackPage(daysAway: 9, newPhotos: 12, topHeld: true, topId: 1),
    ];
    for (final cta in [const SettleDuelCta(1, 2), const VibeCheckCta(3), const TryModeCta(GameMode.rate), const ThemedDeckCta(DeckTheme.landscapes), null]) {
      final beat = Beat(kind: BeatKind.milestone, tier: BeatTier.major, pages: pages, decisionCount: 42, cta: cta, shareable: true);
      final back = Beat.fromJson(beat.toJson(), decisionCount: 42);
      expect(back.pages.map((p) => p.toJson()), pages.map((p) => p.toJson()));
      expect(back.cta?.toJson(), cta?.toJson());
      expect(back.shareable, isTrue);
    }
  });

  test('late-game policy shortens hands and leans toward the top and new arrivals', () {
    const early = LibraryStats(settledFraction: 0.3, observations: 800);
    const late = LibraryStats(settledFraction: 0.9, observations: 800);
    const cfg = DealerConfig();
    expect(LateGamePolicy.adjust(cfg, early), same(cfg));
    final adj = LateGamePolicy.adjust(cfg, late);
    expect(adj.handSize, 10);
    expect(adj.modeWeights[GameMode.challenger], greaterThan(cfg.modeWeights[GameMode.challenger]!));
    expect(adj.weights.recency, greaterThan(cfg.weights.recency));
  });
}
