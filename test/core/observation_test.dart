import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/rating/engine.dart';
import 'package:photorank/core/rating/glicko.dart';
import 'package:photorank/core/rating/observation.dart';

void main() {
  final now = DateTime(2026, 8, 24);
  const engine = RatingEngine();
  Rating fresh(int _) => Rating.initial;

  group('Decompose', () {
    test('rate 4★ = win,win,win,draw,loss vs anchors', () {
      final obs = Decompose.rate(axisId: 1, cardId: 'c', photoId: 7, stars: 4, now: now);
      expect(obs.map((o) => o.outcome), [
        Outcome.win, Outcome.win, Outcome.win, Outcome.draw, Outcome.loss,
      ]);
      expect(obs.every((o) => o.isAnchor && o.subjectId == 7), isTrue);
    });

    test('sort of 3 yields 3 pairs, best first', () {
      final obs = Decompose.sort(axisId: 1, cardId: 'c', orderedIds: [3, 1, 2], now: now);
      expect(obs.length, 3);
      expect(obs.map((o) => (o.subjectId, o.opponentId)), [(3, 1), (3, 2), (1, 2)]);
      expect(obs.every((o) => o.outcome == Outcome.win), isTrue);
    });

    test('burst: winner beats each sibling, siblings untouched among themselves', () {
      final obs = Decompose.burst(
          axisId: 1, cardId: 'c', winnerId: 5, siblingIds: [5, 6, 7, 8], now: now);
      expect(obs.map((o) => o.opponentId), [6, 7, 8]);
      expect(obs.every((o) => o.subjectId == 5), isTrue);
    });

    test('heart is a light win', () {
      final obs = Decompose.heart(axisId: 1, cardId: 'c', photoId: 1, now: now).single;
      expect(obs.weight, lessThan(1));
      expect(obs.outcome, Outcome.win);
    });
  });

  group('RatingEngine', () {
    test('5★ ends above 1★', () {
      final five = engine
          .applyAll(Decompose.rate(axisId: 1, cardId: 'a', photoId: 1, stars: 5, now: now), fresh)
          .after[1]!;
      final one = engine
          .applyAll(Decompose.rate(axisId: 1, cardId: 'b', photoId: 2, stars: 1, now: now), fresh)
          .after[2]!;
      expect(five.mu, greaterThan(one.mu));
      expect(five.mu, greaterThan(Rating.initialMu));
      expect(one.mu, lessThan(Rating.initialMu));
    });

    test('sorted card ranks in given order and snapshots before-state', () {
      final delta = engine.applyAll(
          Decompose.sort(axisId: 1, cardId: 'c', orderedIds: [10, 20, 30], now: now), fresh);
      expect(delta.after[10]!.mu, greaterThan(delta.after[20]!.mu));
      expect(delta.after[20]!.mu, greaterThan(delta.after[30]!.mu));
      expect(delta.before.values.every((r) => r == Rating.initial), isTrue);
      expect(delta.before.keys, containsAll([10, 20, 30]));
    });

    test('duel moves both sides', () {
      final delta = engine.applyAll(
          Decompose.duel(axisId: 1, cardId: 'c', winnerId: 1, loserId: 2, now: now), fresh);
      expect(delta.after[1]!.mu, greaterThan(Rating.initialMu));
      expect(delta.after[2]!.mu, lessThan(Rating.initialMu));
    });
  });
}
