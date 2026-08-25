import '../dealer/dealer.dart';
import '../rating/observation.dart';
import 'beat_engine.dart';

/// When most of the library is settled, hands get shorter and lean toward
/// defending the top and ranking new arrivals, so the game stays fresh.
class LateGamePolicy {
  LateGamePolicy._();

  static DealerConfig adjust(DealerConfig config, LibraryStats stats) {
    if (!stats.lateGame) return config;
    final weights = <GameMode, double>{
      for (final e in config.modeWeights.entries) e.key: e.value,
    };
    void boost(GameMode m, double factor) {
      if ((weights[m] ?? 0) > 0) weights[m] = weights[m]! * factor;
    }
    boost(GameMode.challenger, 3);
    boost(GameMode.rerankTop, 2);
    boost(GameMode.vibeCheck, 1.5);
    return DealerConfig(
      modeWeights: weights,
      handSize: config.handSize > 10 ? 10 : config.handSize,
      topTierSize: config.topTierSize,
      weights: PriorityWeights(
        uncertainty: config.weights.uncertainty,
        recency: config.weights.recency * 3, // new arrivals first
        neglect: config.weights.neglect,
        noise: config.weights.noise * 1.5,
      ),
    );
  }
}
