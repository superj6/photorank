import 'glicko.dart';
import 'observation.dart';

/// Ratings involved in one observation, before and after applying it.
class RatingDelta {
  const RatingDelta({required this.before, required this.after});
  final Map<int, Rating> before;
  final Map<int, Rating> after;
}

/// Applies observations to ratings. Pure; persistence lives elsewhere.
class RatingEngine {
  const RatingEngine();

  RatingDelta apply(Observation o, Rating Function(int photoId) lookup) {
    final a = lookup(o.subjectId);
    if (o.isAnchor) {
      final na = Glicko.updateOne(a, o.anchorRating, o.outcome, weight: o.weight);
      return RatingDelta(before: {o.subjectId: a}, after: {o.subjectId: na});
    }
    final b = lookup(o.opponentId!);
    final (na, nb) = Glicko.updatePair(a, b, o.outcome, weight: o.weight);
    return RatingDelta(
      before: {o.subjectId: a, o.opponentId!: b},
      after: {o.subjectId: na, o.opponentId!: nb},
    );
  }

  /// Applies a card's observations in order, threading updates through.
  RatingDelta applyAll(
      Iterable<Observation> observations, Rating Function(int) lookup) {
    final before = <int, Rating>{};
    final current = <int, Rating>{};
    Rating look(int id) => current[id] ?? lookup(id);
    for (final o in observations) {
      final d = apply(o, look);
      for (final e in d.before.entries) {
        before.putIfAbsent(e.key, () => e.value);
      }
      current.addAll(d.after);
    }
    return RatingDelta(before: before, after: current);
  }
}
