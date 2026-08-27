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
  });

  /// How long a photo counts as "just taken".
  static const freshFor = Duration(days: 14);

  final double uncertainty;
  final double recency;
  final double neglect;
  final double noise;
}

double priorityOf(PhotoState p, DateTime now, Random rng,
    {PriorityWeights w = const PriorityWeights()}) {
  final uncertainty = (p.rd - Rating.minRd) / (Rating.initialRd - Rating.minRd);
  // Capture time, not index time: importing an old archive should not make
  // ten thousand photos count as "new" for a fortnight. Photos with no date
  // fall back to when they were indexed.
  final shotAt = p.takenAt ?? p.addedAt;
  final recentlyAdded = shotAt == null
      ? 0.0
      : (1 - now.difference(shotAt).inDays / PriorityWeights.freshFor.inDays).clamp(0.0, 1.0);
  final neglect = p.lastShownAt == null
      ? 1.0
      : (now.difference(p.lastShownAt!).inDays / 30).clamp(0.0, 1.0);
  return w.uncertainty * uncertainty +
      w.recency * recentlyAdded +
      w.neglect * neglect +
      w.noise * rng.nextDouble();
}
