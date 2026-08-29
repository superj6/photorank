import 'dart:math' as math;

/// A photo's standing on one axis: skill estimate [mu] and uncertainty [rd].
class Rating {
  const Rating({required this.mu, required this.rd});

  static const double initialMu = 1500;
  static const double initialRd = 350;
  static const double minRd = 30;
  static const Rating initial = Rating(mu: initialMu, rd: initialRd);

  final double mu;
  final double rd;

  /// The number shown to the user: the raw Glicko rating itself (Elo-like,
  /// starts at 1500, no ceiling). Kept under this name so deltas and gates
  /// read the same as the display.
  double get score => mu;

  /// 0 = brand new, 1 = fully settled.
  double get confidence =>
      (1 - (rd - minRd) / (initialRd - minRd)).clamp(0, 1).toDouble();

  Rating copyWith({double? mu, double? rd}) =>
      Rating(mu: mu ?? this.mu, rd: rd ?? this.rd);

  @override
  String toString() => 'Rating(mu: ${mu.toStringAsFixed(1)}, rd: ${rd.toStringAsFixed(1)})';

  @override
  bool operator ==(Object other) =>
      other is Rating && other.mu == mu && other.rd == rd;

  @override
  int get hashCode => Object.hash(mu, rd);
}

/// Result of a pairing from the *subject's* point of view.
enum Outcome {
  win(1.0),
  draw(0.5),
  loss(0.0);

  const Outcome(this.value);
  final double value;

  Outcome get inverse => switch (this) {
        Outcome.win => Outcome.loss,
        Outcome.loss => Outcome.win,
        Outcome.draw => Outcome.draw,
      };
}

/// Glicko-1 update rules, applied one observation at a time.
///
/// Sequential single-observation updates keep undo trivial (restore the
/// snapshot taken before the observation) and are plenty accurate for a
/// system where every card yields at most a handful of pairings.
class Glicko {
  Glicko._();

  static final double q = math.ln10 / 400;

  static double g(double rd) =>
      1 / math.sqrt(1 + 3 * q * q * rd * rd / (math.pi * math.pi));

  /// Probability that [a] beats [b].
  static double expected(Rating a, Rating b) =>
      1 / (1 + math.pow(10, -g(b.rd) * (a.mu - b.mu) / 400));

  /// New rating for [a] after facing [b] with [outcome] (from a's view).
  ///
  /// [weight] in (0, 1] scales how much the observation moves [a]; used for
  /// weak signals such as a browse ❤.
  static Rating updateOne(Rating a, Rating b, Outcome outcome,
      {double weight = 1.0}) {
    assert(weight > 0 && weight <= 1);
    final gb = g(b.rd);
    final e = expected(a, b);
    final d2 = 1 / (q * q * gb * gb * e * (1 - e));
    final invRd2 = 1 / (a.rd * a.rd);
    final delta = q / (invRd2 + 1 / d2) * gb * (outcome.value - e);
    final newRd = math
        .sqrt(1 / (invRd2 + weight / d2))
        .clamp(Rating.minRd, Rating.initialRd)
        .toDouble();
    return Rating(mu: a.mu + weight * delta, rd: newRd);
  }

  /// Update both sides of a pairing from their pre-update values.
  static (Rating a, Rating b) updatePair(Rating a, Rating b, Outcome outcomeForA,
      {double weight = 1.0}) {
    final na = updateOne(a, b, outcomeForA, weight: weight);
    final nb = updateOne(b, a, outcomeForA.inverse, weight: weight);
    return (na, nb);
  }
}
