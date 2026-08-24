import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/dealer/burst_cluster.dart';
import 'package:photorank/core/dealer/dealer.dart';
import 'package:photorank/core/rating/glicko.dart';
import 'package:photorank/core/rating/observation.dart';

void main() {
  final now = DateTime(2026, 8, 24, 12);

  List<PhotoState> library(int n, {double rd = 350, int seed = 1}) {
    final rng = Random(seed);
    return [
      for (var i = 0; i < n; i++)
        PhotoState(
          id: i,
          rating: Rating(mu: 1500 + (rng.nextDouble() - 0.5) * 800, rd: rd),
          takenAt: now.subtract(Duration(minutes: i * 5)),
          addedAt: now.subtract(const Duration(days: 30)),
          lastShownAt: i.isEven ? now.subtract(Duration(days: i % 40)) : null,
        ),
    ];
  }

  Set<int> ids(List<Card> cards) => {for (final c in cards) ...c.photoIds};

  group('Dealer', () {
    test('deals a full hand with no repeated photo', () {
      final photos = library(300);
      final cards = Dealer(rng: Random(3)).dealHand(photos,
          config: const DealerConfig(), now: now);
      expect(cards.length, 20);
      final all = cards.expand((c) => c.photoIds).toList();
      expect(all.toSet().length, all.length);
    });

    test('every hand contains at least one top-tier photo', () {
      final photos = library(500, rd: 60);
      final top = ([...photos]..sort((a, b) => b.mu.compareTo(a.mu)))
          .take(50)
          .map((p) => p.id)
          .toSet();
      for (var seed = 0; seed < 20; seed++) {
        final cards = Dealer(rng: Random(seed)).dealHand(photos,
            config: const DealerConfig(), now: now);
        expect(ids(cards).intersection(top), isNotEmpty, reason: 'seed $seed');
      }
    });

    test('duel opponents are within the information window', () {
      final photos = library(400, rd: 50);
      final byId = {for (final p in photos) p.id: p};
      final cards = Dealer(rng: Random(9)).dealHand(photos,
          config: const DealerConfig(modeWeights: {GameMode.duel: 1}), now: now);
      expect(cards, isNotEmpty);
      for (final c in cards) {
        final a = byId[c.photoIds[0]]!, b = byId[c.photoIds[1]]!;
        expect((a.mu - b.mu).abs(), lessThanOrEqualTo(max(a.rd, 100.0)));
      }
    });

    test('challenger pairs a non-top photo with a top-50 photo', () {
      final photos = library(400, rd: 60);
      final top = ([...photos]..sort((a, b) => b.mu.compareTo(a.mu)))
          .take(50)
          .map((p) => p.id)
          .toSet();
      final cards = Dealer(rng: Random(5)).dealHand(photos,
          config: const DealerConfig(modeWeights: {GameMode.challenger: 1}), now: now);
      expect(cards, isNotEmpty);
      for (final c in cards) {
        expect(c.mode, GameMode.challenger);
        expect(top.contains(c.photoIds[0]), isFalse);
        expect(top.contains(c.photoIds[1]), isTrue);
      }
    });

    test('burst cards come only from eligible clusters', () {
      final photos = library(100);
      final bursts = [photos.sublist(0, 4), photos.sublist(10, 13)];
      final cards = Dealer(rng: Random(1)).dealHand(photos,
          config: const DealerConfig(modeWeights: {GameMode.bestOfBurst: 1}),
          bursts: bursts,
          now: now);
      expect(cards.length, 2);
      final allowed = bursts.expand((b) => b.map((p) => p.id)).toSet();
      for (final c in cards) {
        expect(c.photoIds.length, greaterThanOrEqualTo(3));
        expect(allowed.containsAll(c.photoIds), isTrue);
      }
    });

    test('disabled modes never appear; hand still fills from the rest', () {
      final photos = library(200);
      final cards = Dealer(rng: Random(2)).dealHand(photos,
          config: const DealerConfig(
              modeWeights: {GameMode.vibeCheck: 1, GameMode.rate: 1}),
          now: now);
      expect(cards.length, 20);
      expect(cards.every((c) => c.mode == GameMode.vibeCheck || c.mode == GameMode.rate),
          isTrue);
    });

    test('empty library deals nothing', () {
      expect(Dealer().dealHand([], config: const DealerConfig(), now: now), isEmpty);
    });
  });

  group('clusterBursts', () {
    test('groups shots within 10s and ignores pairs/singles', () {
      PhotoState at(int id, int seconds) => PhotoState(
          id: id, rating: Rating.initial, takenAt: now.add(Duration(seconds: seconds)));
      final photos = [
        at(1, 0), at(2, 3), at(3, 6), at(4, 9), // burst of 4
        at(5, 100), at(6, 105), // pair → ignored
        at(7, 300), // single
        at(8, 1000), at(9, 1005), at(10, 1012), // burst of 3
      ];
      final clusters = clusterBursts(photos);
      expect(clusters.map((c) => c.map((p) => p.id).toList()), [
        [1, 2, 3, 4],
        [8, 9, 10],
      ]);
    });

    test('splits oversized clusters to max 9', () {
      final photos = [
        for (var i = 0; i < 20; i++)
          PhotoState(id: i, rating: Rating.initial, takenAt: now.add(Duration(seconds: i))),
      ];
      final clusters = clusterBursts(photos);
      expect(clusters.every((c) => c.length <= 9 && c.length >= 3), isTrue);
      expect(clusters.expand((c) => c).length, 20);
    });
  });
}
