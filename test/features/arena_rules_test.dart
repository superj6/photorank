import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/data/arena/arena_models.dart';
import 'package:photorank/features/arena/arena_providers.dart';

void main() {
  test('isFromToday uses the local calendar day', () {
    final now = DateTime(2026, 8, 25, 9, 30);
    expect(isFromToday(DateTime(2026, 8, 25, 0, 5), now: now), isTrue);
    expect(isFromToday(DateTime(2026, 8, 24, 23, 55), now: now), isFalse);
    expect(isFromToday(DateTime(2026, 8, 25, 23, 59), now: now), isTrue);
  });

  test('status: left duels and unlock', () {
    const s = ArenaStatus(hasEntry: true, duelsToday: 4, required: 10, unlocked: false, others: 20);
    expect(s.left, 6);
    const done = ArenaStatus(hasEntry: true, duelsToday: 10, required: 10, unlocked: true, others: 20);
    expect(done.left, 0);
    const alone = ArenaStatus(hasEntry: true, duelsToday: 0, required: 0, unlocked: true, others: 0);
    expect(alone.left, 0);
  });

  test('history percentile', () {
    final r = HistoryRow(day: DateTime(2026, 8, 24), entryId: 'e', storagePath: 'p', finalRank: 10, total: 100, duels: 8, wins: 5, status: 'active');
    expect(r.percentile, 91);
  });
}
