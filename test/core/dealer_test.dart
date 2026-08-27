import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/dealer/burst_cluster.dart';
import 'package:photorank/core/dealer/dealer.dart';
import 'package:photorank/core/rating/glicko.dart';
import 'package:photorank/core/rating/observation.dart';

void main() {
  momentDealerTests();
  newPhotoShareTests();
  final now = DateTime(2026, 8, 24, 12);

  List<PhotoState> library(int n, {double rd = 350, int seed = 1, bool rated = true}) {
    final rng = Random(seed);
    return [
      for (var i = 0; i < n; i++)
        PhotoState(
          id: i,
          rating: Rating(mu: 1500 + (rng.nextDouble() - 0.5) * 800, rd: rd),
          takenAt: now.subtract(Duration(minutes: i * 5)),
          addedAt: now.subtract(const Duration(days: 30)),
          lastShownAt: i.isEven ? now.subtract(Duration(days: i % 40)) : null,
          observations: rated ? 1 : 0,
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

    test('unrated library never deals Challenger and needs no top tier', () {
      final photos = library(200, rated: false);
      final cards = Dealer(rng: Random(4)).dealHand(photos,
          config: const DealerConfig(), now: now);
      expect(cards.length, 20);
      expect(cards.any((c) => c.mode == GameMode.challenger), isFalse);
    });

    test('a one-card hand keeps the requested mode (CTA cards)', () {
      final photos = library(300, rd: 60);
      for (final mode in [GameMode.rate, GameMode.vibeCheck, GameMode.sort3]) {
        final cards = Dealer(rng: Random(8)).dealHand(photos,
            config: DealerConfig(modeWeights: {mode: 1}, handSize: 1), now: now);
        expect(cards.single.mode, mode);
      }
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

void momentDealerTests() {
  final now = DateTime(2026, 8, 24, 12);
  test('dealer never duels burst siblings, deals one per burst, benches shadowed losers', () {
    final photos = [
      for (var i = 0; i < 60; i++)
        PhotoState(
          id: i,
          rating: Rating(mu: 1500 + (i % 7) * 20, rd: 60),
          observations: 1,
          takenAt: now.subtract(Duration(hours: i)),
          clusterId: i < 12 ? i ~/ 4 : null, // three bursts of four
          shadowedBy: i == 1 || i == 2 ? 0 : null, // burst 0 decided, 0 won
        ),
    ];
    for (var seed = 0; seed < 10; seed++) {
      final cards = Dealer(rng: Random(seed)).dealHand(photos,
          config: const DealerConfig(modeWeights: {GameMode.duel: 2, GameMode.vibeCheck: 1, GameMode.sort3: 1}), now: now);
      final byId = {for (final p in photos) p.id: p};
      final seenClusters = <int>{};
      for (final c in cards) {
        final clusters = c.photoIds.map((id) => byId[id]!.clusterId).whereType<int>().toList();
        expect(clusters.toSet().length, clusters.length, reason: 'no two members of one burst in a card');
        for (final cl in clusters) {
          expect(seenClusters.add(cl), isTrue, reason: 'one member per burst per hand');
        }
        expect(c.photoIds.any((id) => byId[id]!.shadowedBy != null), isFalse, reason: 'shadowed losers sit out');
      }
    }
  });
}

void newPhotoShareTests() {
  final now = DateTime(2026, 8, 27, 12);

  List<PhotoState> mixed({required int rated, required int unrated}) => [
        for (var i = 0; i < rated; i++)
          PhotoState(
            id: i,
            rating: Rating(mu: 1400 + (i % 9) * 40, rd: 70),
            observations: 4,
            takenAt: now.subtract(Duration(days: 200 + i)),
            addedAt: now.subtract(const Duration(days: 300)),
            lastShownAt: now.subtract(Duration(days: i % 20)),
          ),
        for (var i = 0; i < unrated; i++)
          PhotoState(
            id: 100000 + i,
            rating: Rating.initial,
            takenAt: now.subtract(Duration(days: 200 + i)),
            // Freshly indexed, like a folder just added.
            addedAt: now,
          ),
      ];

  test('a big unrated library does not take over the hand', () {
    // The shape of the real library: ~10k unrated, ~1.2k rated.
    final photos = mixed(rated: 1200, unrated: 10000);
    for (var seed = 0; seed < 6; seed++) {
      final cards = Dealer(rng: Random(seed)).dealHand(photos, config: const DealerConfig(), now: now);
      final byId = {for (final p in photos) p.id: p};
      final newCards = cards.where((c) => c.photoIds.any((id) => byId[id]!.observations == 0)).length;
      expect(cards.length, 20);
      expect(newCards, lessThanOrEqualTo(5), reason: 'default share is 25% of 20 cards (seed $seed)');
      expect(newCards, greaterThan(0), reason: 'new photos still get in (seed $seed)');
    }
  });

  test('the share is configurable', () {
    final photos = mixed(rated: 1200, unrated: 10000);
    int newCardsFor(double share) {
      final cards = Dealer(rng: Random(3)).dealHand(photos,
          config: DealerConfig(newPhotoShare: share), now: now);
      final byId = {for (final p in photos) p.id: p};
      return cards.where((c) => c.photoIds.any((id) => byId[id]!.observations == 0)).length;
    }

    expect(newCardsFor(0.0), 0, reason: 'never introduce new photos');
    expect(newCardsFor(0.1), lessThanOrEqualTo(2));
    expect(newCardsFor(0.5), greaterThan(newCardsFor(0.1)));
  });

  test('a library with nothing rated yet still deals a full hand', () {
    final photos = mixed(rated: 0, unrated: 300);
    final cards = Dealer(rng: Random(1)).dealHand(photos, config: const DealerConfig(), now: now);
    expect(cards.length, 20, reason: 'the cap yields when there is nothing else to deal');
  });

  test('recency follows when a photo was taken, not when it was indexed', () {
    final justImportedOldPhoto = PhotoState(
      id: 1,
      rating: Rating.initial,
      takenAt: now.subtract(const Duration(days: 900)),
      addedAt: now,
    );
    final photoTakenToday = PhotoState(
      id: 2,
      rating: Rating.initial,
      takenAt: now.subtract(const Duration(hours: 2)),
      addedAt: now,
    );
    final rng = Random(0);
    const w = PriorityWeights(noise: 0);
    expect(priorityOf(photoTakenToday, now, rng, w: w),
        greaterThan(priorityOf(justImportedOldPhoto, now, rng, w: w)),
        reason: 'a photo shot today outranks a decade-old one imported today');
  });
}
