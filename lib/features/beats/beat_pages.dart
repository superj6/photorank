import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme.dart';
import '../../core/beats/beat.dart';
import '../../core/rating/observation.dart';
import '../settings/settings_screen.dart';
import '../widgets/photo_tile.dart';
import 'beat_photo.dart';

/// Renders one [BeatPage]. Every page is: a headline, one visual, one line.
class BeatPageView extends StatelessWidget {
  const BeatPageView(this.page, {super.key});

  final BeatPage page;

  @override
  Widget build(BuildContext context) {
    return switch (page) {
      StandingsPage p => _Frame(
          eyebrow: 'Right now',
          title: 'Your Top 3',
          footer: '${p.settled} of ${p.total} photos settled',
          child: _Podium(ids: p.top),
        ),
      MoverPage p => _Frame(
          eyebrow: 'Climber',
          title: p.rankBefore != null && p.rankAfter != null ? 'From #${p.rankBefore} to #${p.rankAfter}' : 'On the rise',
          footer: 'Score ${p.scoreBefore.round()} → ${p.scoreAfter.round()} this hand',
          child: _Hero(id: p.photoId, badge: '+${p.delta.round()}'),
        ),
      ThenVsNowPage p => _Frame(
          eyebrow: 'Then vs now',
          title: '${p.decisionsBetween} decisions later',
          footer: 'Started at ${p.scoreThen.round()}, now ${p.scoreNow.round()} · ${_days(p.daysBetween)}',
          child: _Hero(id: p.photoId, badge: '${p.scoreThen.round()} → ${p.scoreNow.round()}'),
        ),
      HeadToHeadPage p => _Frame(
          eyebrow: 'Head to head',
          title: '${p.aWins}–${p.bWins}',
          footer: 'The two you keep comparing. Settle it?',
          child: Row(children: [
            Expanded(child: BeatPhoto(p.a)),
            const SizedBox(width: 10),
            Expanded(child: BeatPhoto(p.b)),
          ]),
        ),
      DeepCutPage p => _Frame(
          eyebrow: 'Deep cut',
          title: 'Still #${p.rank}',
          footer: 'You haven\'t seen this one in ${p.daysUnseen} days. Still feeling it?',
          child: _Hero(id: p.photoId, badge: '#${p.rank}'),
        ),
      BurstClearedPage p => _Frame(
          eyebrow: 'Burst settled',
          title: 'The keeper',
          footer: '${p.siblingIds.length} near-identical shots ranked below it',
          child: Column(children: [
            Expanded(flex: 3, child: BeatPhoto(p.winnerId)),
            const SizedBox(height: 8),
            Expanded(
              child: Row(children: [
                for (final id in p.siblingIds.take(4)) ...[
                  Expanded(child: BeatPhoto(id, borderRadius: 12, size: ThumbCacheSizes.grid)),
                  if (id != p.siblingIds.take(4).last) const SizedBox(width: 6),
                ],
              ]),
            ),
          ]),
        ),
      SettledPage p => _Frame(
          eyebrow: 'Milestone',
          title: '${p.crossed}% settled',
          footer: p.crossed == 100
              ? 'Every photo has found its place. New arrivals will keep the game going.'
              : '${p.settled} of ${p.total} photos have a confident rank',
          child: Center(child: _Ring(fraction: p.settled / (p.total == 0 ? 1 : p.total), label: '${p.crossed}%')),
        ),
      NewTopPage p => _Frame(
          eyebrow: 'New number one',
          title: 'A new #1',
          footer: p.previousId == null ? 'Your first #1.' : 'It just overtook your previous favourite.',
          child: _NewTop(id: p.photoId, previous: p.previousId),
        ),
      TopTenPage p => _Frame(
          eyebrow: 'Official',
          title: 'Your Top 10',
          footer: 'All ten are settled. This is your shelf.',
          child: _Grid(ids: p.ids, columns: 3),
        ),
      MilestonePage p => _Frame(
          eyebrow: 'Milestone',
          title: '${p.decisions} decisions',
          footer: '${p.minutes} minutes played · ${p.streak}-day streak',
          child: Center(
            child: Text('${p.decisions}',
                    style: const TextStyle(fontSize: 120, fontWeight: FontWeight.w800, color: AppTheme.accent, letterSpacing: -4))
                .animate()
                .scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut, duration: 900.ms),
          ),
        ),
      ModeUnlockedPage p => _Frame(
          eyebrow: 'New mode unlocked',
          title: SettingsScreen.modeNames[p.mode]?.$1 ?? p.mode.name,
          footer: SettingsScreen.modeNames[p.mode]?.$2 ?? '',
          child: Center(
            child: Icon(_modeIcon(p.mode), size: 140, color: AppTheme.accent)
                .animate()
                .scale(begin: const Offset(0.4, 0.4), curve: Curves.elasticOut, duration: 900.ms)
                .then()
                .shimmer(duration: 800.ms),
          ),
        ),
      ThemedHandPage p => _Frame(
          eyebrow: 'Themed hand',
          title: _themeTitle(p.theme),
          footer: '${p.count} cards from one slice of your library. Deal it?',
          child: Center(child: Icon(_themeIcon(p.theme), size: 140, color: AppTheme.accent).animate().fadeIn().scale(begin: const Offset(0.7, 0.7))),
        ),
      WelcomeBackPage p => _Frame(
          eyebrow: 'Welcome back',
          title: '${p.daysAway} days away',
          footer: '${p.newPhotos} new photos arrived. ${p.topHeld ? 'Your #1 held.' : 'Your #1 changed while you were gone.'}',
          child: p.topId == null ? const SizedBox.shrink() : _Hero(id: p.topId!, badge: '#1'),
        ),
    };
  }

  static String _days(int d) => d == 0 ? 'since today' : d == 1 ? 'since yesterday' : 'over $d days';

  static IconData _modeIcon(GameMode m) => switch (m) {
        GameMode.duel => Icons.compare_arrows_rounded,
        GameMode.vibeCheck => Icons.favorite_rounded,
        GameMode.rate => Icons.star_rounded,
        GameMode.bestOfBurst => Icons.burst_mode_rounded,
        GameMode.sort3 => Icons.low_priority_rounded,
        GameMode.challenger => Icons.emoji_events_rounded,
        GameMode.rerankTop => Icons.military_tech_rounded,
        GameMode.browseHeart => Icons.favorite_border,
      };

  static String _themeTitle(DeckTheme t) => switch (t) {
        DeckTheme.oneTrip => 'One day, one deck',
        DeckTheme.sameMonth => 'A single month',
        DeckTheme.landscapes => 'Landscapes only',
        DeckTheme.rerankTop => 'Re-rank your Top 10',
      };

  static IconData _themeIcon(DeckTheme t) => switch (t) {
        DeckTheme.oneTrip => Icons.luggage_rounded,
        DeckTheme.sameMonth => Icons.calendar_month_rounded,
        DeckTheme.landscapes => Icons.landscape_rounded,
        DeckTheme.rerankTop => Icons.military_tech_rounded,
      };
}

class _Frame extends StatelessWidget {
  const _Frame({required this.eyebrow, required this.title, required this.footer, required this.child});
  final String eyebrow;
  final String title;
  final String footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(),
                  style: const TextStyle(fontSize: 12, letterSpacing: 1.4, color: AppTheme.accent, fontWeight: FontWeight.w700))
              .animate()
              .fadeIn(duration: 250.ms),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.headlineMedium)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 16),
          Expanded(child: child.animate(delay: 120.ms).fadeIn(duration: 350.ms).scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutCubic)),
          const SizedBox(height: 14),
          Text(footer, style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.35))
              .animate(delay: 250.ms)
              .fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.id, required this.badge});
  final int id;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return BeatPhoto(
      id,
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(padding: const EdgeInsets.all(12), child: Pill(badge, color: AppTheme.accent)),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.ids});
  final List<int> ids;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 3, child: BeatPhoto(ids[0], child: const _Corner('#1'))),
        const SizedBox(height: 8),
        Expanded(
          flex: 2,
          child: Row(children: [
            Expanded(child: BeatPhoto(ids[1], borderRadius: 14, child: const _Corner('#2'))),
            const SizedBox(width: 8),
            Expanded(child: BeatPhoto(ids[2], borderRadius: 14, child: const _Corner('#3'))),
          ]),
        ),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topLeft,
        child: Padding(padding: const EdgeInsets.all(10), child: Pill(text, color: AppTheme.accent)),
      );
}

class _Grid extends StatelessWidget {
  const _Grid({required this.ids, required this.columns});
  final List<int> ids;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 0.8),
      itemCount: ids.length,
      itemBuilder: (_, i) => BeatPhoto(ids[i], borderRadius: 12, size: ThumbCacheSizes.grid, child: _Corner('#${i + 1}'))
          .animate(delay: (i * 50).ms)
          .fadeIn()
          .scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

class _NewTop extends StatelessWidget {
  const _NewTop({required this.id, this.previous});
  final int id;
  final int? previous;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BeatPhoto(id, child: const _Corner('#1'))
              .animate()
              .flipV(begin: -0.5, end: 0, duration: 700.ms, curve: Curves.easeOutBack)
              .then()
              .shimmer(duration: 900.ms, color: Colors.white24),
        ),
        if (previous != null)
          Positioned(
            right: 12,
            bottom: 12,
            width: 96,
            height: 120,
            child: BeatPhoto(previous!, borderRadius: 12, size: ThumbCacheSizes.grid, child: const _Corner('#2'))
                .animate(delay: 500.ms)
                .fadeIn()
                .slideX(begin: 0.3, end: 0),
          ),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.fraction, required this.label});
  final double fraction;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(value: v, strokeWidth: 14, backgroundColor: Colors.white10, color: AppTheme.accent, strokeCap: StrokeCap.round),
            Center(child: Text(label, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }
}
