import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/arena/arena_models.dart';
import 'arena_image.dart';
import 'sets_providers.dart';

/// The boards of one set: the pooled "everyone" order, plus one board per
/// rater — every rater sees their own; the owner sees each friend's.
class SetBoardsScreen extends ConsumerStatefulWidget {
  const SetBoardsScreen({super.key, required this.set, this.initialRater});
  final SetSummary set;

  /// 'me' selects the caller's own board; null the aggregate.
  final String? initialRater;

  @override
  ConsumerState<SetBoardsScreen> createState() => _SetBoardsScreenState();
}

class _SetBoardsScreenState extends ConsumerState<SetBoardsScreen> {
  String? _rater; // null = everyone

  @override
  void initState() {
    super.initState();
    _rater = widget.initialRater;
  }

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    final raters = set.mine ? ref.watch(setRatersProvider(set.id)).value ?? const <SetRater>[] : const <SetRater>[];
    final me = ref.watch(setsMeIdProvider);
    final board = ref.watch(setBoardProvider((set.id, _rater == 'me' ? me : _rater)));
    return Scaffold(
      appBar: AppBar(title: Text(set.mine ? 'How friends rank yours' : '${set.ownerName} · ${set.title}')),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _chip('Everyone', null, subtitle: set.raters == 0 ? null : '${set.raters}'),
              if (!set.mine && set.myDone) _chip('My order', 'me'),
              for (final r in raters.where((r) => r.done)) _chip(r.name, r.id),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            _rater == null
                ? (set.raters == 0 ? 'Nobody has finished ranking yet — the pooled order settles as friends rate.' : 'Every duel from every rater, pooled. Arrows compare with ${set.mine ? 'your' : 'the owner\'s'} own order.')
                : 'One rater\'s order. Arrows compare with ${set.mine ? 'your' : 'the owner\'s'} own order.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        Expanded(
          child: board.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (rows) => rows.isEmpty
                ? const Center(child: Text('Nothing to show.', style: TextStyle(color: Colors.white60)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: rows.length,
                    itemBuilder: (_, i) => _Row(row: rows[i]).animate(delay: (i.clamp(0, 12) * 30).ms).fadeIn(),
                  ),
          ),
        ),
      ]),
    );
  }

  Widget _chip(String label, String? id, {String? subtitle}) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(subtitle == null ? label : '$label · $subtitle'),
          selected: _rater == id,
          onSelected: (_) => setState(() => _rater = id),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.row});
  final SetBoardRow row;

  @override
  Widget build(BuildContext context) {
    final r = row;
    final moved = r.moved;
    final unrated = r.duels == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        SizedBox(width: 36, child: Text('#${r.rank}', style: TextStyle(fontWeight: FontWeight.w800, color: r.rank <= 3 ? AppTheme.accent : Colors.white70))),
        SizedBox(width: 64, height: 80, child: ArenaImage(r.storagePath, borderRadius: 10)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Owner\'s #${r.ownerRank}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(unrated ? 'not rated yet' : '${r.score.round()} · ${r.wins}–${r.duels - r.wins}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
        if (!unrated && moved != 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: (moved > 0 ? Colors.greenAccent : Colors.orangeAccent).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Text('${moved > 0 ? '↑' : '↓'}${moved.abs()}', style: TextStyle(fontWeight: FontWeight.w700, color: moved > 0 ? Colors.greenAccent : Colors.orangeAccent)),
          )
        else if (!unrated)
          const Icon(Icons.check_rounded, color: Colors.white38, size: 18),
      ]),
    );
  }
}
