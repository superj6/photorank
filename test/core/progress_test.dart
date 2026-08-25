import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/stats/progress.dart';

ProgressFacts facts({int decisions = 0, int sessions = 0, int streak = 0, int bursts = 0, double settled = 0, bool top = false, bool all = false, int duels = 0, int shares = 0}) =>
    ProgressFacts(decisions: decisions, sessions: sessions, streak: streak, burstsCleared: bursts, settledFraction: settled, topTenOfficial: top, unlockedAll: all, duels: duels, moments: 0, shares: shares);

void main() {
  test('levels get longer and fractions are sane', () {
    expect(Level.fromXp(0).level, 1);
    expect(Level.fromXp(24).level, 1);
    expect(Level.fromXp(25).level, 2);
    expect(Level.fromXp(25).into, 0);
    expect(Level.fromXp(25 + 40 - 1).level, 2);
    expect(Level.fromXp(25 + 40).level, 3);
    final l = Level.fromXp(30);
    expect(l.fraction, closeTo(5 / 40, 1e-9));
    expect(Level.title(1), 'Browser');
    expect(Level.title(12), 'Editor');
  });

  test('badges are earned monotonically and newlyEarned diffs', () {
    final before = facts(decisions: 90, sessions: 3, streak: 6);
    final after = facts(decisions: 101, sessions: 4, streak: 7, shares: 1);
    final fresh = Badges.newlyEarned(before, after).map((b) => b.id).toList();
    expect(fresh, ['d100', 'streak7', 'share']);
    expect(Badges.earned(after), containsAll(['first_hand', 'd100', 'streak7', 'share']));
    expect(Badges.earned(facts()), isEmpty);
    expect(Badges.all.map((b) => b.id).toSet().length, Badges.all.length);
  });
}
