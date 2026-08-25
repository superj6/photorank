import 'dart:math';

import '../dealer/photo_state.dart';
import '../rating/glicko.dart';
import '../rating/observation.dart';
import 'beat.dart';
import 'beat_scheduler.dart';
import 'unlocks.dart';

/// A pair's head-to-head record (mirrors the repo type, kept pure here).
class PairInfo {
  const PairInfo({required this.a, required this.b, required this.aWins, required this.bWins});
  final int a;
  final int b;
  final int aWins;
  final int bWins;
  int get duels => aWins + bWins;
  bool get contested => duels >= 2 && (aWins - bWins).abs() <= 1;
}

class MoverInfo {
  const MoverInfo({required this.photoId, required this.before, required this.after});
  final int photoId;
  final Rating before;
  final Rating after;
  double get delta => after.score - before.score;
}

/// Everything the engine may look at. Nulls/empties mean "not available".
class BeatInput {
  const BeatInput({
    required this.decisions,
    required this.states,
    required this.now,
    this.moversThisHand = const [],
    this.pairs = const [],
    this.thenRatings = const {},
    this.firstSessionAt,
    this.sessionCount = 0,
    this.minutesPlayed = 0,
    this.streak = 0,
    this.recentKinds = const [],
    this.minorBeatsSoFar = 0,
    this.shownPairs = const {},
    this.themedAllowed = false,
    this.changes = const StateChanges(),
    this.lateGame = false,
    this.firstBeat = false,
  });

  final int decisions;
  final List<PhotoState> states;
  final DateTime now;
  final List<MoverInfo> moversThisHand;
  final List<PairInfo> pairs;

  /// Ratings as of the first session (for Then vs now).
  final Map<int, Rating> thenRatings;
  final DateTime? firstSessionAt;
  final int sessionCount;
  final int minutesPlayed;
  final int streak;
  final List<BeatKind> recentKinds;
  final int minorBeatsSoFar;

  /// Pairs already featured in Head-to-head beats, as "lo-hi" strings.
  final Set<String> shownPairs;
  final bool themedAllowed;
  final StateChanges changes;
  final bool lateGame;

  /// No beat has ever fired: the first one is always "Your first Top 3".
  final bool firstBeat;

  List<PhotoState> get rated => states.where((s) => s.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu));
  int get settledCount => states.where((s) => s.rating.confidence >= 0.5).length;
}

/// Turns a due slot into concrete pages, applying interestingness gates.
class BeatEngine {
  BeatEngine({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  static const double moverMinDelta = 8;
  static const double thenVsNowMinDelta = 5;
  static const int deepCutDays = 14;

  Beat? build(BeatDue due, BeatInput input) {
    if (due.tier == BeatTier.major) return _major(due.kind!, input);
    return _minor(input);
  }

  /// Build a specific kind regardless of schedule (debug previews, welcome back).
  Beat? forceKind(BeatKind kind, BeatInput i) => switch (kind) {
        BeatKind.standings => _standings(i),
        BeatKind.mover => _mover(i),
        BeatKind.headToHead => _headToHead(i),
        BeatKind.deepCut => _deepCut(i),
        BeatKind.thenVsNow => _thenVsNow(i),
        BeatKind.themedHand => _themed(i),
        BeatKind.welcomeBack => null,
        _ => _major(kind, i),
      };

  Beat? _major(BeatKind kind, BeatInput i) {
    final c = i.changes;
    switch (kind) {
      case BeatKind.modeUnlocked:
        final mode = c.unlocked.first;
        return Beat(
          kind: kind,
          tier: BeatTier.major,
          decisionCount: i.decisions,
          pages: [ModeUnlockedPage(mode)],
          cta: TryModeCta(mode),
        );
      case BeatKind.newTop:
        if (c.newTopId == null) return null;
        return Beat(
          kind: kind,
          tier: BeatTier.major,
          decisionCount: i.decisions,
          pages: [NewTopPage(photoId: c.newTopId!, previousId: c.previousTopId)],
          shareable: true,
        );
      case BeatKind.milestone:
        return Beat(
          kind: kind,
          tier: BeatTier.major,
          decisionCount: i.decisions,
          pages: [
            MilestonePage(
              decisions: BeatScheduler.milestones.lastWhere((m) => m <= i.decisions, orElse: () => i.decisions),
              minutes: i.minutesPlayed,
              streak: i.streak,
            ),
            ..._standingsIfAny(i),
          ],
          shareable: true,
        );
      case BeatKind.topTenOfficial:
        final top = i.rated.take(10).map((s) => s.id).toList();
        if (top.length < 10) return null;
        return Beat(kind: kind, tier: BeatTier.major, decisionCount: i.decisions, pages: [TopTenPage(ids: top)], shareable: true);
      case BeatKind.settledPct:
        if (c.settledCrossed == null) return null;
        return Beat(
          kind: kind,
          tier: BeatTier.major,
          decisionCount: i.decisions,
          pages: [SettledPage(settled: i.settledCount, total: i.states.length, crossed: c.settledCrossed!)],
          shareable: c.settledCrossed == 100,
        );
      case BeatKind.burstCleared:
        if (c.burstWinner == null) return null;
        return Beat(
          kind: kind,
          tier: BeatTier.major,
          decisionCount: i.decisions,
          pages: [BurstClearedPage(winnerId: c.burstWinner!, siblingIds: c.burstSiblings.where((s) => s != c.burstWinner).toList())],
        );
      default:
        return null;
    }
  }

  List<BeatPage> _standingsIfAny(BeatInput i) {
    final top = i.rated.take(3).map((s) => s.id).toList();
    return top.length >= 3 ? [StandingsPage(top: top, settled: i.settledCount, total: i.states.length)] : const [];
  }

  Beat? _minor(BeatInput i) {
    if (i.firstBeat) return _standings(i);
    final recent = i.recentKinds.take(4).toSet();
    final candidates = <(BeatKind, Beat? Function())>[
      if (i.themedAllowed && i.minorBeatsSoFar % 4 == 3) (BeatKind.themedHand, () => _themed(i)),
      (BeatKind.mover, () => _mover(i)),
      (BeatKind.headToHead, () => _headToHead(i)),
      (BeatKind.deepCut, () => _deepCut(i)),
      (BeatKind.thenVsNow, () => _thenVsNow(i)),
      (BeatKind.standings, () => _standings(i)),
    ];
    // Prefer kinds not shown recently; fall back to any that has content.
    for (final pass in [true, false]) {
      for (final (kind, make) in candidates) {
        if (pass && recent.contains(kind)) continue;
        final beat = make();
        if (beat != null) return beat;
      }
    }
    return null;
  }

  Beat? _standings(BeatInput i) {
    final pages = _standingsIfAny(i);
    if (pages.isEmpty) return null;
    return Beat(kind: BeatKind.standings, tier: BeatTier.minor, decisionCount: i.decisions, pages: pages);
  }

  Beat? _mover(BeatInput i) {
    final movers = i.moversThisHand.where((m) => m.delta >= moverMinDelta).toList()..sort((a, b) => b.delta.compareTo(a.delta));
    if (movers.isEmpty) return null;
    final m = movers.first;
    return Beat(
      kind: BeatKind.mover,
      tier: BeatTier.minor,
      decisionCount: i.decisions,
      pages: [
        MoverPage(
          photoId: m.photoId,
          scoreBefore: m.before.score,
          scoreAfter: m.after.score,
          rankBefore: _rankWith(i, m.photoId, m.before),
          rankAfter: _rank(i, m.photoId),
        ),
      ],
    );
  }

  Beat? _headToHead(BeatInput i) {
    final candidates = i.pairs.where((p) => p.contested && !i.shownPairs.contains('${p.a}-${p.b}')).toList();
    if (candidates.isEmpty) return null;
    final p = candidates.first;
    return Beat(
      kind: BeatKind.headToHead,
      tier: BeatTier.minor,
      decisionCount: i.decisions,
      pages: [HeadToHeadPage(a: p.a, b: p.b, aWins: p.aWins, bWins: p.bWins)],
      cta: SettleDuelCta(p.a, p.b),
    );
  }

  Beat? _deepCut(BeatInput i) {
    final rated = i.rated;
    if (rated.length < 10) return null;
    final cutoff = max(3, rated.length ~/ 5);
    final pool = rated.take(cutoff).where((s) {
      if (s.rating.confidence < 0.5 || s.lastShownAt == null) return false;
      return i.now.difference(s.lastShownAt!).inDays >= deepCutDays;
    }).toList();
    if (pool.isEmpty) return null;
    final pick = pool[_rng.nextInt(pool.length)];
    return Beat(
      kind: BeatKind.deepCut,
      tier: BeatTier.minor,
      decisionCount: i.decisions,
      pages: [DeepCutPage(photoId: pick.id, rank: _rank(i, pick.id)!, daysUnseen: i.now.difference(pick.lastShownAt!).inDays)],
      cta: VibeCheckCta(pick.id),
    );
  }

  Beat? _thenVsNow(BeatInput i) {
    if (i.sessionCount < 3 || i.decisions < 25 || i.firstSessionAt == null || i.thenRatings.isEmpty) return null;
    PhotoState? best;
    var bestDelta = 0.0;
    for (final s in i.rated) {
      final then = i.thenRatings[s.id];
      if (then == null) continue;
      final d = (s.rating.score - then.score).abs();
      if (d > bestDelta) {
        bestDelta = d;
        best = s;
      }
    }
    if (best == null || bestDelta < thenVsNowMinDelta) return null;
    return Beat(
      kind: BeatKind.thenVsNow,
      tier: BeatTier.minor,
      decisionCount: i.decisions,
      pages: [
        ThenVsNowPage(
          photoId: best.id,
          scoreThen: i.thenRatings[best.id]!.score,
          scoreNow: best.rating.score,
          decisionsBetween: i.decisions,
          daysBetween: i.now.difference(i.firstSessionAt!).inDays,
        ),
      ],
    );
  }

  Beat? _themed(BeatInput i) {
    final themes = [
      if (i.states.where((s) => s.clusterId != null || s.takenAt != null).length >= 10) DeckTheme.oneTrip,
      if (i.states.where((s) => s.takenAt != null).length >= 10) DeckTheme.sameMonth,
      DeckTheme.landscapes,
      if (i.rated.length >= 10) DeckTheme.rerankTop,
    ];
    if (themes.isEmpty) return null;
    final theme = themes[_rng.nextInt(themes.length)];
    return Beat(
      kind: BeatKind.themedHand,
      tier: BeatTier.minor,
      decisionCount: i.decisions,
      pages: [ThemedHandPage(theme, count: 10)],
      cta: ThemedDeckCta(theme),
    );
  }

  int? _rank(BeatInput i, int id) {
    final idx = i.rated.indexWhere((s) => s.id == id);
    return idx < 0 ? null : idx + 1;
  }

  /// Rank the photo would have had with [r] among today's rated photos.
  int? _rankWith(BeatInput i, int id, Rating r) {
    var above = 0;
    for (final s in i.rated) {
      if (s.id != id && s.mu > r.mu) above++;
    }
    return above + 1;
  }
}

/// Once the library is mostly settled, shift the game toward what's new.
class LibraryStats {
  const LibraryStats({required this.settledFraction, required this.observations});
  final double settledFraction;
  final int observations;
  bool get lateGame => settledFraction >= 0.8 && observations >= 500;
}

/// Reminder of which modes are open for a given decision count.
Set<GameMode> openModes(int decisions, {bool unlockAll = false}) => Unlocks.unlocked(decisions, all: unlockAll);
