import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/bracket/bracket.dart';

void main() {
  final ids = List.generate(20, (i) => 100 + i);

  test('seeds 16 with standard pairings and plays to a champion', () {
    var b = Bracket.seed(ids)!;
    expect(b.seeds.length, 16);
    expect((b.current.first.a, b.current.first.b), (100, 115));
    expect(b.roundName(0), 'Round of 16');
    expect(b.matchesTotal, 15);
    while (!b.finished) {
      final m = b.nextMatch;
      if (m == null) {
        b = b.advance();
        continue;
      }
      b = b.decide(m.a); // higher seed always wins
    }
    expect(b.champion, 100);
    expect(b.rounds.length, 4);
    expect(b.roundName(3), 'Final');
    expect(b.matchesPlayed, 15);
  });

  test('seeds 8 when fewer than 16 rated, none below 8', () {
    expect(Bracket.seed(ids.take(10).toList())!.seeds.length, 8);
    expect(Bracket.seed(ids.take(7).toList()), isNull);
    expect(Bracket.seed(ids.take(8).toList())!.roundCount, 3);
  });

  test('undo reverts the last decision, crossing rounds when needed', () {
    var b = Bracket.seed(ids.take(8).toList())!;
    for (var i = 0; i < 4; i++) {
      b = b.decide(b.nextMatch!.a);
    }
    b = b.advance();
    expect(b.currentRound, 1);
    b = b.undo();
    expect(b.currentRound, 0);
    expect(b.current.where((m) => m.done).length, 3);
    expect(b.undo().current.where((m) => m.done).length, 2);
  });
}
