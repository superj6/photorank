import '../rating/observation.dart';

/// Progressive mode unlocks: new things keep appearing for the first few
/// hundred decisions. Existing installs (and power users) can unlock all.
class Unlocks {
  Unlocks._();

  /// Decisions needed before a mode appears. Absent = never dealt by unlock
  /// rules (browseHeart is not a dealt mode).
  static const Map<GameMode, int> thresholds = {
    GameMode.duel: 0,
    GameMode.vibeCheck: 0,
    GameMode.rate: 30,
    GameMode.bestOfBurst: 60,
    GameMode.sort3: 100,
    GameMode.challenger: 150,
    GameMode.rerankTop: 300,
  };

  static const int themedHandsAt = 100;

  static Set<GameMode> unlocked(int decisions, {bool all = false}) => {
        for (final e in thresholds.entries)
          if (all || decisions >= e.value) e.key,
      };

  static bool isUnlocked(GameMode m, int decisions, {bool all = false}) =>
      all || (thresholds[m] != null && decisions >= thresholds[m]!);

  /// Next mode to unlock and at what count, or null when everything is open.
  static (GameMode, int)? next(int decisions) {
    (GameMode, int)? best;
    for (final e in thresholds.entries) {
      if (e.value > decisions && (best == null || e.value < best.$2)) {
        best = (e.key, e.value);
      }
    }
    return best;
  }

  /// Modes whose threshold lies in (before, after].
  static List<GameMode> newlyUnlocked(int before, int after) => [
        for (final e in thresholds.entries)
          if (e.value > before && e.value <= after) e.key,
      ]..sort((a, b) => thresholds[a]!.compareTo(thresholds[b]!));

  static bool themedHands(int decisions, {bool all = false}) =>
      all || decisions >= themedHandsAt;
}
