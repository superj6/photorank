import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/dealer/dealer.dart';
import 'package:photorank/core/rating/glicko.dart';
import 'package:photorank/core/rating/observation.dart';

void main() {
  final now = DateTime(2026, 8, 24, 12);
  final photos = [
    // day A: 8 photos, day B: 3 photos, mixed orientation, some rated
    for (var i = 0; i < 8; i++)
      PhotoState(id: i, rating: Rating(mu: 1800 - i * 20, rd: 50), observations: 3, takenAt: DateTime(2026, 5, 3, 9 + i), landscape: i.isEven),
    for (var i = 8; i < 11; i++)
      PhotoState(id: i, rating: Rating.initial, takenAt: DateTime(2026, 6, 9, 10 + i), landscape: true),
    for (var i = 11; i < 20; i++)
      PhotoState(id: i, rating: Rating(mu: 1600.0 - i, rd: 60), observations: 2, takenAt: DateTime(2026, 7, 1 + i, 8), landscape: false),
  ];
  final dealer = Dealer(rng: Random(3));

  Set<int> ids(List<Card> cards) => {for (final c in cards) ...c.photoIds};

  test('oneTrip deals only from one day with enough photos, no repeats', () {
    final deck = dealer.dealDeck(photos, theme: DeckTheme.oneTrip, now: now);
    expect(deck, isNotEmpty);
    final all = deck.expand((c) => c.photoIds).toList();
    expect(all.toSet().length, all.length);
    expect(ids(deck).every((id) => id < 8), isTrue, reason: 'day A is the only day with ≥6 photos');
    expect(deck.every((c) => c.mode == GameMode.duel || c.mode == GameMode.vibeCheck), isTrue);
  });

  test('landscapes deck only contains landscape photos', () {
    final deck = dealer.dealDeck(photos, theme: DeckTheme.landscapes, now: now);
    expect(deck, isNotEmpty);
    final landscape = photos.where((p) => p.landscape).map((p) => p.id).toSet();
    expect(landscape.containsAll(ids(deck)), isTrue);
  });

  test('rerankTop deck sorts trios of the top 10 then duels them', () {
    final deck = dealer.dealDeck(photos, theme: DeckTheme.rerankTop, now: now);
    final top10 = (photos.where((p) => p.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu))).take(10).map((p) => p.id).toSet();
    expect(deck.length, lessThanOrEqualTo(10));
    expect(top10.containsAll(ids(deck)), isTrue);
    expect(deck.where((c) => c.mode == GameMode.rerankTop).length, 3);
    expect(deck.any((c) => c.mode == GameMode.duel), isTrue);
  });

  test('too little material yields an empty deck', () {
    final few = photos.take(3).toList();
    expect(dealer.dealDeck(few, theme: DeckTheme.sameMonth, now: now), isEmpty);
  });
}
