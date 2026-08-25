import 'dart:math';

import '../rating/observation.dart';
import 'deck_theme.dart';
import 'photo_state.dart';
import 'priority.dart';

export 'deck_theme.dart';
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
      GameMode.rerankTop: 0.5,
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

    // Priority-sorted pool (priorities fixed once per hand so the sort is
    // consistent despite the noise term); `used` filters as cards are built.
    final priority = {
      for (final p in photos) p.id: priorityOf(p, now, _rng, w: config.weights),
    };
    final ranked = [...photos]..sort((a, b) => priority[b.id]!.compareTo(priority[a.id]!));
    // Top tier = best *rated* photos; an unrated library has no top yet.
    final byMu = photos.where((p) => p.observations > 0).toList()
      ..sort((a, b) => b.mu.compareTo(a.mu));
    final topTier = byMu.take(config.topTierSize).map((p) => p.id).toSet();

    final cards = <Card>[];
    final modes = _enabledModes(config);
    var burstQueue = bursts.where((c) => c.length >= 3).toList()..shuffle(_rng);
    // One member per moment per hand; shadowed burst losers sit out (their
    // winner represents the moment) unless nothing else is left.
    final usedClusters = <int>{};
    bool blocked(PhotoState p) =>
        (p.clusterId != null && usedClusters.contains(p.clusterId)) || p.shadowedBy != null;
    void take(PhotoState p) {
      used.add(p.id);
      if (p.clusterId != null) usedClusters.add(p.clusterId!);
    }

    PhotoState? next({bool Function(PhotoState)? where}) {
      for (final pass in [true, false]) {
        for (final p in ranked) {
          if (used.contains(p.id)) continue;
          if (pass && blocked(p)) continue;
          if (where != null && !where(p)) continue;
          return p;
        }
      }
      return null;
    }

    PhotoState? opponentFor(PhotoState a, {bool Function(PhotoState)? where}) {
      final window = max(a.rd, 100.0);
      PhotoState? best;
      var bestDist = double.infinity;
      for (final p in ranked) {
        if (p.id == a.id || used.contains(p.id)) continue;
        if (a.clusterId != null && p.clusterId == a.clusterId) continue; // never duel your own burst
        if (blocked(p)) continue;
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
          take(a);
          return Card(mode: mode, photoIds: [a.id]);
        case GameMode.duel:
          final a = next();
          if (a == null) return null;
          final b = opponentFor(a);
          if (b == null) return null;
          take(a);
          take(b);
          return Card(mode: mode, photoIds: [a.id, b.id]);
        case GameMode.challenger:
          if (topTier.length < 10) return null;
          final a = next(where: (p) => !topTier.contains(p.id));
          if (a == null) return null;
          final b = opponentFor(a, where: (p) => topTier.contains(p.id));
          if (b == null) return null;
          take(a);
          take(b);
          return Card(mode: mode, photoIds: [a.id, b.id]);
        case GameMode.sort3:
          final a = next();
          if (a == null) return null;
          take(a);
          final b = opponentFor(a);
          if (b == null) return null;
          take(b);
          final c = opponentFor(a);
          if (c == null) return null;
          take(c);
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
        case GameMode.rerankTop:
          // Three photos that are all in the rated Top 10, sorted again.
          final top10 = byMu.take(10).map((p) => p.id).toSet();
          if (top10.length < 3) return null;
          final picks = <int>[];
          for (final p in ranked) {
            if (top10.contains(p.id) && !used.contains(p.id)) picks.add(p.id);
            if (picks.length == 3) break;
          }
          if (picks.length < 3) return null;
          used.addAll(picks);
          return Card(mode: mode, photoIds: picks..shuffle(_rng));
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

    // Delight rule: at least one current top-tier photo per (real) hand.
    // Tiny hands (a single CTA card) keep the mode they were asked for.
    final hasTop = cards.any((c) => c.photoIds.any(topTier.contains));
    if (!hasTop && topTier.isNotEmpty && cards.length >= 5) {
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

  /// A themed deck: [count] cards drawn from one slice of the library.
  /// Returns an empty list when the theme has too little material.
  List<Card> dealDeck(
    List<PhotoState> photos, {
    required DeckTheme theme,
    int count = 10,
    required DateTime now,
    Set<GameMode>? allowed,
  }) {
    final pool = _deckPool(photos, theme);
    if (pool.length < 4) return const [];
    final priority = {for (final p in pool) p.id: priorityOf(p, now, _rng)};
    final ordered = [...pool]..sort((a, b) => priority[b.id]!.compareTo(priority[a.id]!));
    final used = <int>{};
    final cards = <Card>[];
    final vibeOk = allowed == null || allowed.contains(GameMode.vibeCheck);

    List<int> take(int n) {
      final out = <int>[];
      for (final p in ordered) {
        if (used.contains(p.id)) continue;
        out.add(p.id);
        if (out.length == n) break;
      }
      if (out.length < n) return const [];
      used.addAll(out);
      return out;
    }

    if (theme == DeckTheme.rerankTop) {
      while (cards.length < count) {
        final trio = take(3);
        if (trio.isEmpty) break;
        cards.add(Card(mode: GameMode.rerankTop, photoIds: trio..shuffle(_rng)));
      }
      used.clear();
    }
    var i = 0;
    while (cards.length < count) {
      final wantVibe = vibeOk && i.isOdd;
      final ids = take(wantVibe ? 1 : 2);
      if (ids.isEmpty) {
        if (used.length >= pool.length) break;
        i++;
        continue;
      }
      cards.add(Card(mode: wantVibe ? GameMode.vibeCheck : GameMode.duel, photoIds: ids));
      i++;
    }
    return cards;
  }

  List<PhotoState> _deckPool(List<PhotoState> photos, DeckTheme theme) {
    switch (theme) {
      case DeckTheme.landscapes:
        return photos.where((p) => p.landscape).toList();
      case DeckTheme.rerankTop:
        final rated = photos.where((p) => p.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu));
        return rated.take(10).toList();
      case DeckTheme.oneTrip:
      case DeckTheme.sameMonth:
        final groups = <String, List<PhotoState>>{};
        for (final p in photos) {
          final t = p.takenAt;
          if (t == null) continue;
          final key = theme == DeckTheme.oneTrip ? '${t.year}-${t.month}-${t.day}' : '${t.year}-${t.month}';
          groups.putIfAbsent(key, () => []).add(p);
        }
        final big = groups.values.where((g) => g.length >= 6).toList();
        if (big.isEmpty) return const [];
        // Prefer groups with the most still-uncertain photos.
        big.sort((a, b) => b.fold(0.0, (s, p) => s + p.rd).compareTo(a.fold(0.0, (s, p) => s + p.rd)));
        final top = big.take(3).toList();
        return top[_rng.nextInt(top.length)];
    }
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
