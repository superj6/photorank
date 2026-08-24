import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/dealer/photo_state.dart';
import '../../core/sampler/rank_sampler.dart';
import '../shell/shell_screen.dart';
import '../widgets/photo_tile.dart';
import 'browse_controller.dart';

/// Browse: a vertical Flow through your ranking, plus Deal me 9.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _pager = PageController();
  bool _dealMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(browseProvider).items.isEmpty) {
        ref.read(browseProvider.notifier).open(Channel.topShelf);
      }
    });
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _switch(Channel c) {
    ref.read(browseProvider.notifier).open(c);
    if (_pager.hasClients) _pager.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(browseProvider);
    final ctl = ref.read(browseProvider.notifier);
    return Scaffold(
      body: Stack(
        children: [
          if (_dealMode)
            _DealNine(ctl: ctl)
          else if (s.items.isEmpty)
            Center(
              child: s.loading
                  ? const CircularProgressIndicator()
                  : const Text('Rank a few hands first — the Flow follows your taste.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
            )
          else
            GestureDetector(
              onHorizontalDragEnd: s.channel == Channel.timeMachine
                  ? (d) {
                      if ((d.primaryVelocity ?? 0).abs() > 200) ctl.more();
                    }
                  : null,
              child: PageView.builder(
                controller: _pager,
                scrollDirection: Axis.vertical,
                itemCount: s.items.length,
                onPageChanged: ctl.onPage,
                itemBuilder: (_, i) => _FlowPage(photo: s.items[i], onHeart: () => ctl.heart(s.items[i].id)),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final c in const [Channel.topShelf, Channel.wildcard, Channel.timeMachine, Channel.deepCuts])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_name(c)),
                            selected: !_dealMode && s.channel == c,
                            onSelected: (_) {
                              setState(() => _dealMode = false);
                              _switch(c);
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: const Icon(Icons.grid_view_rounded, size: 16),
                          label: const Text('Deal me 9'),
                          selected: _dealMode,
                          onSelected: (_) => setState(() => _dealMode = true),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_dealMode && s.momentLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Pill(s.momentLabel!, icon: Icons.history),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _name(Channel c) => switch (c) {
        Channel.topShelf => 'Top Shelf',
        Channel.wildcard => 'Wildcard',
        Channel.timeMachine => 'Time Machine',
        Channel.deepCuts => 'Deep Cuts',
        Channel.rising => 'Rising',
        Channel.thisDay => 'This Day',
      };
}

class _FlowPage extends StatefulWidget {
  const _FlowPage({required this.photo, required this.onHeart});
  final PhotoState photo;
  final VoidCallback onHeart;

  @override
  State<_FlowPage> createState() => _FlowPageState();
}

class _FlowPageState extends State<_FlowPage> {
  int _hearts = 0;

  void _heart() {
    HapticFeedback.lightImpact();
    setState(() => _hearts++);
    widget.onHeart();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.photo;
    final date = p.takenAt;
    return Stack(
      fit: StackFit.expand,
      children: [
        PhotoTile(
          mediaId: p.mediaId,
          fit: BoxFit.contain,
          borderRadius: 0,
          onDoubleTap: _heart,
          onTap: () => context.openPhoto(p.id),
        ),
        if (_hearts > 0)
          Center(
            key: ValueKey(_hearts),
            child: const Icon(Icons.favorite, size: 120, color: AppTheme.accent)
                .animate()
                .scale(begin: const Offset(0.4, 0.4), curve: Curves.elasticOut, duration: 600.ms)
                .then()
                .fadeOut(duration: 300.ms),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Row(
            children: [
              Pill('${p.rating.score.round()}', icon: Icons.emoji_events, color: AppTheme.accent),
              const SizedBox(width: 8),
              if (date != null) Pill('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
              const Spacer(),
              const Pill('double-tap ♥'),
            ],
          ),
        ),
      ],
    );
  }
}

class _DealNine extends StatefulWidget {
  const _DealNine({required this.ctl});
  final BrowseController ctl;

  @override
  State<_DealNine> createState() => _DealNineState();
}

class _DealNineState extends State<_DealNine> {
  late Future<List<PhotoState>> _hand = widget.ctl.dealNine();
  int _deal = 0;

  void _again() => setState(() {
        _deal++;
        _hand = widget.ctl.dealNine();
      });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 56, 12, 12),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<PhotoState>>(
                future: _hand,
                builder: (_, snap) {
                  final items = snap.data ?? const <PhotoState>[];
                  if (items.isEmpty) return const Center(child: CircularProgressIndicator());
                  return Dismissible(
                    key: ValueKey(_deal),
                    direction: DismissDirection.horizontal,
                    onDismissed: (_) => _again(),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 0.72),
                      itemCount: items.length,
                      itemBuilder: (_, i) => PhotoTile(
                        mediaId: items[i].mediaId,
                        size: ThumbCacheSizes.grid,
                        borderRadius: 12,
                        onTap: () => context.openPhoto(items[i].id),
                      ).animate(delay: (i * 40).ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _again,
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Deal again  (or fling the hand away)'),
            ),
          ],
        ),
      ),
    );
  }
}
