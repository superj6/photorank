import 'dart:math';

import '../dealer/photo_state.dart';

/// Two ways a friend can play on your photos.
enum GuestMode {
  /// "Do we agree?" — they rank as themselves; we measure agreement.
  taste,

  /// "Do you know me?" — they guess what *you* picked.
  guess,
}

enum GuestCardKind { duel, vibe }

class GuestCard {
  const GuestCard.duel(this.a, this.b, {required this.ownerPick})
      : kind = GuestCardKind.duel,
        ownerFeelsIt = null;
  const GuestCard.vibe(this.a, {required this.ownerFeelsIt})
      : kind = GuestCardKind.vibe,
        b = null,
        ownerPick = null;

  final GuestCardKind kind;
  final int a;
  final int? b;

  /// For duels: the photo the owner ranks higher.
  final int? ownerPick;

  /// For vibe checks: whether the owner's score is on the "feeling it" side.
  final bool? ownerFeelsIt;
}

class GuestAnswer {
  const GuestAnswer({required this.card, required this.pickedId, required this.feltIt, required this.agreed});
  final GuestCard card;
  final int? pickedId;
  final bool? feltIt;
  final bool agreed;
}

class GuestResult {
  const GuestResult({required this.name, required this.mode, required this.answers});
  final String name;
  final GuestMode mode;
  final List<GuestAnswer> answers;
  int get agreed => answers.where((a) => a.agreed).length;
  int get total => answers.length;
  int get pct => total == 0 ? 0 : agreed * 100 ~/ total;
  List<GuestAnswer> get disagreements => answers.where((a) => !a.agreed).toList();
}

/// Builds and scores a guest hand from the owner's *settled* photos only,
/// so agreement is measured against opinions the owner actually holds.
class GuestGame {
  GuestGame._();

  static const feelingThreshold = 1550.0; // rating: 'feeling it' side of average
  static const minDuelGap = 90.0; // mu

  static List<GuestCard> build(List<PhotoState> states, {int duels = 7, int vibes = 3, Random? rng}) {
    final r = rng ?? Random();
    final settled = states.where((s) => s.observations >= 2 && s.rating.confidence >= 0.3).toList();
    if (settled.length < 4) return const [];
    final cards = <GuestCard>[];
    final used = <int>{};
    final shuffled = [...settled]..shuffle(r);
    // Duels: pairs with a clear owner preference.
    outer:
    for (final a in shuffled) {
      if (cards.where((c) => c.kind == GuestCardKind.duel).length >= duels) break;
      if (used.contains(a.id)) continue;
      for (final b in shuffled) {
        if (b.id == a.id || used.contains(b.id)) continue;
        if ((a.mu - b.mu).abs() >= minDuelGap) {
          used.addAll([a.id, b.id]);
          final pair = r.nextBool() ? (a, b) : (b, a);
          cards.add(GuestCard.duel(pair.$1.id, pair.$2.id, ownerPick: a.mu > b.mu ? a.id : b.id));
          continue outer;
        }
      }
    }
    // Vibe checks: clearly liked or clearly not.
    final clear = shuffled.where((s) => !used.contains(s.id) && (s.rating.score - feelingThreshold).abs() >= 100).toList();
    for (final s in clear.take(vibes)) {
      cards.add(GuestCard.vibe(s.id, ownerFeelsIt: s.rating.score >= feelingThreshold));
    }
    cards.shuffle(r);
    return cards;
  }

  static GuestAnswer scoreDuel(GuestCard card, int picked) =>
      GuestAnswer(card: card, pickedId: picked, feltIt: null, agreed: picked == card.ownerPick);

  static GuestAnswer scoreVibe(GuestCard card, bool feltIt) =>
      GuestAnswer(card: card, pickedId: null, feltIt: feltIt, agreed: feltIt == card.ownerFeelsIt);

  static String verdict(GuestResult r) {
    final p = r.pct;
    return switch (r.mode) {
      GuestMode.taste => p >= 85 ? 'Same eye.' : p >= 65 ? 'Mostly aligned.' : p >= 45 ? 'Healthy disagreement.' : 'Opposites.',
      GuestMode.guess => p >= 85 ? 'You know them scarily well.' : p >= 65 ? 'You know them well.' : p >= 45 ? 'Getting there.' : 'Time to look at more of their photos.',
    };
  }
}
