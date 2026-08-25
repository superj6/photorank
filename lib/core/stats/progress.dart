import 'dart:math';

/// XP = decisions. Levels get progressively longer; level 1 starts at 0.
class Level {
  const Level._(this.level, this.into, this.span);

  final int level;

  /// XP earned inside the current level and the level's total span.
  final int into;
  final int span;

  double get fraction => span == 0 ? 1 : into / span;

  static int spanFor(int level) => 25 + (level - 1) * 15;

  static Level fromXp(int xp) {
    var level = 1;
    var remaining = max(0, xp);
    while (remaining >= spanFor(level)) {
      remaining -= spanFor(level);
      level++;
    }
    return Level._(level, remaining, spanFor(level));
  }

  static String title(int level) => switch (level) {
        <= 2 => 'Browser',
        <= 5 => 'Sorter',
        <= 9 => 'Curator',
        <= 14 => 'Editor',
        <= 20 => 'Archivist',
        _ => 'Connoisseur',
      };
}

/// Everything a badge rule may look at.
class ProgressFacts {
  const ProgressFacts({
    required this.decisions,
    required this.sessions,
    required this.streak,
    required this.burstsCleared,
    required this.settledFraction,
    required this.topTenOfficial,
    required this.unlockedAll,
    required this.duels,
    required this.moments,
    required this.shares,
  });

  final int decisions;
  final int sessions;
  final int streak;
  final int burstsCleared;
  final double settledFraction;
  final bool topTenOfficial;
  final bool unlockedAll;
  final int duels;
  final int moments;
  final int shares;
}

class Badge {
  const Badge(this.id, this.title, this.description, this.earned);
  final String id;
  final String title;
  final String description;
  final bool Function(ProgressFacts f) earned;
}

/// Badge catalogue, in the order they are shown.
class Badges {
  Badges._();

  static final List<Badge> all = [
    Badge('first_hand', 'First hand', 'Finished your first hand', (f) => f.sessions >= 1),
    Badge('d100', 'Century', '100 decisions', (f) => f.decisions >= 100),
    Badge('d500', 'Five hundred', '500 decisions', (f) => f.decisions >= 500),
    Badge('d1000', 'Thousand', '1,000 decisions', (f) => f.decisions >= 1000),
    Badge('d5000', 'Five thousand', '5,000 decisions', (f) => f.decisions >= 5000),
    Badge('streak7', 'One week', '7-day streak', (f) => f.streak >= 7),
    Badge('streak30', 'One month', '30-day streak', (f) => f.streak >= 30),
    Badge('bursts10', 'Burst breaker', 'Settled 10 bursts', (f) => f.burstsCleared >= 10),
    Badge('duels250', 'Duelist', '250 duels', (f) => f.duels >= 250),
    Badge('half', 'Halfway', 'Half your library settled', (f) => f.settledFraction >= 0.5),
    Badge('settled', 'Settled', 'Whole library settled', (f) => f.settledFraction >= 1.0),
    Badge('top10', 'Top shelf', 'Your Top 10 is official', (f) => f.topTenOfficial),
    Badge('modes', 'Full deck', 'Every mode unlocked', (f) => f.unlockedAll),
    Badge('share', 'Show-off', 'Shared a moment', (f) => f.shares >= 1),
  ];

  static Set<String> earned(ProgressFacts f) => {for (final b in all) if (b.earned(f)) b.id};

  static List<Badge> newlyEarned(ProgressFacts before, ProgressFacts after) {
    final b = earned(before);
    return [for (final badge in all) if (!b.contains(badge.id) && badge.earned(after)) badge];
  }
}
