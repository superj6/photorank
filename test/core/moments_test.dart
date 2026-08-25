import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/dealer/photo_state.dart';
import 'package:photorank/core/rating/glicko.dart';
import 'package:photorank/core/sampler/moments.dart';

void main() {
  shadowTests();
  final t0 = DateTime(2026, 6, 1, 19, 0);
  PhotoState p(int id, {int minutes = 0, int seconds = 0, double mu = 1700, int? cluster}) =>
      PhotoState(id: id, rating: Rating(mu: mu, rd: 40), observations: 3, takenAt: t0.add(Duration(minutes: minutes, seconds: seconds)), clusterId: cluster);

  test('bursts, close-in-time look-alikes, and far photos group correctly', () {
    final states = [
      p(1, cluster: 7, mu: 1800), p(2, seconds: 3, cluster: 7, mu: 1790), // burst
      p(3, minutes: 10, mu: 1750), p(4, minutes: 11, mu: 1745), p(5, minutes: 13, mu: 1740), // sunset series
      p(6, minutes: 14, mu: 1400), // close in time but very different score -> its own
      p(7, minutes: 60, mu: 1760), // far away
    ];
    final keys = momentKeys(states);
    expect(keys[1], keys[2]);
    expect(keys[3], keys[4]);
    expect(keys[4], keys[5]);
    expect(keys[6], isNot(keys[5]));
    expect(keys[7], isNot(keys[5]));
    expect(keys[1], isNot(keys[3]));
  });

  test('collapse keeps best-first order and exposes similar members', () {
    final states = [
      p(1, cluster: 7, mu: 1800), p(2, seconds: 3, cluster: 7, mu: 1790),
      p(3, minutes: 10, mu: 1750), p(4, minutes: 11, mu: 1745),
      p(7, minutes: 60, mu: 1760),
    ]..sort((a, b) => b.mu.compareTo(a.mu));
    final moments = collapseMoments(states);
    expect(moments.map((m) => m.best.id), [1, 7, 3]);
    expect(moments.first.similar.map((s) => s.id), [2]);
    expect(moments.last.size, 2);
    expect(onePerMoment(states).map((s) => s.id), [1, 7, 3]);
  });

  test('photos without capture time stand alone', () {
    final states = [
      PhotoState(id: 1, rating: const Rating(mu: 1700, rd: 40), observations: 1),
      PhotoState(id: 2, rating: const Rating(mu: 1690, rd: 40), observations: 1),
    ];
    expect(collapseMoments(states).length, 2);
  });
}

void shadowTests() {
  test('a chosen burst keeper fronts its moment even if a sibling scores higher', () {
    final t0 = DateTime(2026, 6, 1, 19);
    final states = [
      PhotoState(id: 1, rating: const Rating(mu: 1790, rd: 40), observations: 3, takenAt: t0, clusterId: 7, shadowedBy: 2),
      PhotoState(id: 2, rating: const Rating(mu: 1760, rd: 40), observations: 3, takenAt: t0.add(const Duration(seconds: 3)), clusterId: 7),
    ];
    final m = collapseMoments(states).single;
    expect(m.best.id, 2);
    expect(m.similar.map((p) => p.id), [1]);
  });
}
