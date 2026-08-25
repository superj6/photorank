import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show BoxFit;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/beats/beat.dart';
import '../../core/beats/beat_engine.dart';
import '../../core/beats/beat_scheduler.dart';
import '../../core/beats/late_game.dart';
import '../../core/beats/recap.dart';
import '../../core/beats/unlocks.dart';
import '../../core/dealer/dealer.dart';
import '../../core/rating/engine.dart';
import '../../core/rating/glicko.dart';
import '../../core/rating/observation.dart';
import '../../core/stats/progress.dart';
import '../../data/db/database.dart';
import '../../data/repo/beat_repo.dart';
import '../widget/duel_widget.dart';

enum SessionStatus { idle, loading, playing, finished, empty }

class SessionSummary {
  const SessionSummary({
    required this.cards,
    required this.answered,
    required this.newTopTen,
    required this.risers,
    required this.sortedFraction,
    required this.libraryCount,
    required this.streak,
    required this.level,
    this.newBadges = const [],
  });

  final int cards;
  final int answered;
  final List<int> newTopTen;

  /// (photoId, score gain) best first.
  final List<(int, double)> risers;
  final double sortedFraction;
  final int libraryCount;
  final int streak;
  final Level level;
  final List<Badge> newBadges;
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
    this.beat,
    this.decisions = 0,
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

  /// A moment waiting to be shown before the next card.
  final Beat? beat;
  final int decisions;

  Card? get current => index < hand.length ? hand[index] : null;
  bool get canUndo => index > 0 && !busy && beat == null;
  double get progress => hand.isEmpty ? 0 : index / hand.length;
  String? mediaOf(int id) => photos[id]?.mediaId;

  /// Landscape shots are letterboxed instead of cropped into a tall card.
  BoxFit fitOf(int id) {
    final p = photos[id];
    return p != null && p.width > p.height ? BoxFit.contain : BoxFit.cover;
  }

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
    Beat? beat,
    bool clearBeat = false,
    int? decisions,
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
        beat: clearBeat ? null : (beat ?? this.beat),
        decisions: decisions ?? this.decisions,
      );
}

/// Runs one hand: deal → answer/pass/undo → summary, with beats in between.
class SessionController extends Notifier<SessionState> {
  final _dealer = Dealer();
  final _scheduler = BeatScheduler();
  final _engine = BeatEngine();
  late int _axis;
  Map<int, Rating> _before = {};
  Set<int> _topBefore = {};

  // Beat bookkeeping (kept incrementally so a card never needs a full reload).
  int _decisions = 0;
  bool _unlockAll = false;
  SchedulerState _sched = const SchedulerState(nextMinorAt: 0, lastBeatAt: 0);
  DateTime _handStartAt = DateTime.now();
  int? _topId;
  double _topMu = double.negativeInfinity;
  int _settled = 0;
  int _total = 0;
  bool _topTenSettled = false;
  List<List<PhotoState>> _bursts = const [];
  ProgressFacts? _factsAtStart;

  static const _prefSched = 'beat_sched';

  @override
  SessionState build() {
    ref.watch(axisIdProvider); // a new axis deals a new hand
    return const SessionState();
  }

  BeatRepo get _beats => ref.read(beatRepoProvider);

  Future<void> start() async {
    state = const SessionState(status: SessionStatus.loading);
    _axis = await ref.read(axisIdProvider.future);
    final ranking = ref.read(rankingRepoProvider);
    final photosRepo = ref.read(photoRepoProvider);
    _unlockAll = (await photosRepo.pref(prefUnlockAll)) == '1';
    _decisions = await _beats.decisionCount();
    _sched = await _loadSched();

    var config = ref.read(dealerSettingsProvider);
    final unlocked = Unlocks.unlocked(_decisions, all: _unlockAll);
    config = config.copyWith(modeWeights: {
      for (final e in config.modeWeights.entries)
        if (unlocked.contains(e.key)) e.key: e.value,
    });

    final states = await ranking.photoStates(_axis);
    if (states.length < 2) {
      state = const SessionState(status: SessionStatus.empty);
      return;
    }
    _initTracking(states);
    final obsCount = await ranking.observationCount();
    config = LateGamePolicy.adjust(
        config, LibraryStats(settledFraction: _total == 0 ? 0 : _settled / _total, observations: obsCount));

    _bursts = await ranking.eligibleBursts(_axis);
    final now = DateTime.now();
    _handStartAt = now;
    final hand = _dealer.dealHand(states, config: config, bursts: _bursts, now: now);
    if (hand.isEmpty) {
      state = const SessionState(status: SessionStatus.empty);
      return;
    }
    final rows = await photosRepo.byIds({for (final c in hand) ...c.photoIds});
    final rated = states.where((s) => s.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu));
    _topBefore = rated.take(10).map((p) => p.id).toSet();
    _before = {for (final s in states) s.id: s.rating};

    final sessions = await _beats.sessions();
    _factsAtStart = await progressFacts(sessions: sessions, now: now);
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
      topTier: rated.take(config.topTierSize).map((p) => p.id).toSet(),
      sessionId: sessionId,
      decisions: _decisions,
    );
    await _welcomeBack(sessions, states, now);
    if (state.beat == null) await _calendarRecap(sessions, states, now);
  }

  Future<void> _calendarRecap(List<SessionRow> sessions, List<PhotoState> states, DateTime now) async {
    final due = RecapScheduler.due(
      now: now,
      sessionStarts: sessions.map((s) => s.startedAt),
      savedKeys: await _beats.savedRecapKeys(),
    );
    if (due == null) return;
    final beat = RecapEngine.build(await _beats.recapInput(_axis, due, states, now: now));
    if (beat != null) await _show(beat, schedule: false);
  }

  /// On-demand yearly recap ("Show my year"). Returns false if there is too
  /// little to show.
  Future<bool> showYear(int year) async {
    if (state.status == SessionStatus.idle || state.status == SessionStatus.loading) await start();
    final states = await ref.read(rankingRepoProvider).photoStates(_axis);
    final beat = RecapEngine.build(await _beats.recapInput(_axis, RecapScheduler.year(year), states));
    if (beat == null) return false;
    await _show(beat, schedule: false);
    return true;
  }

  /// Everything badges and levels are computed from.
  Future<ProgressFacts> progressFacts({List<SessionRow>? sessions, DateTime? now}) async {
    final all = sessions ?? await _beats.sessions();
    final ts = now ?? DateTime.now();
    return ProgressFacts(
      decisions: _decisions,
      sessions: all.where((s) => s.endedAt != null).length,
      streak: BeatRepo.streak(all.map((s) => s.startedAt), ts),
      burstsCleared: await _beats.cardCount([GameMode.bestOfBurst]),
      settledFraction: _total == 0 ? 0 : _settled / _total,
      topTenOfficial: await _beats.hasBeat(BeatKind.topTenOfficial),
      unlockedAll: Unlocks.unlocked(_decisions, all: _unlockAll).length == Unlocks.thresholds.length,
      duels: await _beats.cardCount([GameMode.duel, GameMode.challenger]),
      moments: 0,
      shares: await _beats.sharedCount(),
    );
  }

  void _initTracking(List<PhotoState> states) {
    final rated = states.where((s) => s.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu));
    _topId = rated.isEmpty ? null : rated.first.id;
    _topMu = rated.isEmpty ? double.negativeInfinity : rated.first.mu;
    _total = states.length;
    _settled = states.where((s) => s.rating.confidence >= 0.5).length;
    _topTenSettled = rated.length >= 10 && rated.take(10).every((s) => s.rating.confidence >= 0.75);
  }

  Future<SchedulerState> _loadSched() async {
    final raw = await ref.read(photoRepoProvider).pref(_prefSched);
    if (raw == null) return _scheduler.initial();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return SchedulerState(
      nextMinorAt: j['next'] as int,
      lastBeatAt: j['last'] as int,
      everFired: j['fired'] as bool? ?? false,
    );
  }

  Future<void> _saveSched() => ref.read(photoRepoProvider).setPref(
      _prefSched, jsonEncode({'next': _sched.nextMinorAt, 'last': _sched.lastBeatAt, 'fired': _sched.everFired}));

  String _cardId(int index) => '${state.sessionId}-$index';

  Future<void> _apply(List<Observation> obs) async {
    if (state.busy || state.current == null || state.beat != null) return;
    state = state.copyWith(busy: true);
    HapticFeedback.lightImpact();
    final card = state.current!;
    final delta = await ref.read(rankingRepoProvider).applyCard(obs, sessionId: state.sessionId);
    if (card.mode == GameMode.bestOfBurst && card.clusterId != null) {
      await ref.read(photoRepoProvider).resolveCluster(card.clusterId!);
    }
    final previous = _decisions;
    _decisions++;
    final changes = _track(delta, card);
    _advance(true);
    await _maybeBeat(previous, changes);
  }

  /// Update incremental stats from one card's rating delta; report changes.
  StateChanges _track(RatingDelta delta, Card card) {
    int? newTop;
    int? previousTop;
    final settledBefore = _settled;
    for (final e in delta.after.entries) {
      final before = delta.before[e.key]!;
      final wasSettled = before.confidence >= 0.5;
      final isSettled = e.value.confidence >= 0.5;
      if (!wasSettled && isSettled) _settled++;
      if (wasSettled && !isSettled) _settled--;
      if (e.value.mu > _topMu) {
        if (_topId != null && _topId != e.key) {
          newTop = e.key;
          previousTop = _topId;
        }
        _topId = e.key;
        _topMu = e.value.mu;
      }
    }
    int? crossed;
    if (_total > 0) {
      final pb = settledBefore * 100 ~/ _total;
      final pa = _settled * 100 ~/ _total;
      for (final t in const [25, 50, 75, 100]) {
        if (pb < t && pa >= t) crossed = t;
      }
    }
    return StateChanges(
      newTopId: newTop,
      previousTopId: previousTop,
      settledCrossed: crossed,
      unlocked: _unlockAll ? const [] : Unlocks.newlyUnlocked(_decisions - 1, _decisions),
      burstWinner: card.mode == GameMode.bestOfBurst ? card.photoIds.first : null,
      burstSiblings: card.mode == GameMode.bestOfBurst ? card.photoIds : const [],
    );
  }

  Future<void> _maybeBeat(int previous, StateChanges changes) async {
    // Top-10-settled is a full-state check; only do it when something else is due.
    var due = _scheduler.due(previous: previous, decisions: _decisions, state: _sched, changes: changes);
    if (due == null) return;
    final input = await _buildInput(changes);
    if (!_topTenSettled) {
      final top = input.rated.take(10).toList();
      if (top.length >= 10 && top.every((s) => s.rating.confidence >= 0.75)) {
        _topTenSettled = true;
        if (due.tier == BeatTier.minor) due = const BeatDue.major(BeatKind.topTenOfficial);
      }
    }
    await _fire(due, input);
  }

  Future<void> _fire(BeatDue due, BeatInput input, {bool schedule = true}) async {
    final beat = _engine.build(due, input);
    if (beat == null) {
      if (schedule && due.tier == BeatTier.minor) {
        _sched = _sched.copyWith(nextMinorAt: _scheduler.nextMinorAfter(_decisions));
        await _saveSched();
      }
      return;
    }
    await _show(beat, schedule: schedule);
  }

  Future<void> _show(Beat beat, {bool schedule = true}) async {
    final id = await _beats.saveBeat(kind: beat.kind.name, decisionCount: _decisions, payload: beat.toJson());
    if (schedule) {
      _sched = _scheduler.fired(_sched, _decisions, beat.tier);
      await _saveSched();
    }
    HapticFeedback.mediumImpact();
    state = state.copyWith(beat: beat.withId(id), decisions: _decisions);
  }

  Future<BeatInput> _buildInput(StateChanges changes) async {
    final ranking = ref.read(rankingRepoProvider);
    final states = await ranking.photoStates(_axis);
    final movers = await _beats.moversSince(_axis, _handStartAt);
    final pairs = await _beats.pairRecords(_axis);
    final sessions = await _beats.sessions();
    final recent = await _beats.listBeats(limit: 40);
    final now = DateTime.now();
    final firstAt = sessions.isEmpty ? null : sessions.first.startedAt;
    final then = sessions.length >= 3 && firstAt != null ? await _beats.ratingsAsOf(_axis, firstAt) : <int, Rating>{};
    final shownPairs = <String>{};
    var minorCount = 0;
    for (final b in recent) {
      final j = jsonDecode(b.payloadJson) as Map<String, dynamic>;
      if (j['tier'] == 'minor') minorCount++;
      if (b.kind == BeatKind.headToHead.name) {
        for (final p in (j['pages'] as List)) {
          if (p['type'] == 'headToHead') shownPairs.add('${p['a']}-${p['b']}');
        }
      }
    }
    return BeatInput(
      decisions: _decisions,
      states: states,
      now: now,
      moversThisHand: [for (final m in movers) MoverInfo(photoId: m.photoId, before: m.before, after: m.after)],
      pairs: [for (final p in pairs) PairInfo(a: p.a, b: p.b, aWins: p.aWins, bWins: p.bWins)],
      thenRatings: then,
      firstSessionAt: firstAt,
      sessionCount: sessions.length,
      minutesPlayed: BeatRepo.minutesPlayed(sessions).inMinutes,
      streak: BeatRepo.streak(sessions.map((s) => s.startedAt), now),
      recentKinds: [for (final b in recent.take(6)) BeatKind.values.byName(b.kind)],
      minorBeatsSoFar: minorCount,
      shownPairs: shownPairs,
      themedAllowed: Unlocks.themedHands(_decisions, all: _unlockAll),
      changes: changes,
      lateGame: _total > 0 && _settled / _total >= 0.8,
      firstBeat: !_sched.everFired,
    );
  }

  Future<void> _welcomeBack(List<SessionRow> previous, List<PhotoState> states, DateTime now) async {
    if (previous.isEmpty) return;
    final last = previous.last.startedAt;
    final away = now.difference(last).inDays;
    if (away < 7) return;
    final newPhotos = states.where((s) => s.addedAt != null && s.addedAt!.isAfter(last)).length;
    final snaps = await _beats.snapshots(limit: 1);
    final rated = states.where((s) => s.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu));
    final topNow = rated.isEmpty ? null : rated.first.id;
    final topThen = snaps.isEmpty ? null : BeatRepo.top10Of(snaps.first).firstOrNull;
    final beat = Beat(
      kind: BeatKind.welcomeBack,
      tier: BeatTier.major,
      decisionCount: _decisions,
      pages: [WelcomeBackPage(daysAway: away, newPhotos: newPhotos, topHeld: topThen == null || topThen == topNow, topId: topNow)],
    );
    await _show(beat, schedule: false);
  }

  // ---- beat interaction ---------------------------------------------------

  Future<void> dismissBeat() async {
    final beat = state.beat;
    if (beat == null) return;
    if (beat.id != null) await _beats.markSeen(beat.id!);
    state = state.copyWith(clearBeat: true);
  }

  /// Take the beat's offered action (settle a duel, try a mode, deal a deck…).
  Future<void> acceptCta() async {
    final beat = state.beat;
    final cta = beat?.cta;
    await dismissBeat();
    if (cta == null) return;
    final ranking = ref.read(rankingRepoProvider);
    final now = DateTime.now();
    switch (cta) {
      case SettleDuelCta(:final a, :final b):
        await _insertCards([Card(mode: GameMode.duel, photoIds: [a, b])]);
      case VibeCheckCta(:final photoId):
        await _insertCards([Card(mode: GameMode.vibeCheck, photoIds: [photoId])]);
      case TryModeCta(:final mode):
        final states = await ranking.photoStates(_axis);
        final cards = _dealer.dealHand(states,
            config: DealerConfig(modeWeights: {mode: 1}, handSize: 1), bursts: _bursts, now: now);
        await _insertCards(cards);
      case ThemedDeckCta(:final theme):
        final states = await ranking.photoStates(_axis);
        final deck = _dealer.dealDeck(states,
            theme: theme, now: now, allowed: Unlocks.unlocked(_decisions, all: _unlockAll));
        if (deck.isEmpty) return;
        await _replaceRemaining(deck);
    }
  }

  Future<void> _insertCards(List<Card> cards) async {
    if (cards.isEmpty) return;
    final rows = await ref.read(photoRepoProvider).byIds({for (final c in cards) ...c.photoIds});
    final hand = [...state.hand.sublist(0, state.index), ...cards, ...state.hand.sublist(state.index)];
    state = state.copyWith(
      hand: hand,
      photos: {...state.photos, for (final r in rows) r.id: r},
      status: SessionStatus.playing,
    );
  }

  Future<void> _replaceRemaining(List<Card> cards) async {
    final rows = await ref.read(photoRepoProvider).byIds({for (final c in cards) ...c.photoIds});
    state = state.copyWith(
      hand: [...state.hand.sublist(0, state.index), ...cards],
      photos: {...state.photos, for (final r in rows) r.id: r},
      status: SessionStatus.playing,
    );
  }

  /// Debug builds: preview any beat kind against the current library.
  Future<void> debugFire(BeatKind kind) async {
    if (state.status == SessionStatus.idle) await start();
    final ranking = ref.read(rankingRepoProvider);
    final states = await ranking.photoStates(_axis);
    final rated = states.where((s) => s.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu));
    final changes = switch (kind) {
      BeatKind.modeUnlocked => const StateChanges(unlocked: [GameMode.rate]),
      BeatKind.newTop => StateChanges(newTopId: rated.firstOrNull?.id, previousTopId: rated.length > 1 ? rated[1].id : null),
      BeatKind.settledPct => const StateChanges(settledCrossed: 50),
      BeatKind.burstCleared => StateChanges(
          burstWinner: _bursts.firstOrNull?.first.id,
          burstSiblings: _bursts.firstOrNull?.map((s) => s.id).toList() ?? const []),
      _ => const StateChanges(),
    };
    final input = await _buildInput(changes);
    if (kind == BeatKind.welcomeBack) {
      await _show(
        Beat(kind: kind, tier: BeatTier.major, decisionCount: _decisions, pages: [
          WelcomeBackPage(daysAway: 9, newPhotos: 12, topHeld: true, topId: rated.firstOrNull?.id),
        ]),
        schedule: false,
      );
      return;
    }
    final beat = _engine.forceKind(kind, input);
    if (beat != null) await _show(beat, schedule: false);
  }

  // ---- card flow ------------------------------------------------------------

  Future<void> pass() async {
    if (state.busy || state.current == null || state.beat != null) return;
    state = state.copyWith(busy: true);
    await ref.read(photoRepoProvider).markShown(state.current!.photoIds);
    _advance(false);
  }

  void _advance(bool answered) {
    final next = state.index + 1;
    state = state.copyWith(index: next, answered: [...state.answered, answered], busy: false, decisions: _decisions);
    if (next >= state.hand.length) _finish();
  }

  Future<void> undo() async {
    if (!state.canUndo) return;
    state = state.copyWith(busy: true);
    final prev = state.index - 1;
    if (state.answered[prev]) {
      await ref.read(rankingRepoProvider).undoCard(_cardId(prev));
      _decisions--;
      final card = state.hand[prev];
      if (card.mode == GameMode.bestOfBurst && card.clusterId != null) {
        await _unresolve(card.clusterId!);
      }
      // Undo can move the top or settled counts; re-derive rather than guess.
      _initTracking(await ref.read(rankingRepoProvider).photoStates(_axis));
    }
    HapticFeedback.selectionClick();
    state = state.copyWith(
      index: prev,
      answered: state.answered.sublist(0, prev),
      busy: false,
      status: SessionStatus.playing,
      decisions: _decisions,
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
    final byMu = states.where((s) => s.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu));
    final topNow = byMu.take(10).map((p) => p.id).toList();
    final touched = {
      for (var i = 0; i < state.hand.length; i++)
        if (i < state.answered.length && state.answered[i]) ...state.hand[i].photoIds,
    };
    final risers = [
      for (final s in states)
        if (touched.contains(s.id)) (s.id, s.rating.score - (_before[s.id] ?? Rating.initial).score),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    if (state.sessionId != null) {
      await (db.update(db.sessions)..where((s) => s.id.equals(state.sessionId!)))
          .write(SessionsCompanion(endedAt: Value(DateTime.now())));
    }
    final settled = states.where((s) => s.rating.confidence >= 0.5).length;
    final facts = await progressFacts();
    final newBadges = _factsAtStart == null ? <Badge>[] : Badges.newlyEarned(_factsAtStart!, facts);
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
        streak: facts.streak,
        level: Level.fromXp(_decisions),
        newBadges: newBadges,
      ),
    );
    ref.invalidate(libraryCountProvider);
    ref.invalidate(decisionsProvider);
    DuelWidget.refresh(ranking: ranking, photos: ref.read(photoRepoProvider), axis: _axis);
  }

  /// Opened from the home-screen widget: put that duel first. If a side was
  /// tapped on the widget, count it immediately.
  Future<void> startWithDuel(int a, int b, {int? pick}) async {
    if (state.status != SessionStatus.playing) await start();
    if (state.status != SessionStatus.playing) return;
    await _insertCards([Card(mode: GameMode.duel, photoIds: [a, b])]);
    if (pick != null && (pick == a || pick == b)) await answerDuel(pick);
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
        mode: state.current!.mode,
        now: DateTime.now(),
      ));
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);
