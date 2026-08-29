import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/recovery/recovery_phrase.dart';

void main() {
  test('phrases: five list words, normalised input, validity', () {
    final p = RecoveryPhrase.generate(rng: Random(7));
    final words = p.split('-');
    expect(words.length, 5);
    expect(words.every(RecoveryPhrase.words.contains), isTrue);
    expect(p.length, greaterThanOrEqualTo(12), reason: 'GoTrue minimum password length');
    expect(RecoveryPhrase.normalize('  Apple bee-Cat, dog  egg '), 'apple-bee-cat-dog-egg');
    expect(RecoveryPhrase.looksValid('apple bee cat dog'), isFalse);
    expect(RecoveryPhrase.looksValid('apple bee cat dog egg'), isTrue);
    expect(RecoveryPhrase.words.toSet().length, RecoveryPhrase.words.length, reason: 'no duplicate words');
    final many = {for (var i = 0; i < 200; i++) RecoveryPhrase.generate()};
    expect(many.length, 200, reason: 'phrases are practically unique');
  });
}
