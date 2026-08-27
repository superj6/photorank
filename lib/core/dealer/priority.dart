import 'dart:math';

import '../rating/glicko.dart';
import 'photo_state.dart';

/// Weights for how badly a photo "wants" to be shown next.
class PriorityWeights {
  const PriorityWeights({
    this.uncertainty = 1.0,
    this.recency = 0.6,
    this.neglect = 0.4,
    this.noise = 0.3,
    this.sharpness = 3.0,
  });

  /// How long a photo counts as "just indexed".
  static const freshFor = Duration(days: 14);

  /// How strongly priority bends the draw in [weightedOrder]. 0 is a plain
  /// shuffle, 1 makes a photo's chance proportional to its priority, and
  /// larger values sharpen the preference; very large approaches a strict
  /// sort, with the repetition that brings.
  final double sharpness;

  final double uncertainty;
  final double recency;
  final double neglect;
  final double noise;
}

/// Orders [photos] so that higher-priority photos come first *on average*,
/// without the highest scorers always winning.
///
/// A strict sort deals the same top slice hand after hand: anything with a
/// systematic edge (a batch indexed yesterday, say) sits at the top until its
/// priority decays, and because photos are indexed folder by folder that
/// batch tends to be one stretch of the calendar — so the game keeps showing
/// the same date ranges. Weighted sampling keeps the same preference while
/// letting the whole library through.
///
/// Uses the Efraimidis–Spirakis key `U^(1/w)`: sorting by it descending is a
/// weighted random order without replacement.
List<PhotoState> weightedOrder(
  Iterable<PhotoState> photos,
  DateTime now,
  Random rng, {
  PriorityWeights w = const PriorityWeights(),
}) {
  final keyed = <(double, PhotoState)>[];
  for (final p in photos) {
    final weight = pow(max(priorityOf(p, now, rng, w: w), 1e-6), w.sharpness).toDouble();
    // U^(1/weight), via logs so tiny weights cannot underflow to zero.
    final u = rng.nextDouble().clamp(1e-12, 1.0);
    keyed.add((log(u) / weight, p));
  }
  keyed.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final k in keyed) k.$2];
}

double priorityOf(PhotoState p, DateTime now, Random rng,
    {PriorityWeights w = const PriorityWeights()}) {
  final uncertainty = (p.rd - Rating.minRd) / (Rating.initialRd - Rating.minRd);
  // Index time, not capture time: the point is to rank photos that have just
  // joined the library, whatever their age. On a bulk import this lifts
  // everything equally, so it never favours one stretch of the calendar.
  final recentlyAdded = p.addedAt == null
      ? 0.0
      : (1 - now.difference(p.addedAt!).inDays / PriorityWeights.freshFor.inDays).clamp(0.0, 1.0);
  final neglect = p.lastShownAt == null
      ? 1.0
      : (now.difference(p.lastShownAt!).inDays / 30).clamp(0.0, 1.0);
  return w.uncertainty * uncertainty +
      w.recency * recentlyAdded +
      w.neglect * neglect +
      w.noise * rng.nextDouble();
}
