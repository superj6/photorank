import 'anchors.dart';
import 'glicko.dart';

/// Where an observation came from. Every mode is a ranking signal; there is
/// no mode that discards, hides, or flags a photo.
enum GameMode {
  duel,
  vibeCheck,
  rate,
  bestOfBurst,
  sort3,
  challenger,

  /// Sort three photos that are all in your Top 10.
  rerankTop,
  browseHeart,
}

/// One pairwise fact: [subjectId] faced either another photo ([opponentId])
/// or a virtual anchor ([anchorMu]) and got [outcome].
class Observation {
  Observation({
    this.id,
    required this.axisId,
    this.sessionId,
    required this.cardId,
    required this.mode,
    required this.subjectId,
    this.opponentId,
    this.anchorMu,
    required this.outcome,
    this.weight = 1.0,
    required this.createdAt,
  }) : assert((opponentId == null) != (anchorMu == null),
            'exactly one of opponentId / anchorMu must be set');

  final int? id;
  final int axisId;
  final int? sessionId;

  /// Groups every observation produced by a single card so Undo can revert
  /// the whole card at once.
  final String cardId;
  final GameMode mode;
  final int subjectId;
  final int? opponentId;
  final double? anchorMu;
  final Outcome outcome;
  final double weight;
  final DateTime createdAt;

  bool get isAnchor => anchorMu != null;

  Rating get anchorRating => Anchors.at(anchorMu!);

  Observation copyWith({int? id, int? sessionId}) => Observation(
        id: id ?? this.id,
        axisId: axisId,
        sessionId: sessionId ?? this.sessionId,
        cardId: cardId,
        mode: mode,
        subjectId: subjectId,
        opponentId: opponentId,
        anchorMu: anchorMu,
        outcome: outcome,
        weight: weight,
        createdAt: createdAt,
      );
}

/// Turns what the user did on a card into the list of observations it implies.
class Decompose {
  Decompose._();

  static List<Observation> duel({
    required int axisId,
    required String cardId,
    required int winnerId,
    required int loserId,
    required DateTime now,
    GameMode mode = GameMode.duel,
  }) =>
      [
        Observation(
          axisId: axisId,
          cardId: cardId,
          mode: mode,
          subjectId: winnerId,
          opponentId: loserId,
          outcome: Outcome.win,
          createdAt: now,
        ),
      ];

  static List<Observation> vibe({
    required int axisId,
    required String cardId,
    required int photoId,
    required bool feelingIt,
    required DateTime now,
  }) =>
      [
        Observation(
          axisId: axisId,
          cardId: cardId,
          mode: GameMode.vibeCheck,
          subjectId: photoId,
          anchorMu: Anchors.vibe,
          outcome: feelingIt ? Outcome.win : Outcome.loss,
          createdAt: now,
        ),
      ];

  /// [stars] 1..5 → win vs lower anchors, draw vs own anchor, loss vs higher.
  static List<Observation> rate({
    required int axisId,
    required String cardId,
    required int photoId,
    required int stars,
    required DateTime now,
  }) {
    assert(stars >= 1 && stars <= 5);
    return [
      for (var level = 1; level <= 5; level++)
        Observation(
          axisId: axisId,
          cardId: cardId,
          mode: GameMode.rate,
          subjectId: photoId,
          anchorMu: Anchors.stars[level - 1],
          outcome: level < stars
              ? Outcome.win
              : level == stars
                  ? Outcome.draw
                  : Outcome.loss,
          createdAt: now,
        ),
    ];
  }

  /// [orderedIds] best first → every pair (i beats j for i < j).
  static List<Observation> sort({
    required int axisId,
    required String cardId,
    required List<int> orderedIds,
    required DateTime now,
    GameMode mode = GameMode.sort3,
  }) =>
      [
        for (var i = 0; i < orderedIds.length; i++)
          for (var j = i + 1; j < orderedIds.length; j++)
            Observation(
              axisId: axisId,
              cardId: cardId,
              mode: mode,
              subjectId: orderedIds[i],
              opponentId: orderedIds[j],
              outcome: Outcome.win,
              createdAt: now,
            ),
      ];

  /// Winner beats each sibling; siblings are not ranked against each other.
  static List<Observation> burst({
    required int axisId,
    required String cardId,
    required int winnerId,
    required Iterable<int> siblingIds,
    required DateTime now,
  }) =>
      [
        for (final sib in siblingIds)
          if (sib != winnerId)
            Observation(
              axisId: axisId,
              cardId: cardId,
              mode: GameMode.bestOfBurst,
              subjectId: winnerId,
              opponentId: sib,
              outcome: Outcome.win,
              createdAt: now,
            ),
      ];

  /// A ❤ while browsing: a light "feeling it".
  static List<Observation> heart({
    required int axisId,
    required String cardId,
    required int photoId,
    required DateTime now,
  }) =>
      [
        Observation(
          axisId: axisId,
          cardId: cardId,
          mode: GameMode.browseHeart,
          subjectId: photoId,
          anchorMu: Anchors.vibe,
          outcome: Outcome.win,
          weight: 0.3,
          createdAt: now,
        ),
      ];
}
