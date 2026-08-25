import 'dart:math';

import '../rating/observation.dart';
import 'beat.dart';

/// Things that changed because of the last decision(s); majors key off these.
class StateChanges {
  const StateChanges({
    this.newTopId,
    this.previousTopId,
    this.topTenNewlySettled = false,
    this.settledCrossed,
    this.unlocked = const [],
    this.burstWinner,
    this.burstSiblings = const [],
  });

  final int? newTopId;
  final int? previousTopId;
  final bool topTenNewlySettled;

  /// 25 / 50 / 75 / 100 when the library just crossed that % settled.
  final int? settledCrossed;
  final List<GameMode> unlocked;
  final int? burstWinner;
  final List<int> burstSiblings;
}

/// Persisted scheduler state (prefs).
class SchedulerState {
  const SchedulerState({required this.nextMinorAt, required this.lastBeatAt, this.everFired = false});
  final int nextMinorAt;
  final int lastBeatAt;
  final bool everFired;

  SchedulerState copyWith({int? nextMinorAt, int? lastBeatAt, bool? everFired}) => SchedulerState(
        nextMinorAt: nextMinorAt ?? this.nextMinorAt,
        lastBeatAt: lastBeatAt ?? this.lastBeatAt,
        everFired: everFired ?? this.everFired,
      );
}

/// What is due right now: a specific major kind, or a minor slot the engine
/// fills with whatever is interesting.
class BeatDue {
  const BeatDue.major(this.kind) : tier = BeatTier.major;
  const BeatDue.minor()
      : tier = BeatTier.minor,
        kind = null;
  final BeatTier tier;
  final BeatKind? kind;
}

/// Variable-ratio schedule: a minor beat every 20–35 decisions, majors on
/// milestones and state changes, at most one beat per [minGap] decisions.
class BeatScheduler {
  BeatScheduler({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  static const int firstAt = 12;
  static const int minGap = 10;
  static const int minorMin = 20;
  static const int minorMax = 35;
  static const List<int> milestones = [50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000];

  int nextMinorAfter(int decisions) => decisions + minorMin + _rng.nextInt(minorMax - minorMin + 1);

  SchedulerState initial() => SchedulerState(nextMinorAt: nextMinorAfter(firstAt), lastBeatAt: 0);

  /// [previous] is the decision count before this card, [decisions] after it.
  BeatDue? due({
    required int previous,
    required int decisions,
    required SchedulerState state,
    required StateChanges changes,
  }) {
    if (decisions < firstAt) return null;
    final gapOk = decisions - state.lastBeatAt >= minGap || !state.everFired;

    // Majors, in priority order. Unlocks and a new #1 are worth breaking the gap for.
    if (changes.unlocked.isNotEmpty) return const BeatDue.major(BeatKind.modeUnlocked);
    if (changes.newTopId != null && state.everFired) return const BeatDue.major(BeatKind.newTop);
    if (!gapOk) return null;
    if (milestones.any((m) => m > previous && m <= decisions)) return const BeatDue.major(BeatKind.milestone);
    if (changes.topTenNewlySettled) return const BeatDue.major(BeatKind.topTenOfficial);
    if (changes.settledCrossed != null) return const BeatDue.major(BeatKind.settledPct);
    if (changes.burstWinner != null && _rng.nextDouble() < 0.5) return const BeatDue.major(BeatKind.burstCleared);

    // First ever beat: the guaranteed "your first Top 3".
    if (!state.everFired) return const BeatDue.minor();
    if (decisions >= state.nextMinorAt) return const BeatDue.minor();
    return null;
  }

  /// State after a beat fired at [decisions].
  SchedulerState fired(SchedulerState state, int decisions, BeatTier tier) => state.copyWith(
        lastBeatAt: decisions,
        everFired: true,
        nextMinorAt: tier == BeatTier.minor || decisions >= state.nextMinorAt ? nextMinorAfter(decisions) : state.nextMinorAt,
      );
}
