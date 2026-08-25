import 'dart:math';

import '../dealer/photo_state.dart';

/// Browse channels. Each is a different way of letting the ranking pick.
enum Channel { topShelf, wildcard, timeMachine, deepCuts, rising, thisDay, collection }

/// Draws photos with probability shaped by their rank.
class RankSampler {
  RankSampler({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  /// Softmax over mu with [temperature]; lower = favours the top harder.
  /// `temperature == null` means uniform. Never repeats within one call and
  /// skips [exclude].
  List<PhotoState> sample(
    List<PhotoState> pool, {
    required int count,
    double? temperature = 150,
    Set<int> exclude = const {},
  }) {
    final candidates = pool.where((p) => !exclude.contains(p.id)).toList();
    if (candidates.isEmpty || count <= 0) return const [];
    if (temperature == null) {
      candidates.shuffle(_rng);
      return candidates.take(count).toList();
    }
    final maxMu = candidates.map((p) => p.mu).reduce(max);
    final weights = [
      for (final p in candidates) exp((p.mu - maxMu) / temperature),
    ];
    final out = <PhotoState>[];
    var total = weights.fold(0.0, (a, b) => a + b);
    final taken = List<bool>.filled(candidates.length, false);
    while (out.length < count && out.length < candidates.length) {
      var r = _rng.nextDouble() * total;
      var idx = -1;
      for (var i = 0; i < candidates.length; i++) {
        if (taken[i]) continue;
        r -= weights[i];
        if (r <= 0) {
          idx = i;
          break;
        }
      }
      if (idx == -1) {
        idx = taken.lastIndexOf(false);
      }
      taken[idx] = true;
      total -= weights[idx];
      out.add(candidates[idx]);
    }
    return out;
  }

  /// Top [fraction] of the pool by mu (at least [minCount]), shuffled.
  List<PhotoState> topShelf(
    List<PhotoState> pool, {
    required int count,
    double fraction = 0.05,
    int minCount = 20,
    Set<int> exclude = const {},
  }) {
    final sorted = [...pool]..sort((a, b) => b.mu.compareTo(a.mu));
    final n = max(minCount, (sorted.length * fraction).ceil()).clamp(0, sorted.length);
    return sample(sorted.take(n).toList(),
        count: count, temperature: null, exclude: exclude);
  }

  /// Highly ranked but rarely viewed.
  List<PhotoState> deepCuts(
    List<PhotoState> pool, {
    required int count,
    Set<int> exclude = const {},
  }) {
    final settled = pool.where((p) => p.rating.confidence >= 0.5).toList();
    final byViews = settled..sort((a, b) => a.views.compareTo(b.views));
    final quiet = byViews.take(max(count * 5, byViews.length ~/ 4)).toList();
    return sample(quiet, count: count, temperature: 120, exclude: exclude);
  }

  /// A random day (by capture date) shown best-first.
  List<PhotoState> timeMachine(List<PhotoState> pool, {DateTime? day}) {
    final byDay = <DateTime, List<PhotoState>>{};
    for (final p in pool) {
      final t = p.takenAt;
      if (t == null) continue;
      final key = DateTime(t.year, t.month, t.day);
      byDay.putIfAbsent(key, () => []).add(p);
    }
    if (byDay.isEmpty) return const [];
    final key = day != null && byDay.containsKey(day)
        ? day
        : byDay.keys.elementAt(_rng.nextInt(byDay.length));
    return byDay[key]!..sort((a, b) => b.mu.compareTo(a.mu));
  }
}
