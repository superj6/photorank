import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/beats/beat.dart';
import '../../data/db/database.dart';
import 'beat_overlay.dart';
import 'beat_photo.dart';
import 'beat_pages.dart';

final _momentsProvider = FutureProvider.autoDispose<List<(BeatRow, Beat)>>((ref) async {
  final rows = await ref.watch(beatRepoProvider).listBeats(limit: 200);
  return [
    for (final r in rows)
      (r, Beat.fromJson((jsonDecode(r.payloadJson) as Map).cast<String, dynamic>(), decisionCount: r.decisionCount, id: r.id)),
  ];
});

/// History of every beat, newest first. Tap to replay.
class MomentsScreen extends ConsumerWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moments = ref.watch(_momentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Moments')),
      body: moments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Keep playing — moments appear as your ranking takes shape.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final (row, beat) = items[i];
              final photoId = _heroId(beat);
              return ListTile(
                tileColor: Colors.white.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: SizedBox(
                  width: 52,
                  height: 52,
                  child: photoId == null
                      ? Icon(_icon(beat.kind), color: Colors.white70)
                      : BeatPhoto(photoId, borderRadius: 10),
                ),
                title: Text(_title(beat)),
                subtitle: Text('${_when(row.createdAt)} · decision ${row.decisionCount}'),
                trailing: beat.shareable ? const Icon(Icons.ios_share_rounded, size: 18, color: Colors.white38) : null,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (ctx) => Scaffold(
                    body: SafeArea(
                      child: BeatOverlay(
                        beat: beat,
                        continueLabel: 'Done',
                        onContinue: () => Navigator.of(ctx).pop(),
                        onShared: () => ref.read(beatRepoProvider).markShared(row.id),
                      ),
                    ),
                  ),
                )),
              );
            },
          );
        },
      ),
    );
  }

  static int? _heroId(Beat b) {
    for (final p in b.pages) {
      switch (p) {
        case StandingsPage(:final top):
          return top.firstOrNull;
        case MoverPage(:final photoId):
        case ThenVsNowPage(:final photoId):
        case DeepCutPage(:final photoId):
        case NewTopPage(:final photoId):
          return photoId;
        case HeadToHeadPage(:final a):
          return a;
        case BurstClearedPage(:final winnerId):
          return winnerId;
        case TopTenPage(:final ids):
          return ids.firstOrNull;
        case WelcomeBackPage(:final topId):
          return topId;
        case BestOfPeriodPage(:final photoId):
          return photoId;
        case TopNinePage(:final ids):
          return ids.firstOrNull;
        case BestOfMonthsPage(:final entries):
          return entries.firstOrNull?.$2;
        case SettledPage() || MilestonePage() || ModeUnlockedPage() || ThemedHandPage() || PeriodCoverPage() || NumbersPage() || TastePage() || TrendPage():
          continue;
      }
    }
    return null;
  }

  static String _title(Beat b) => switch (b.kind) {
        BeatKind.standings => 'Your Top 3',
        BeatKind.mover => 'A climber',
        BeatKind.thenVsNow => 'Then vs now',
        BeatKind.headToHead => 'Head to head',
        BeatKind.deepCut => 'Deep cut',
        BeatKind.burstCleared => 'Burst settled',
        BeatKind.settledPct => '${(b.pages.first as SettledPage).crossed}% settled',
        BeatKind.newTop => 'A new #1',
        BeatKind.topTenOfficial => 'Top 10 official',
        BeatKind.milestone => '${(b.pages.first as MilestonePage).decisions} decisions',
        BeatKind.modeUnlocked => 'New mode unlocked',
        BeatKind.themedHand => 'Themed hand',
        BeatKind.welcomeBack => 'Welcome back',
        BeatKind.weekly => 'Your week · ${_periodLabel(b)}',
        BeatKind.monthly => 'Your month · ${_periodLabel(b)}',
        BeatKind.yearly => 'Your year · ${_periodLabel(b)}',
      };

  static String _periodLabel(Beat b) => b.pages.whereType<PeriodCoverPage>().firstOrNull?.label ?? '';

  static IconData _icon(BeatKind k) => switch (k) {
        BeatKind.milestone => Icons.flag_rounded,
        BeatKind.settledPct => Icons.donut_large_rounded,
        BeatKind.modeUnlocked => Icons.lock_open_rounded,
        BeatKind.themedHand => Icons.style_rounded,
        BeatKind.weekly => Icons.view_week_rounded,
        BeatKind.monthly => Icons.calendar_month_rounded,
        BeatKind.yearly => Icons.auto_awesome_rounded,
        _ => Icons.auto_awesome,
      };

  static String _when(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Unused import guard for analyzers that can't see the switch exhaustiveness.
// ignore: unused_element
const _keep = BeatPageView;
