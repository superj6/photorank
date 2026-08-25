import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/dealer/photo_state.dart';
import 'package:photorank/core/guest/guest.dart';
import 'package:photorank/core/rating/glicko.dart';

void main() {
  final states = [
    for (var i = 0; i < 30; i++)
      PhotoState(id: i, rating: Rating(mu: 1100 + i * 30, rd: 60), observations: 3),
  ];

  test('builds duels with a clear owner pick and vibe checks on clear photos', () {
    final cards = GuestGame.build(states, rng: Random(1));
    expect(cards.length, 10);
    final duels = cards.where((c) => c.kind == GuestCardKind.duel).toList();
    final vibes = cards.where((c) => c.kind == GuestCardKind.vibe).toList();
    expect(duels.length, 7);
    expect(vibes.length, 3);
    final byId = {for (final s in states) s.id: s};
    for (final d in duels) {
      final hi = byId[d.a]!.mu > byId[d.b]!.mu ? d.a : d.b;
      expect(d.ownerPick, hi);
      expect((byId[d.a]!.mu - byId[d.b]!.mu).abs(), greaterThanOrEqualTo(GuestGame.minDuelGap));
    }
    for (final v in vibes) {
      expect(v.ownerFeelsIt, byId[v.a]!.rating.score >= GuestGame.feelingThreshold);
    }
    final all = cards.expand((c) => [c.a, if (c.b != null) c.b!]).toList();
    expect(all.toSet().length, all.length);
  });

  test('scoring and verdicts', () {
    final cards = GuestGame.build(states, rng: Random(2));
    final answers = [
      for (final c in cards)
        c.kind == GuestCardKind.duel ? GuestGame.scoreDuel(c, c.ownerPick!) : GuestGame.scoreVibe(c, !c.ownerFeelsIt!),
    ];
    final r = GuestResult(name: 'Sam', mode: GuestMode.taste, answers: answers);
    expect(r.agreed, 7);
    expect(r.pct, 70);
    expect(r.disagreements.length, 3);
    expect(GuestGame.verdict(r), 'Mostly aligned.');
    expect(GuestGame.build(states.take(3).toList()), isEmpty);
  });
}
