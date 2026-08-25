import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/arena/arena_models.dart';
import 'arena_image.dart';
import 'arena_providers.dart';

/// Ten duels on other people's photos from today's pool.
class ArenaRoundsScreen extends ConsumerStatefulWidget {
  const ArenaRoundsScreen({super.key});

  @override
  ConsumerState<ArenaRoundsScreen> createState() => _ArenaRoundsScreenState();
}

class _ArenaRoundsScreenState extends ConsumerState<ArenaRoundsScreen> {
  List<Pair>? _pairs;
  int _index = 0;
  String? _picked;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ref.read(arenaProvider.notifier).nextPairs();
    if (mounted) setState(() => _pairs = p);
  }

  Future<void> _pick(Pair p, String id) async {
    if (_busy || _picked != null) return;
    setState(() {
      _picked = id;
      _busy = true;
    });
    HapticFeedback.lightImpact();
    try {
      await ref.read(arenaProvider.notifier).recordDuel(p, id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    setState(() {
      _index++;
      _picked = null;
      _busy = false;
    });
    if (_index >= (_pairs?.length ?? 0)) {
      // Small pools yield fewer disjoint pairs per call; keep going until the set is done.
      final st = ref.read(arenaProvider).status;
      if (st.left > 0) {
        final more = await ref.read(arenaProvider.notifier).nextPairs();
        if (mounted && more.isNotEmpty) {
          setState(() {
            _pairs = more;
            _index = 0;
          });
          return;
        }
      }
      await ref.read(arenaProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairs = _pairs;
    final done = pairs != null && _index >= pairs.length;
    final s = ref.watch(arenaProvider);
    return Scaffold(
      appBar: AppBar(title: Text(done ? 'Set rated' : 'Which one?  ·  ${s.status.left} left')),
      body: SafeArea(
        child: pairs == null
            ? const Center(child: CircularProgressIndicator())
            : pairs.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Nothing left to rate right now — check back later today.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60))))
                : done
                    ? _Done(state: s)
                    : Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: s.status.required == 0 ? 1 : s.status.duelsToday / s.status.required, minHeight: 4, backgroundColor: Colors.white10, color: AppTheme.accent)),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: KeyedSubtree(key: ValueKey(_index), child: _Duel(pair: pairs[_index], picked: _picked, onPick: (id) => _pick(pairs[_index], id))),
                          ),
                        ),
                      ]),
      ),
    );
  }
}

class _Duel extends StatelessWidget {
  const _Duel({required this.pair, required this.picked, required this.onPick});
  final Pair pair;
  final String? picked;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    Widget tile(String id, String path) {
      final won = picked == id, lost = picked != null && !won;
      return Expanded(
        flex: won ? 11 : lost ? 8 : 10,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: lost ? 0.25 : 1,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            scale: won ? 1.02 : 1,
            child: ArenaImage(path, borderRadius: 20, onTap: () => onPick(id)),
          ),
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      child: Column(children: [tile(pair.aId, pair.aPath), const SizedBox(height: 8), tile(pair.bId, pair.bPath)]),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.state});
  final ArenaState state;

  @override
  Widget build(BuildContext context) {
    final e = state.myEntry;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded, size: 64, color: AppTheme.accent).animate().scale(curve: Curves.elasticOut, duration: 700.ms),
          const SizedBox(height: 16),
          const Text('Set rated — board unlocked.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            e == null
                ? 'Today\'s leaderboard is now open to you.'
                : e.settled
                    ? 'Your photo is #${e.rank} of ${e.total} right now.'
                    : 'Your photo is still settling (${e.duels}/6 duels) — others are rating it.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to the board')),
        ]),
      ),
    );
  }
}
