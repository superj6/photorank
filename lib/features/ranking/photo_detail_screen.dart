import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/rating/glicko.dart';

final _detailProvider = FutureProvider.family<_Detail?, int>((ref, id) async {
  final axis = await ref.watch(axisIdProvider.future);
  final row = await ref.watch(photoRepoProvider).byId(id);
  if (row == null) return null;
  final rating = await ref.watch(rankingRepoProvider).ratingOf(axis, id);
  final (wins, losses) = await ref.watch(photoRepoProvider).record(axis, id);
  final ranked = await ref.watch(rankingProvider.future);
  final rank = ranked.indexWhere((p) => p.id == id) + 1;
  return _Detail(mediaId: row.mediaId, takenAt: row.takenAt, rating: rating, wins: wins, losses: losses, rank: rank);
});

class _Detail {
  const _Detail({required this.mediaId, this.takenAt, required this.rating, required this.wins, required this.losses, required this.rank});
  final String mediaId;
  final DateTime? takenAt;
  final Rating rating;
  final int wins;
  final int losses;
  final int rank;
}

class PhotoDetailScreen extends ConsumerWidget {
  const PhotoDetailScreen({super.key, required this.photoId});

  final int photoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(_detailProvider(photoId));
    final cache = ref.watch(thumbCacheProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (d) {
          if (d == null) return const Center(child: Text('Photo not found'));
          final date = d.takenAt;
          return Column(
            children: [
              Expanded(
                child: FutureBuilder<AssetEntity?>(
                  future: cache.entity(d.mediaId),
                  builder: (_, snap) => snap.data == null
                      ? const SizedBox.expand()
                      : InteractiveViewer(
                          maxScale: 6,
                          child: Center(child: Image(image: cache.original(snap.data!), fit: BoxFit.contain)),
                        ),
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
                        _Big(label: 'Score', value: '${d.rating.score.round()}'),
                        _Big(label: 'Settled', value: '${(d.rating.confidence * 100).round()}%'),
                        _Big(label: 'Record', value: '${d.wins}–${d.losses}'),
                      ],
                    ),
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
