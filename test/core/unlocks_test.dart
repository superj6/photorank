import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/beats/unlocks.dart';
import 'package:photorank/core/rating/observation.dart';

void main() {
  test('new installs start with duel + vibe check', () {
    expect(Unlocks.unlocked(0), {GameMode.duel, GameMode.vibeCheck});
  });

  test('modes unlock at their thresholds, in order', () {
    expect(Unlocks.unlocked(29).contains(GameMode.rate), isFalse);
    expect(Unlocks.unlocked(30).contains(GameMode.rate), isTrue);
    expect(Unlocks.next(30), (GameMode.bestOfBurst, 60));
    expect(Unlocks.newlyUnlocked(55, 100), [GameMode.bestOfBurst, GameMode.sort3]);
    expect(Unlocks.newlyUnlocked(100, 120), isEmpty);
  });

  test('unlock all opens everything and next() becomes null past the end', () {
    expect(Unlocks.unlocked(0, all: true), Unlocks.thresholds.keys.toSet());
    expect(Unlocks.next(10000), isNull);
    expect(Unlocks.themedHands(99), isFalse);
    expect(Unlocks.themedHands(100), isTrue);
  });
}
