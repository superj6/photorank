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

  final double uncertainty;
  final double recency;
  final double neglect;
  final double noise;
}

double priorityOf(PhotoState p, DateTime now, Random rng,
    {PriorityWeights w = const PriorityWeights()}) {
  final uncertainty = (p.rd - Rating.minRd) / (Rating.initialRd - Rating.minRd);
  final recentlyAdded = p.addedAt == null
      ? 0.0
      : (1 - now.difference(p.addedAt!).inDays / 14).clamp(0.0, 1.0);
  final neglect = p.lastShownAt == null
      ? 1.0
      : (now.difference(p.lastShownAt!).inDays / 30).clamp(0.0, 1.0);
  return w.uncertainty * uncertainty +
      w.recency * recentlyAdded +
      w.neglect * neglect +
      w.noise * rng.nextDouble();
}
