import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/bracket/bracket.dart';
import '../../core/rating/observation.dart';
import '../../core/sampler/moments.dart';
import '../beats/beat_photo.dart';
import '../play/cards/duel_card.dart';
import '../share/share_preview_screen.dart';
import '../widgets/photo_tile.dart';

class BracketState {
  const BracketState({this.bracket, this.showOverview = false, this.loading = true, this.busy = false, this.tooFew = false});
  final Bracket? bracket;
  final bool showOverview;
  final bool loading;
  final bool busy;
  final bool tooFew;
  BracketState copyWith({Bracket? bracket, bool? showOverview, bool? loading, bool? busy, bool? tooFew}) => BracketState(
      bracket: bracket ?? this.bracket,
      showOverview: showOverview ?? this.showOverview,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      tooFew: tooFew ?? this.tooFew);
}

/// Top 16 single elimination. Every duel is a real observation, so the
/// bracket both entertains and sharpens the top of the ladder.
class BracketController extends Notifier<BracketState> {
  late int _axis;
  final _cardIds = <String>[];

  @override
  BracketState build() => const BracketState();

  Future<void> start() async {
    state = const BracketState(loading: true);
    _axis = await ref.read(axisIdProvider.future);
    final states = await ref.read(rankingRepoProvider).photoStates(_axis);
    final rated = states.where((s) => s.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu));
    final bracket = Bracket.seed(onePerMoment(rated, keys: momentKeys(states)).map((s) => s.id).toList());
    state = BracketState(bracket: bracket, loading: false, tooFew: bracket == null);
  }

  Future<void> decide(int winner) async {
    final b = state.bracket;
    if (b == null || state.busy) return;
    final m = b.nextMatch;
    if (m == null) return;
    state = state.copyWith(busy: true);
    HapticFeedback.lightImpact();
    final cardId = 'bracket-${DateTime.now().millisecondsSinceEpoch}';
    _cardIds.add(cardId);
    await ref.read(rankingRepoProvider).applyCard(Decompose.duel(
          axisId: _axis,
          cardId: cardId,
          winnerId: winner,
          loserId: winner == m.a ? m.b : m.a,
          now: DateTime.now(),
        ));
    final next = b.decide(winner);
    state = state.copyWith(bracket: next, busy: false, showOverview: next.roundDone);
    if (next.finished) {
      HapticFeedback.heavyImpact();
      ref.invalidate(decisionsProvider);
    }
  }

  void nextRound() {
    final b = state.bracket;
    if (b == null) return;
    state = state.copyWith(bracket: b.advance(), showOverview: false);
  }

  Future<void> undo() async {
    final b = state.bracket;
    if (b == null || _cardIds.isEmpty || state.busy) return;
    state = state.copyWith(busy: true);
    await ref.read(rankingRepoProvider).undoCard(_cardIds.removeLast());
    state = state.copyWith(bracket: b.undo(), busy: false, showOverview: false);
  }
}

final bracketProvider = NotifierProvider.autoDispose<BracketController, BracketState>(BracketController.new);

class BracketScreen extends ConsumerStatefulWidget {
  const BracketScreen({super.key});

  @override
  ConsumerState<BracketScreen> createState() => _BracketScreenState();
}

class _BracketScreenState extends ConsumerState<BracketScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(bracketProvider.notifier).start());
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(bracketProvider);
    final ctl = ref.read(bracketProvider.notifier);
    final rows = ref.watch(rankingProvider).value ?? const [];
    String? mediaOf(int id) => rows.where((p) => p.id == id).firstOrNull?.mediaId;
    final b = s.bracket;
    return Scaffold(
      appBar: AppBar(
        title: Text(b == null ? 'Bracket' : b.finished ? 'Champion' : b.roundName(b.currentRound)),
        actions: [
          if (b != null && !b.finished)
            IconButton(tooltip: 'Undo', onPressed: s.busy ? null : ctl.undo, icon: const Icon(Icons.undo_rounded)),
        ],
      ),
      body: SafeArea(
        child: s.loading
            ? const Center(child: CircularProgressIndicator())
            : s.tooFew
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Rank at least 8 photos to play a bracket.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
                    ),
                  )
                : b!.finished || s.showOverview
                    ? _Overview(bracket: b, mediaOf: mediaOf, onNext: ctl.nextRound)
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: b.matchesPlayed / b.matchesTotal,
                                minHeight: 4,
                                backgroundColor: Colors.white10,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: KeyedSubtree(
                                key: ValueKey('${b.currentRound}-${b.matchesPlayed}'),
                                child: DuelCard(
                                  topId: b.nextMatch!.a,
                                  bottomId: b.nextMatch!.b,
                                  mediaOf: mediaOf,
                                  onPick: ctl.decide,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.bracket, required this.mediaOf, required this.onNext});
  final Bracket bracket;
  final String? Function(int) mediaOf;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final b = bracket;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (b.finished) ...[
                  Text('Your champion', style: Theme.of(context).textTheme.headlineMedium).animate().fadeIn(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
                    child: BeatPhoto(b.champion!, child: const Align(alignment: Alignment.topLeft, child: Padding(padding: EdgeInsets.all(12), child: Pill('Champion', icon: Icons.emoji_events, color: AppTheme.accent)))),
                  ).animate().scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack, duration: 600.ms).then().shimmer(duration: 900.ms),
                  const SizedBox(height: 20),
                ],
                BracketCard(bracket: b, compact: true),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              if (b.finished) ...[
                IconButton.filledTonal(
                  tooltip: 'Share bracket',
                  onPressed: () => SharePreviewScreen.open(context, card: BracketCard(bracket: b), filename: 'photorank-bracket.png'),
                  icon: const Icon(Icons.ios_share_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done'))),
              ] else
                Expanded(child: FilledButton(onPressed: onNext, child: Text('On to the ${b.roundName(b.currentRound + 1).toLowerCase()}'))),
            ],
          ),
        ),
      ],
    );
  }
}

/// The bracket as columns of thumbnails; also the share image.
class BracketCard extends StatelessWidget {
  const BracketCard({super.key, required this.bracket, this.compact = false});
  final Bracket bracket;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final b = bracket;
    final size = compact ? 44.0 : 52.0;
    final columns = <Widget>[];
    for (var r = 0; r < b.roundCount; r++) {
      final matches = r < b.rounds.length ? b.rounds[r] : null;
      final count = b.seeds.length ~/ (1 << (r + 1));
      columns.add(Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(children: [
                _slot(matches != null && i < matches.length ? matches[i].a : null, matches?[i].winner, size),
                const SizedBox(height: 2),
                _slot(matches != null && i < matches.length ? matches[i].b : null, matches?[i].winner, size),
              ]),
            ),
        ],
      ));
    }
    columns.add(Column(mainAxisAlignment: MainAxisAlignment.center, children: [_slot(b.champion, b.champion, size * 1.5)]));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) const Text('My photo bracket', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          if (!compact) const SizedBox(height: 10),
          SizedBox(
            height: b.seeds.length == 16 ? size * 16 + 100 : size * 8 + 60,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: columns),
          ),
          if (!compact) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Ranked with PhotoRank', style: TextStyle(fontSize: 12, color: Colors.white54))),
        ],
      ),
    );
  }

  Widget _slot(int? id, int? winner, double size) {
    final won = id != null && winner == id;
    final lost = id != null && winner != null && winner != id;
    return SizedBox(
      width: size,
      height: size,
      child: id == null
          ? DecoratedBox(decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)))
          : Opacity(
              opacity: lost ? 0.35 : 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: won ? Border.all(color: AppTheme.accent, width: 2) : null,
                ),
                child: BeatPhoto(id, borderRadius: 8, size: ThumbCacheSizes.grid),
              ),
            ),
    );
  }
}
