import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/arena/arena_models.dart';
import 'arena_image.dart';
import 'set_boards_screen.dart';
import 'sets_providers.dart';

/// Rank a friend's set: one pass of duels, then your order next to theirs.
class SetRankScreen extends ConsumerStatefulWidget {
  const SetRankScreen({super.key, required this.setId});
  final String setId;

  @override
  ConsumerState<SetRankScreen> createState() => _SetRankScreenState();
}

class _SetRankScreenState extends ConsumerState<SetRankScreen> {
  List<Pair>? _pairs;
  int _index = 0;
  String? _picked;
  bool _busy = false;

  SetSummary? get _set => ref.read(setsProvider).sets.where((s) => s.id == widget.setId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final set = _set;
    final p = set == null ? const <Pair>[] : await ref.read(setsProvider.notifier).nextPairs(set);
    if (mounted) setState(() => _pairs = p);
  }

  Future<void> _pick(Pair p, String id) async {
    final set = _set;
    if (_busy || _picked != null || set == null) return;
    setState(() {
      _picked = id;
      _busy = true;
    });
    HapticFeedback.lightImpact();
    try {
      await ref.read(setsProvider.notifier).recordDuel(set, p, id);
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
      final now = _set;
      if (now != null && !now.myDone) {
        final more = await ref.read(setsProvider.notifier).nextPairs(now);
        if (mounted && more.isNotEmpty) {
          setState(() {
            _pairs = more;
            _index = 0;
          });
          return;
        }
      }
      await ref.read(setsProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final set = ref.watch(setsProvider).sets.where((s) => s.id == widget.setId).firstOrNull;
    final pairs = _pairs;
    final done = set != null && (set.myDone || (pairs != null && _index >= pairs.length && pairs.isNotEmpty));
    final left = set == null ? 0 : (set.requiredDuels - set.myDuels).clamp(0, 99);
    return Scaffold(
      appBar: AppBar(title: Text(set == null ? 'Set' : done ? 'Ranked · ${set.ownerName}' : '${set.ownerName}  ·  $left left')),
      body: SafeArea(
        child: set == null || pairs == null
            ? const Center(child: CircularProgressIndicator())
            : done
                ? _Done(set: set)
                : pairs.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Nothing left to rate in this set.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60))))
                    : Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: set.requiredDuels == 0 ? 1 : set.myDuels / set.requiredDuels, minHeight: 4, backgroundColor: Colors.white10, color: AppTheme.accent)),
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
  const _Done({required this.set});
  final SetSummary set;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, size: 64, color: AppTheme.accent).animate().scale(curve: Curves.elasticOut, duration: 700.ms),
            const SizedBox(height: 16),
            Text('You ranked ${set.ownerName}\'s set.', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text('See where you agree — and where you really don\'t.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => SetBoardsScreen(set: set, initialRater: 'me'))),
              icon: const Icon(Icons.leaderboard_rounded),
              label: const Text('Your order vs theirs'),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
          ]),
        ),
      );
}
