import 'glicko.dart';

/// Fixed virtual opponents that let absolute judgements (stars, vibe checks)
/// feed the same pairwise engine as duels.
class Anchors {
  Anchors._();

  /// Anchors are nearly certain so they barely move the scale.
  static const double rd = 30;

  /// 1★ … 5★.
  static const List<double> stars = [1100, 1300, 1500, 1700, 1900];

  /// "Feeling it / not feeling it" threshold.
  static const double vibe = 1400;

  static Rating star(int stars) {
    assert(stars >= 1 && stars <= 5);
    return Rating(mu: Anchors.stars[stars - 1], rd: rd);
  }

  static Rating at(double mu) => Rating(mu: mu, rd: rd);
}
