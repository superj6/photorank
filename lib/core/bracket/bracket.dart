/// Single-elimination bracket over seeded photo ids. Pure.
class Match {
  const Match({required this.a, required this.b, this.winner});
  final int a;
  final int b;
  final int? winner;
  bool get done => winner != null;
  int get loser => winner == a ? b : a;
  Match withWinner(int w) => Match(a: a, b: b, winner: w);
}

class Bracket {
  const Bracket({required this.seeds, required this.rounds});

  /// Seeded best first (1..N). N is 8 or 16.
  final List<int> seeds;
  final List<List<Match>> rounds;

  static const seedOrder16 = [1, 16, 8, 9, 5, 12, 4, 13, 6, 11, 3, 14, 7, 10, 2, 15];
  static const seedOrder8 = [1, 8, 4, 5, 3, 6, 2, 7];

  /// Builds round one from the top 16 (or top 8) of [rankedIds].
  static Bracket? seed(List<int> rankedIds) {
    final n = rankedIds.length >= 16 ? 16 : rankedIds.length >= 8 ? 8 : 0;
    if (n == 0) return null;
    final seeds = rankedIds.take(n).toList();
    final order = n == 16 ? seedOrder16 : seedOrder8;
    final first = [
      for (var i = 0; i < order.length; i += 2) Match(a: seeds[order[i] - 1], b: seeds[order[i + 1] - 1]),
    ];
    return Bracket(seeds: seeds, rounds: [first]);
  }

  int get roundCount => seeds.length == 16 ? 4 : 3;
  int get currentRound => rounds.length - 1;
  List<Match> get current => rounds.last;
  bool get roundDone => current.every((m) => m.done);
  bool get finished => rounds.length == roundCount && roundDone;
  int? get champion => finished ? current.single.winner : null;

  /// The next undecided match in the current round.
  Match? get nextMatch {
    for (final m in current) {
      if (!m.done) return m;
    }
    return null;
  }

  int get matchesPlayed => rounds.fold(0, (n, r) => n + r.where((m) => m.done).length);
  int get matchesTotal => seeds.length - 1;

  String roundName(int index) {
    final remaining = roundCount - index;
    return switch (remaining) { 1 => 'Final', 2 => 'Semi-finals', 3 => 'Quarter-finals', _ => 'Round of ${seeds.length}' };
  }

  Bracket decide(int winner) {
    final idx = current.indexWhere((m) => !m.done);
    if (idx < 0) return this;
    final m = current[idx];
    assert(winner == m.a || winner == m.b);
    final updated = [...current]..[idx] = m.withWinner(winner);
    return Bracket(seeds: seeds, rounds: [...rounds.sublist(0, rounds.length - 1), updated]);
  }

  /// Opens the next round once the current one is complete.
  Bracket advance() {
    if (!roundDone || rounds.length == roundCount) return this;
    final winners = current.map((m) => m.winner!).toList();
    final next = [for (var i = 0; i < winners.length; i += 2) Match(a: winners[i], b: winners[i + 1])];
    return Bracket(seeds: seeds, rounds: [...rounds, next]);
  }

  /// Undo the most recent decision (within the current round only).
  Bracket undo() {
    final r = [...current];
    for (var i = r.length - 1; i >= 0; i--) {
      if (r[i].done) {
        r[i] = Match(a: r[i].a, b: r[i].b);
        return Bracket(seeds: seeds, rounds: [...rounds.sublist(0, rounds.length - 1), r]);
      }
    }
    if (rounds.length > 1) {
      return Bracket(seeds: seeds, rounds: rounds.sublist(0, rounds.length - 1)).undo();
    }
    return this;
  }
}
