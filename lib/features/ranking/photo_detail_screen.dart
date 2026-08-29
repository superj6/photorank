import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/rating/glicko.dart';
import '../../data/repo/photo_repo.dart';
import '../share/share_cards.dart';
import '../share/share_preview_screen.dart';

final _detailProvider = FutureProvider.family<_Detail?, int>((ref, id) async {
  final axis = await ref.watch(axisIdProvider.future);
  final row = await ref.watch(photoRepoProvider).byId(id);
  if (row == null) return null;
  final rating = await ref.watch(rankingRepoProvider).ratingOf(axis, id);
  final (wins, losses) = await ref.watch(photoRepoProvider).record(axis, id);
  final verdicts = await ref.watch(photoRepoProvider).verdicts(axis, id);
  final ranked = await ref.watch(rankingProvider.future);
  final rank = ranked.indexWhere((p) => p.id == id) + 1;
  return _Detail(mediaId: row.mediaId, takenAt: row.takenAt, rating: rating, wins: wins, losses: losses, rank: rank, verdicts: verdicts);
});

class _Detail {
  const _Detail({required this.mediaId, this.takenAt, required this.rating, required this.wins, required this.losses, required this.rank, required this.verdicts});
  final String mediaId;
  final DateTime? takenAt;
  final Rating rating;
  final int wins;
  final int losses;
  final int rank;
  final PhotoVerdicts verdicts;
}

class PhotoDetailScreen extends ConsumerWidget {
  const PhotoDetailScreen({super.key, required this.photoId});

  final int photoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(_detailProvider(photoId));
    final source = ref.watch(photoSourceProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () {
              final d = detail.value;
              SharePreviewScreen.open(context,
                  card: NumberOneCard(photoId: photoId, label: d != null && d.rank > 0 ? 'My #${d.rank} photo' : 'From my ranking'),
                  filename: 'photorank-photo-$photoId.png');
            },
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (d) {
          if (d == null) return const Center(child: Text('Photo not found'));
          final date = d.takenAt;
          return Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  maxScale: 6,
                  child: Center(child: Image(image: source.original(d.mediaId), fit: BoxFit.contain)),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                color: AppTheme.bg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Big(label: 'Rank', value: d.rank > 0 ? '#${d.rank}' : '—'),
                        _Big(label: 'Rating', value: '${d.rating.score.round()}'),
                        _Big(label: 'Settled', value: '${(d.rating.confidence * 100).round()}%'),
                        _Big(label: 'Record', value: '${d.wins}–${d.losses}'),
                      ],
                    ),
                    if (d.verdicts.any) ...[
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        if (d.verdicts.stars != null) _Verdict(icon: Icons.star_rounded, text: '${'★' * d.verdicts.stars!}${'☆' * (5 - d.verdicts.stars!)}${d.verdicts.timesRated > 1 ? '  ·  rated ${d.verdicts.timesRated}×' : ''}'),
                        if (d.verdicts.latestVibe != null)
                          _Verdict(
                            icon: d.verdicts.latestVibe! ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            text: '${d.verdicts.latestVibe! ? 'Feeling it' : 'Not feeling it'}${d.verdicts.feeling + d.verdicts.notFeeling > 1 ? '  ·  ${d.verdicts.feeling} of ${d.verdicts.feeling + d.verdicts.notFeeling}' : ''}',
                            on: d.verdicts.latestVibe!,
                          ),
                      ]),
                    ],
                    if (date != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// A star rating or vibe verdict chip.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.icon, required this.text, this.on = true});
  final IconData icon;
  final String text;
  final bool on;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: (on ? AppTheme.accent : Colors.white).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: on ? AppTheme.accent : Colors.white60),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: on ? Colors.white : Colors.white70)),
        ]),
      );
}
