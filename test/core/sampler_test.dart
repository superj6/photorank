import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/dealer/photo_state.dart';
import 'package:photorank/core/rating/glicko.dart';
import 'package:photorank/core/sampler/rank_sampler.dart';

void main() {
  final now = DateTime(2026, 8, 24);
  final pool = [
    for (var i = 0; i < 200; i++)
      PhotoState(
        id: i,
        rating: Rating(mu: 1000 + i * 5, rd: 40), // id 199 is best
        takenAt: now.subtract(Duration(days: i % 7, hours: i)),
        views: i % 3,
      ),
  ];

  group('RankSampler', () {
    test('no duplicates within a draw and honours exclude', () {
      final s = RankSampler(rng: Random(1));
      final out = s.sample(pool, count: 9, exclude: {199, 198});
      expect(out.length, 9);
      expect(out.map((p) => p.id).toSet().length, 9);
      expect(out.any((p) => p.id == 199 || p.id == 198), isFalse);
    });

    test('rank weighting is monotonic: better photos are drawn more often', () {
      final s = RankSampler(rng: Random(7));
      final counts = <int, int>{};
      for (var i = 0; i < 2000; i++) {
        for (final p in s.sample(pool, count: 1)) {
          counts[p.id] = (counts[p.id] ?? 0) + 1;
        }
      }
      expect(counts[199] ?? 0, greaterThan(counts[100] ?? 0));
      expect(counts[100] ?? 0, greaterThan(counts[0] ?? 0));
    });

    test('top shelf never yields below the cutoff', () {
      final s = RankSampler(rng: Random(3));
      final out = s.topShelf(pool, count: 20, fraction: 0.05, minCount: 20);
      expect(out.length, 20);
      expect(out.every((p) => p.id >= 180), isTrue);
    });

    test('time machine returns a single day sorted best-first', () {
      final s = RankSampler(rng: Random(5));
      final out = s.timeMachine(pool);
      expect(out, isNotEmpty);
      final days = out.map((p) => DateTime(p.takenAt!.year, p.takenAt!.month, p.takenAt!.day)).toSet();
      expect(days.length, 1);
      for (var i = 1; i < out.length; i++) {
        expect(out[i - 1].mu, greaterThanOrEqualTo(out[i].mu));
      }
    });

    test('deep cuts prefers rarely viewed photos', () {
      final s = RankSampler(rng: Random(11));
      final out = s.deepCuts(pool, count: 10);
      expect(out, isNotEmpty);
      expect(out.every((p) => p.views == 0), isTrue);
    });
  });
}
