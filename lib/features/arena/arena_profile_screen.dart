import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/arena/arena_models.dart';
import 'arena_image.dart';
import 'arena_providers.dart';

final _historyProvider = FutureProvider.autoDispose<List<HistoryRow>>((ref) async {
  final api = await ref.watch(arenaApiProvider.future);
  return api?.myHistory() ?? const [];
});

final _daysProvider = FutureProvider.autoDispose<List<DaySummary>>((ref) => ref.read(arenaProvider.notifier).days());

/// Your arena account: every photo you entered and where it finished, your
/// best days, and every past day's final board.
class ArenaProfileScreen extends ConsumerWidget {
  const ArenaProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_historyProvider);
    final days = ref.watch(_daysProvider);
    final profile = ref.watch(arenaProvider).profile;
    return Scaffold(
      appBar: AppBar(title: Text(profile?.username != null ? '@${profile!.username}' : 'Your arena')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          final finished = rows.where((r) => r.finalRank != null).toList();
          final best = [...finished]..sort((a, b) => a.finalRank!.compareTo(b.finalRank!));
          final avgPct = finished.isEmpty ? null : finished.map((r) => r.percentile!).reduce((a, b) => a + b) ~/ finished.length;
          final streak = _streak(rows.map((r) => r.day));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                _Stat('${rows.length}', 'days entered'),
                _Stat(best.isEmpty ? '—' : '#${best.first.finalRank}', 'best finish'),
                _Stat(avgPct == null ? '—' : 'top $avgPct%', 'on average'),
                _Stat('$streak', 'day streak'),
              ]).animate().fadeIn(),
              if (best.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Best days', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: best.take(5).length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final r = best[i];
                      return SizedBox(
                        width: 112,
                        child: ArenaImage(
                          r.storagePath,
                          borderRadius: 12,
                          onTap: () => _openDay(context, r.day),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(8, 20, 8, 6),
                              width: double.infinity,
                              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
                              child: Text('#${r.finalRank} · ${_short(r.day)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                      ).animate(delay: (i * 60).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text('Your entries', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (rows.isEmpty) const Text('No entries yet. Enter today\'s arena.', style: TextStyle(color: Colors.white60)),
              for (final r in rows) _EntryRow(row: r, onTap: () => _openDay(context, r.day)),
              const SizedBox(height: 20),
              Text('Past boards', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('Final at midnight UTC and open to everyone.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              days.when(
                loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('$e'),
                data: (list) => Column(children: [
                  if (list.isEmpty) const Text('No finished days yet.', style: TextStyle(color: Colors.white60)),
                  for (final d in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: d.myStoragePath == null
                          ? const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.calendar_today_rounded, size: 18, color: Colors.white54))
                          : SizedBox(width: 44, height: 44, child: ArenaImage(d.myStoragePath!, borderRadius: 22)),
                      title: Text(_long(d.day)),
                      subtitle: Text('${d.entries} photos${d.myFinalRank != null ? ' · you finished #${d.myFinalRank}' : ''}${d.finalized ? '' : ' · finalising'}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openDay(context, d.day),
                    ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  static int _streak(Iterable<DateTime> days) {
    final set = {for (final d in days) DateTime(d.year, d.month, d.day)};
    if (set.isEmpty) return 0;
    final t = DateTime.now().toUtc();
    var cursor = DateTime(t.year, t.month, t.day);
    if (!set.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
    var n = 0;
    while (set.contains(cursor)) {
      n++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return n;
  }

  static void _openDay(BuildContext context, DateTime day) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ArenaDayScreen(day: day)));

  static String _short(DateTime d) => '${d.day}/${d.month}';
  static String _long(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.row, required this.onTap});
  final HistoryRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = row;
    final rank = r.rank;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          SizedBox(width: 64, height: 80, child: ArenaImage(r.storagePath, borderRadius: 10)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${ArenaProfileScreen._long(r.day)}${r.roomId != null ? ' · room' : ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                rank == null
                    ? (r.status == 'active' ? 'today · board opens after your set' : r.status)
                    : '${r.finalRank != null ? 'Finished' : 'Currently'} #$rank of ${r.total} · top ${r.percentile}% · ${r.wins}–${r.duels - r.wins}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ]),
          ),
          if (rank != null && rank <= 3) const Icon(Icons.emoji_events_rounded, color: AppTheme.accent),
        ]),
      ),
    );
  }
}

/// A full board for one day (past days are final and public).
class ArenaDayScreen extends ConsumerWidget {
  const ArenaDayScreen({super.key, required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(_dayBoardProvider(day));
    return Scaffold(
      appBar: AppBar(title: Text(ArenaProfileScreen._long(day))),
      body: board.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) => rows.isEmpty
            ? const Center(child: Text('Nothing to show for this day.', style: TextStyle(color: Colors.white60)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                itemBuilder: (_, i) {
                  final r = rows[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: r.mine ? AppTheme.accent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: r.mine ? Border.all(color: AppTheme.accent, width: 1.5) : null,
                    ),
                    child: Row(children: [
                      SizedBox(width: 36, child: Text('#${r.rank}', style: TextStyle(fontWeight: FontWeight.w800, color: r.rank <= 3 ? AppTheme.accent : Colors.white70))),
                      SizedBox(width: 64, height: 80, child: ArenaImage(r.storagePath, borderRadius: 10)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.mine ? 'You' : r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${r.score.round()} · ${r.wins}–${r.duels - r.wins}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ])),
                    ]),
                  );
                },
              ),
      ),
    );
  }
}

final _dayBoardProvider = FutureProvider.autoDispose.family<List<BoardRow>, DateTime>((ref, day) => ref.read(arenaProvider.notifier).boardFor(day));

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.accent)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54), textAlign: TextAlign.center),
        ]),
      );
}
