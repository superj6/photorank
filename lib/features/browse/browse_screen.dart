import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/theme.dart';
import '../../core/dealer/photo_state.dart';
import '../../core/sampler/collections.dart';
import '../../core/sampler/rank_sampler.dart';
import '../../app/providers.dart';
import '../shell/shell_screen.dart';
import '../widgets/photo_tile.dart';
import 'browse_controller.dart';

enum _Mode { flow, deal, collections }

/// Browse: a vertical Flow through your ranking, Deal me 9, auto-collections,
/// and a slideshow that turns the phone into a frame.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _pager = PageController();
  _Mode _mode = _Mode.flow;
  Timer? _slideshow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(browseProvider).items.isEmpty) ref.read(browseProvider.notifier).open(Channel.topShelf);
    });
  }

  @override
  void dispose() {
    _stopSlideshow();
    _pager.dispose();
    super.dispose();
  }

  bool get _playing => _slideshow != null;

  void _startSlideshow() {
    HapticFeedback.selectionClick();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _slideshow = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pager.hasClients) return;
      final s = ref.read(browseProvider);
      final next = (_pager.page?.round() ?? 0) + 1;
      if (next >= s.items.length) {
        ref.read(browseProvider.notifier).more();
      }
      if (next < ref.read(browseProvider).items.length) {
        _pager.animateToPage(next, duration: const Duration(milliseconds: 900), curve: Curves.easeInOutCubic);
      }
    });
    setState(() {});
  }

  void _stopSlideshow() {
    _slideshow?.cancel();
    _slideshow = null;
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) setState(() {});
  }

  void _switch(Channel c) {
    _stopSlideshow();
    setState(() => _mode = _Mode.flow);
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
          switch (_mode) {
            _Mode.deal => _DealNine(ctl: ctl),
            _Mode.collections => _Collections(onOpen: (c, pool) {
                ctl.openCollection(c, pool);
                setState(() => _mode = _Mode.flow);
                if (_pager.hasClients) _pager.jumpToPage(0);
              }),
            _Mode.flow => s.items.isEmpty
                ? Center(
                    child: s.loading
                        ? const CircularProgressIndicator()
                        : Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              switch (s.channel) {
                                Channel.rising => 'Nothing has climbed in the last week yet.',
                                Channel.thisDay => 'No photos from this day in other years.',
                                _ => 'Rank a few hands first — the Flow follows your taste.',
                              },
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ),
                  )
                : GestureDetector(
                    onHorizontalDragEnd: s.channel == Channel.timeMachine
                        ? (d) {
                            if ((d.primaryVelocity ?? 0).abs() > 200) ctl.more();
                          }
                        : null,
                    onTap: _playing ? _stopSlideshow : null,
                    child: PageView.builder(
                      controller: _pager,
                      scrollDirection: Axis.vertical,
                      itemCount: s.items.length,
                      onPageChanged: ctl.onPage,
                      itemBuilder: (_, i) => _FlowPage(
                        photo: s.items[i],
                        kenBurns: _playing,
                        onHeart: () => ctl.heart(s.items[i].id),
                      ),
                    ),
                  ),
          },
          if (!_playing)
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (final c in const [Channel.topShelf, Channel.wildcard, Channel.timeMachine, Channel.deepCuts, Channel.rising, Channel.thisDay])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_name(c)),
                              selected: _mode == _Mode.flow && s.channel == c,
                              onSelected: (_) => _switch(c),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: const Icon(Icons.collections_bookmark_rounded, size: 16),
                            label: const Text('Collections'),
                            selected: _mode == _Mode.collections,
                            onSelected: (_) {
                              _stopSlideshow();
                              setState(() => _mode = _Mode.collections);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: const Icon(Icons.grid_view_rounded, size: 16),
                            label: const Text('Deal me 9'),
                            selected: _mode == _Mode.deal,
                            onSelected: (_) {
                              _stopSlideshow();
                              setState(() => _mode = _Mode.deal);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_mode == _Mode.flow && s.momentLabel != null)
                    Padding(padding: const EdgeInsets.only(top: 6), child: Pill(s.momentLabel!, icon: s.channel == Channel.collection ? Icons.collections_bookmark_rounded : Icons.history)),
                ],
              ),
            ),
          if (_mode == _Mode.flow && s.items.isNotEmpty && !_playing)
            Positioned(
              right: 16,
              top: MediaQuery.paddingOf(context).top + 56,
              child: IconButton.filledTonal(
                tooltip: 'Slideshow',
                onPressed: _startSlideshow,
                icon: const Icon(Icons.play_arrow_rounded),
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
        Channel.collection => 'Collection',
      };
}

class _FlowPage extends StatefulWidget {
  const _FlowPage({required this.photo, required this.onHeart, this.kenBurns = false});
  final PhotoState photo;
  final VoidCallback onHeart;
  final bool kenBurns;

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
    Widget image = PhotoTile(
      mediaId: p.mediaId,
      fit: BoxFit.contain,
      borderRadius: 0,
      onDoubleTap: _heart,
      onTap: widget.kenBurns ? null : () => context.openPhoto(p.id),
    );
    if (widget.kenBurns) {
      image = TweenAnimationBuilder<double>(
        key: ValueKey('kb-${p.id}'),
        tween: Tween(begin: 1.0, end: 1.08),
        duration: const Duration(seconds: 6),
        curve: Curves.easeInOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: image,
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        if (_hearts > 0)
          Center(
            key: ValueKey(_hearts),
            child: const Icon(Icons.favorite, size: 120, color: AppTheme.accent)
                .animate()
                .scale(begin: const Offset(0.4, 0.4), curve: Curves.elasticOut, duration: 600.ms)
                .then()
                .fadeOut(duration: 300.ms),
          ),
        if (!widget.kenBurns)
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

class _Collections extends ConsumerWidget {
  const _Collections({required this.onOpen});
  final void Function(Collection, List<PhotoState>) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pool = ref.watch(rankingProvider).value ?? const <PhotoState>[];
    final collections = buildCollections(pool);
    if (collections.isEmpty) {
      return const Center(child: Text('Collections appear once you have ranked a few photos.', style: TextStyle(color: Colors.white60)));
    }
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(12, MediaQuery.paddingOf(context).top + 56, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.8),
      itemCount: collections.length,
      itemBuilder: (_, i) {
        final c = collections[i];
        final cover = pool.where((p) => p.id == c.coverId).firstOrNull;
        return PhotoTile(
          mediaId: cover?.mediaId,
          size: ThumbCacheSizes.grid,
          borderRadius: 16,
          onTap: () => onOpen(c, pool),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 30, 12, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  Text(c.subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ),
        ).animate(delay: (i * 40).ms).fadeIn().scale(begin: const Offset(0.95, 0.95));
      },
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
