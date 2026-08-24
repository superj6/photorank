import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/dealer/dealer.dart';
import '../../core/rating/glicko.dart';
import '../../core/rating/observation.dart';
import '../../data/db/database.dart';

enum SessionStatus { idle, loading, playing, finished, empty }

class SessionSummary {
  const SessionSummary({
    required this.cards,
    required this.answered,
    required this.newTopTen,
    required this.risers,
    required this.sortedFraction,
    required this.libraryCount,
  });

  final int cards;
  final int answered;
  final List<int> newTopTen;

  /// (photoId, score gain) best first.
  final List<(int, double)> risers;
  final double sortedFraction;
  final int libraryCount;
}

class SessionState {
  const SessionState({
    this.status = SessionStatus.idle,
    this.hand = const [],
    this.index = 0,
    this.answered = const [],
    this.photos = const {},
    this.topTier = const {},
    this.sessionId,
    this.summary,
    this.busy = false,
  });

  final SessionStatus status;
  final List<Card> hand;
  final int index;

  /// Per card: true if applied, false if passed; length == index.
  final List<bool> answered;
  final Map<int, PhotoRow> photos;
  final Set<int> topTier;
  final int? sessionId;
  final SessionSummary? summary;
  final bool busy;

  Card? get current => index < hand.length ? hand[index] : null;
  bool get canUndo => index > 0 && !busy;
  double get progress => hand.isEmpty ? 0 : index / hand.length;
  String? mediaOf(int id) => photos[id]?.mediaId;

  SessionState copyWith({
    SessionStatus? status,
    List<Card>? hand,
    int? index,
    List<bool>? answered,
    Map<int, PhotoRow>? photos,
    Set<int>? topTier,
    int? sessionId,
    SessionSummary? summary,
    bool? busy,
  }) =>
      SessionState(
        status: status ?? this.status,
        hand: hand ?? this.hand,
        index: index ?? this.index,
        answered: answered ?? this.answered,
        photos: photos ?? this.photos,
        topTier: topTier ?? this.topTier,
        sessionId: sessionId ?? this.sessionId,
        summary: summary ?? this.summary,
        busy: busy ?? this.busy,
      );
}

/// Runs one hand: deal → answer/pass/undo → summary.
class SessionController extends Notifier<SessionState> {
  final _dealer = Dealer();
  late int _axis;
  Map<int, Rating> _before = {};
  Set<int> _topBefore = {};

  @override
  SessionState build() => const SessionState();

  Future<void> start() async {
    state = const SessionState(status: SessionStatus.loading);
    _axis = await ref.read(axisIdProvider.future);
    final ranking = ref.read(rankingRepoProvider);
    final photosRepo = ref.read(photoRepoProvider);
    final config = ref.read(dealerSettingsProvider);
    final states = await ranking.photoStates(_axis);
    if (states.length < 2) {
      state = const SessionState(status: SessionStatus.empty);
      return;
    }
    final bursts = await ranking.eligibleBursts(_axis);
    final now = DateTime.now();
    final hand = _dealer.dealHand(states, config: config, bursts: bursts, now: now);
    if (hand.isEmpty) {
      state = const SessionState(status: SessionStatus.empty);
      return;
    }
    final ids = {for (final c in hand) ...c.photoIds};
    final rows = await photosRepo.byIds(ids);
    final byMu = [...states]..sort((a, b) => b.mu.compareTo(a.mu));
    _topBefore = byMu.take(10).map((p) => p.id).toSet();
    _before = {for (final s in states) s.id: s.rating};
    final db = ref.read(dbProvider);
    final sessionId = await db.into(db.sessions).insert(SessionsCompanion.insert(
          startedAt: now,
          cards: Value(hand.length),
          mixJson: Value(config.modeWeights.entries.map((e) => '${e.key.name}:${e.value}').join(',')),
        ));
    state = SessionState(
      status: SessionStatus.playing,
      hand: hand,
      photos: {for (final r in rows) r.id: r},
      topTier: byMu.take(config.topTierSize).map((p) => p.id).toSet(),
      sessionId: sessionId,
    );
  }

  String _cardId(int index) => '${state.sessionId}-$index';

  Future<void> _apply(List<Observation> obs) async {
    if (state.busy || state.current == null) return;
    state = state.copyWith(busy: true);
    HapticFeedback.lightImpact();
    final card = state.current!;
    await ref.read(rankingRepoProvider).applyCard(obs, sessionId: state.sessionId);
    if (card.mode == GameMode.bestOfBurst && card.clusterId != null) {
      await ref.read(photoRepoProvider).resolveCluster(card.clusterId!);
    }
    _advance(true);
  }

  Future<void> pass() async {
    if (state.busy || state.current == null) return;
    state = state.copyWith(busy: true);
    await ref.read(photoRepoProvider).markShown(state.current!.photoIds);
    _advance(false);
  }

  void _advance(bool answered) {
    final next = state.index + 1;
    state = state.copyWith(index: next, answered: [...state.answered, answered], busy: false);
    if (next >= state.hand.length) _finish();
  }

  Future<void> undo() async {
    if (!state.canUndo) return;
    state = state.copyWith(busy: true);
    final prev = state.index - 1;
    if (state.answered[prev]) {
      await ref.read(rankingRepoProvider).undoCard(_cardId(prev));
      final card = state.hand[prev];
      if (card.mode == GameMode.bestOfBurst && card.clusterId != null) {
        await _unresolve(card.clusterId!);
      }
    }
    HapticFeedback.selectionClick();
    state = state.copyWith(
      index: prev,
      answered: state.answered.sublist(0, prev),
      busy: false,
      status: SessionStatus.playing,
    );
  }

  Future<void> _unresolve(int clusterId) async {
    final db = ref.read(dbProvider);
    await (db.update(db.clusters)..where((c) => c.id.equals(clusterId)))
        .write(const ClustersCompanion(resolved: Value(false)));
  }

  Future<void> _finish() async {
    final ranking = ref.read(rankingRepoProvider);
    final db = ref.read(dbProvider);
    final states = await ranking.photoStates(_axis);
    final byMu = [...states]..sort((a, b) => b.mu.compareTo(a.mu));
    final topNow = byMu.take(10).map((p) => p.id).toList();
    final touched = {
      for (var i = 0; i < state.hand.length; i++)
        if (state.answered[i]) ...state.hand[i].photoIds,
    };
    final risers = [
      for (final s in states)
        if (touched.contains(s.id))
          (s.id, s.rating.score - (_before[s.id] ?? Rating.initial).score),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    if (state.sessionId != null) {
      await (db.update(db.sessions)..where((s) => s.id.equals(state.sessionId!)))
          .write(SessionsCompanion(endedAt: Value(DateTime.now())));
    }
    final settled = states.where((s) => s.rating.confidence >= 0.5).length;
    HapticFeedback.mediumImpact();
    state = state.copyWith(
      status: SessionStatus.finished,
      summary: SessionSummary(
        cards: state.hand.length,
        answered: state.answered.where((a) => a).length,
        newTopTen: topNow.where((id) => !_topBefore.contains(id)).toList(),
        risers: risers.where((r) => r.$2 > 0).take(3).toList(),
        sortedFraction: states.isEmpty ? 0 : settled / states.length,
        libraryCount: states.length,
      ),
    );
    ref.invalidate(libraryCountProvider);
  }

  // ---- per-mode answers ---------------------------------------------------

  Future<void> answerDuel(int winnerId) {
    final c = state.current!;
    final loser = c.photoIds.firstWhere((id) => id != winnerId);
    return _apply(Decompose.duel(
      axisId: _axis,
      cardId: _cardId(state.index),
      winnerId: winnerId,
      loserId: loser,
      mode: c.mode,
      now: DateTime.now(),
    ));
  }

  Future<void> answerVibe(bool feelingIt) => _apply(Decompose.vibe(
        axisId: _axis,
        cardId: _cardId(state.index),
        photoId: state.current!.photoIds.single,
        feelingIt: feelingIt,
        now: DateTime.now(),
      ));

  Future<void> answerRate(int stars) => _apply(Decompose.rate(
        axisId: _axis,
        cardId: _cardId(state.index),
        photoId: state.current!.photoIds.single,
        stars: stars,
        now: DateTime.now(),
      ));

  Future<void> answerBurst(int winnerId) => _apply(Decompose.burst(
        axisId: _axis,
        cardId: _cardId(state.index),
        winnerId: winnerId,
        siblingIds: state.current!.photoIds,
        now: DateTime.now(),
      ));

  Future<void> answerSort(List<int> orderedIds) => _apply(Decompose.sort(
        axisId: _axis,
        cardId: _cardId(state.index),
        orderedIds: orderedIds,
        now: DateTime.now(),
      ));
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);
