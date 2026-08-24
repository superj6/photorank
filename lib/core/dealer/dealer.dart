import 'dart:math';

import '../rating/observation.dart';
import 'photo_state.dart';
import 'priority.dart';

export 'photo_state.dart';
export 'priority.dart';

/// One thing to put in front of the user.
class Card {
  const Card({required this.mode, required this.photoIds, this.clusterId});

  final GameMode mode;

  /// duel/challenger: [a, b]; vibeCheck/rate: [a]; sort3: 3 ids;
  /// bestOfBurst: 3–9 ids.
  final List<int> photoIds;
  final int? clusterId;

  @override
  String toString() => 'Card(${mode.name}, $photoIds)';
}

class DealerConfig {
  const DealerConfig({
    this.modeWeights = const {
      GameMode.duel: 3,
      GameMode.vibeCheck: 3,
      GameMode.rate: 2,
      GameMode.bestOfBurst: 2,
      GameMode.sort3: 1,
      GameMode.challenger: 1,
    },
    this.handSize = 20,
    this.topTierSize = 50,
    this.weights = const PriorityWeights(),
  });

  /// Relative frequency per mode; a mode with weight 0 (or absent) is off.
  final Map<GameMode, double> modeWeights;
  final int handSize;
  final int topTierSize;
  final PriorityWeights weights;

  DealerConfig copyWith({Map<GameMode, double>? modeWeights, int? handSize}) =>
      DealerConfig(
        modeWeights: modeWeights ?? this.modeWeights,
        handSize: handSize ?? this.handSize,
        topTierSize: topTierSize,
        weights: weights,
      );
}

/// Chooses which photos, in which mode, for a hand of cards.
class Dealer {
  Dealer({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  /// [bursts] are clusters still eligible for Best-of-Burst (no member has
  /// beaten its siblings yet). Each cluster's photos must also be in [photos].
  List<Card> dealHand(
    List<PhotoState> photos, {
    required DealerConfig config,
    List<List<PhotoState>> bursts = const [],
    required DateTime now,
  }) {
    if (photos.isEmpty) return const [];
    final used = <int>{};
    final byId = {for (final p in photos) p.id: p};

    // Priority-sorted pool; recomputed lazily via `used` filtering.
    final ranked = [...photos]
      ..sort((a, b) => priorityOf(b, now, _rng, w: config.weights)
          .compareTo(priorityOf(a, now, _rng, w: config.weights)));
    final byMu = [...photos]..sort((a, b) => b.mu.compareTo(a.mu));
    final topTier = byMu.take(config.topTierSize).map((p) => p.id).toSet();

    final cards = <Card>[];
    final modes = _enabledModes(config);
    var burstQueue = bursts.where((c) => c.length >= 3).toList()..shuffle(_rng);

    PhotoState? next({bool Function(PhotoState)? where}) {
      for (final p in ranked) {
        if (used.contains(p.id)) continue;
        if (where != null && !where(p)) continue;
        return p;
      }
      return null;
    }

    PhotoState? opponentFor(PhotoState a, {bool Function(PhotoState)? where}) {
      final window = max(a.rd, 100.0);
      PhotoState? best;
      var bestDist = double.infinity;
      for (final p in ranked) {
        if (p.id == a.id || used.contains(p.id)) continue;
        if (where != null && !where(p)) continue;
        final dist = (p.mu - a.mu).abs();
        if (dist <= window) return p; // ranked is priority-ordered
        if (dist < bestDist) {
          best = p;
          bestDist = dist;
        }
      }
      return best;
    }

    Card? build(GameMode mode) {
      switch (mode) {
        case GameMode.vibeCheck:
        case GameMode.rate:
          final a = next();
          if (a == null) return null;
          used.add(a.id);
          return Card(mode: mode, photoIds: [a.id]);
        case GameMode.duel:
          final a = next();
          if (a == null) return null;
          final b = opponentFor(a);
          if (b == null) return null;
          used.addAll([a.id, b.id]);
          return Card(mode: mode, photoIds: [a.id, b.id]);
        case GameMode.challenger:
          if (topTier.length < 10) return null;
          final a = next(where: (p) => !topTier.contains(p.id));
          if (a == null) return null;
          final b = opponentFor(a, where: (p) => topTier.contains(p.id));
          if (b == null) return null;
          used.addAll([a.id, b.id]);
          return Card(mode: mode, photoIds: [a.id, b.id]);
        case GameMode.sort3:
          final a = next();
          if (a == null) return null;
          used.add(a.id);
          final b = opponentFor(a);
          if (b == null) return null;
          used.add(b.id);
          final c = opponentFor(a);
          if (c == null) return null;
          used.add(c.id);
          final ids = [a.id, b.id, c.id]..shuffle(_rng);
          return Card(mode: mode, photoIds: ids);
        case GameMode.bestOfBurst:
          while (burstQueue.isNotEmpty) {
            final cluster = burstQueue.removeLast();
            final ids = cluster
                .map((p) => p.id)
                .where((id) => byId.containsKey(id) && !used.contains(id))
                .toList();
            if (ids.length < 3) continue;
            used.addAll(ids);
            return Card(
                mode: mode, photoIds: ids, clusterId: cluster.first.clusterId);
          }
          return null;
        case GameMode.browseHeart:
          return null;
      }
    }

    var attempts = 0;
    while (cards.length < config.handSize && attempts < config.handSize * 4) {
      attempts++;
      final mode = _pickMode(modes);
      if (mode == null) break;
      final card = build(mode);
      if (card == null) {
        modes.remove(mode);
        if (modes.isEmpty) break;
        continue;
      }
      cards.add(card);
    }

    // Delight rule: at least one current top-tier photo per hand.
    final hasTop = cards.any((c) => c.photoIds.any(topTier.contains));
    if (!hasTop && topTier.isNotEmpty && cards.isNotEmpty) {
      final top = next(where: (p) => topTier.contains(p.id));
      if (top != null) {
        final b = opponentFor(top);
        final replacement = b == null
            ? Card(mode: GameMode.vibeCheck, photoIds: [top.id])
            : Card(mode: GameMode.duel, photoIds: [top.id, b.id]);
        cards[cards.length - 1] = replacement;
      }
    }
    return cards;
  }

  Map<GameMode, double> _enabledModes(DealerConfig c) => {
        for (final e in c.modeWeights.entries)
          if (e.value > 0 && e.key != GameMode.browseHeart) e.key: e.value,
      };

  GameMode? _pickMode(Map<GameMode, double> modes) {
    if (modes.isEmpty) return null;
    final total = modes.values.fold(0.0, (a, b) => a + b);
    var r = _rng.nextDouble() * total;
    for (final e in modes.entries) {
      r -= e.value;
      if (r <= 0) return e.key;
    }
    return modes.keys.last;
  }
}
