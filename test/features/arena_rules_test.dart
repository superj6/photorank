import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/data/arena/arena_models.dart';
import 'package:photorank/features/arena/arena_providers.dart';

void main() {
  test('isFromToday uses the US Pacific calendar day', () {
    final now = DateTime.utc(2026, 8, 25, 16, 30); // 09:30 PDT, Aug 25
    expect(isFromToday(DateTime.utc(2026, 8, 25, 7, 5), now: now), isTrue, reason: '00:05 PDT that day');
    expect(isFromToday(DateTime.utc(2026, 8, 25, 6, 55), now: now), isFalse, reason: '23:55 PDT the day before');
    expect(isFromToday(DateTime.utc(2026, 8, 25, 4, 0), now: now), isFalse, reason: '21:00 PDT the day before, same UTC date');
    expect(isFromToday(DateTime.utc(2026, 8, 26, 6, 0), now: now), isTrue, reason: '23:00 PDT that evening, next UTC date');
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
