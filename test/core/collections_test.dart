import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/rating/glicko.dart';
import 'package:photorank/core/sampler/collections.dart';
import 'package:photorank/core/dealer/photo_state.dart';

void main() {
  final states = [
    for (var i = 0; i < 40; i++)
      PhotoState(
        id: i,
        rating: Rating(mu: 1900 - i * 10, rd: 40),
        observations: i < 36 ? 2 : 0,
        takenAt: i < 8 ? DateTime(2026, 3, 5, 9 + i) : DateTime(2025, 8, 20 + i % 8, 12),
        clusterId: i < 6 ? 1 : i < 9 ? 2 : null,
      ),
  ];

  test('collections: top 10, years, months, trip days, bursts', () {
    final c = buildCollections(states);
    final ids = c.map((x) => x.id).toList();
    expect(ids.first, 'top');
    expect(c.first.ids.length, 10);
    expect(ids, contains('year-2026'));
    expect(ids, contains('year-2025'));
    expect(ids, contains('month-2026-03'));
    expect(ids.any((x) => x.startsWith('day-2026-03-05')), isTrue);
    expect(c.firstWhere((x) => x.id == 'bursts').ids, [0, 6]);
    expect(c.every((x) => x.ids.isNotEmpty), isTrue);
  });

  test('this day looks at other years and widens when empty', () {
    final exact = thisDay(states, DateTime(2026, 8, 21));
    expect(exact, isNotEmpty);
    expect(exact.every((s) => s.takenAt!.year == 2025 && s.takenAt!.day == 21), isTrue);
    final near = thisDay(states, DateTime(2026, 8, 18));
    expect(near, isNotEmpty);
    expect(thisDay(states, DateTime(2026, 1, 1)), isEmpty);
  });
}
