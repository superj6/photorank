import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/arena/arena_models.dart';
import 'arena_image.dart';
import 'arena_providers.dart';

final _historyProvider = FutureProvider.autoDispose<List<HistoryRow>>((ref) async {
  final api = await ref.watch(arenaApiProvider.future);
  return api?.myHistory() ?? const [];
});

/// Every day you entered, with where the photo finished.
class ArenaHistoryScreen extends ConsumerWidget {
  const ArenaHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Your arena days')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) return const Center(child: Text('No entries yet. Enter today\'s arena.', style: TextStyle(color: Colors.white60)));
          final best = rows.where((r) => r.rank != null).fold<HistoryRow?>(null, (b, r) => b == null || r.rank! < b.rank! ? r : b);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                _Stat('${rows.length}', 'days entered'),
                _Stat(best == null ? '—' : '#${best.rank}', 'best finish'),
                _Stat('${rows.fold(0, (n, r) => n + r.wins)}', 'duels won'),
              ]),
              const SizedBox(height: 16),
              for (final r in rows)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    SizedBox(width: 64, height: 80, child: ArenaImage(r.storagePath, borderRadius: 10)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${r.day.year}-${r.day.month.toString().padLeft(2, '0')}-${r.day.day.toString().padLeft(2, '0')}${r.roomId != null ? ' · room' : ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(r.rank == null ? 'settling' : '${r.finalRank != null ? 'Finished' : 'Currently'} #${r.rank} of ${r.total} · ${r.wins}–${r.duels - r.wins}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ]),
                    ),
                    if (r.rank != null && r.rank! <= 3) const Icon(Icons.emoji_events_rounded, color: AppTheme.accent),
                  ]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.accent)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ]),
      );
}
