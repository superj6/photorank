import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/rating/observation.dart';
import '../beats/beat_overlay.dart';
import '../widgets/photo_tile.dart';
import 'cards/burst_card.dart';
import 'cards/duel_card.dart';
import 'cards/rate_card.dart';
import 'cards/sort_card.dart';
import 'cards/vibe_card.dart';
import 'session_controller.dart';
import 'summary_view.dart';

/// Opens straight into a hand. No home screen.
class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(sessionProvider).status == SessionStatus.idle) {
        ref.read(sessionProvider.notifier).start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    final ctl = ref.read(sessionProvider.notifier);
    if (s.status == SessionStatus.idle) {
      // Also covers a scope change that invalidated the session.
      WidgetsBinding.instance.addPostFrameCallback((_) => ctl.start());
    }
    ref.listen(sessionProvider.select((s) => s.current), (prev, next) {
      if (next != null) _precache(next.photoIds, s);
    });
    if (s.beat != null) {
      return Scaffold(
        body: SafeArea(
          child: BeatOverlay(
            key: ValueKey('beat-${s.beat!.id}'),
            beat: s.beat!,
            onContinue: ctl.dismissBeat,
            onCta: s.beat!.cta == null ? null : ctl.acceptCta,
            onShared: () => ref.read(beatRepoProvider).markShared(s.beat!.id!),
            continueLabel: s.status == SessionStatus.finished ? 'See summary' : 'Continue',
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: switch (s.status) {
          SessionStatus.idle || SessionStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          SessionStatus.empty => _Empty(onRescan: () => context.go('/settings')),
          SessionStatus.finished => SummaryView(summary: s.summary!, onAgain: ctl.start),
          SessionStatus.playing => Column(
              children: [
                _Header(state: s, onUndo: ctl.undo, onPass: ctl.pass),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.97, end: 1.0).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey('${s.sessionId}-${s.index}'),
                        child: _card(s, ctl),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }

  void _precache(List<int> ids, SessionState s) {
    final next = s.index + 1 < s.hand.length ? s.hand[s.index + 1].photoIds : const <int>[];
    final media = [for (final id in [...ids, ...next]) s.mediaOf(id)].whereType<String>();
    ref.read(thumbCacheProvider).precache(context, media);
  }

  Widget _card(SessionState s, SessionController ctl) {
    final c = s.current!;
    // First two cards ever: teach the two gestures that are not obvious.
    final firstTime = s.decisions < 2 && s.index < 2;
    switch (c.mode) {
      case GameMode.duel:
      case GameMode.challenger:
        return DuelCard(
          topId: c.photoIds[0],
          bottomId: c.photoIds[1],
          mediaOf: s.mediaOf,
          fitOf: s.fitOf,
          challenger: c.mode == GameMode.challenger,
          onPick: ctl.answerDuel,
          hint: firstTime ? const Pill('Tap to pick · hold to look closer', icon: Icons.touch_app_rounded) : null,
        );
      case GameMode.vibeCheck:
        return VibeCard(
          mediaId: s.mediaOf(c.photoIds.single),
          fit: s.fitOf(c.photoIds.single),
          onAnswer: ctl.answerVibe,
          hint: firstTime ? const Pill('Swipe · tap to view full screen', icon: Icons.swipe_rounded) : null,
        );
      case GameMode.rate:
        return RateCard(
          mediaId: s.mediaOf(c.photoIds.single),
          fit: s.fitOf(c.photoIds.single),
          onRate: ctl.answerRate,
          hint: firstTime ? const Pill('Double-tap for 5★ · tap to view', icon: Icons.star_rounded) : null,
        );
      case GameMode.bestOfBurst:
        return BurstCard(ids: c.photoIds, mediaOf: s.mediaOf, onPick: ctl.answerBurst);
      case GameMode.sort3:
      case GameMode.rerankTop:
        return SortCard(ids: c.photoIds, mediaOf: s.mediaOf, fitOf: s.fitOf, onSorted: ctl.answerSort);
      case GameMode.browseHeart:
        return const SizedBox.shrink();
    }
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.state, required this.onUndo, required this.onPass});

  final SessionState state;
  final VoidCallback onUndo;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = state.current!.mode;
    final axis = ref.watch(currentAxisProvider).value;
    final axisLabel = axis == null || axis.isDefault ? '' : '${axis.name} · ';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Undo',
                onPressed: state.canUndo ? onUndo : null,
                icon: const Icon(Icons.undo_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$axisLabel${_label(mode)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
                  ).animate(key: ValueKey(state.index)).fadeIn(duration: 200.ms),
                ),
              ),
              TextButton(onPressed: state.busy ? null : onPass, child: const Text('Pass')),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: state.progress),
              duration: const Duration(milliseconds: 300),
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: Colors.white10,
                color: AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(GameMode m) => switch (m) {
        GameMode.duel => 'Which one?',
        GameMode.challenger => 'Challenger',
        GameMode.vibeCheck => 'Vibe check',
        GameMode.rate => 'Rate it',
        GameMode.bestOfBurst => 'Best of burst',
        GameMode.sort3 => 'Sort three',
        GameMode.rerankTop => 'Re-rank your Top 10',
        GameMode.browseHeart => '',
      };
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onRescan});
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, size: 56, color: Colors.white38),
            const SizedBox(height: 16),
            const Text('Nothing to rank yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Widen your library scope or wait for the scan to finish.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRescan, child: const Text('Open settings')),
          ],
        ),
      ),
    );
  }
}
