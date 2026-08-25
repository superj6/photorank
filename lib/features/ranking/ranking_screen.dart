import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/dealer/photo_state.dart';
import '../shell/shell_screen.dart';
import '../widgets/photo_tile.dart';

enum _Filter { top10, top100, all, settling, unseen }

/// The ranked grid: the useful output.
class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  _Filter _filter = _Filter.top100;

  List<PhotoState> _apply(List<PhotoState> all) => switch (_filter) {
        _Filter.top10 => all.where((p) => p.observations > 0).take(10).toList(),
        _Filter.top100 => all.where((p) => p.observations > 0).take(100).toList(),
        _Filter.all => all,
        _Filter.settling => all.where((p) => p.observations > 0 && p.rating.confidence < 0.5).toList(),
        _Filter.unseen => all.where((p) => p.observations == 0).toList(),
      };

  @override
  Widget build(BuildContext context) {
    final ranking = ref.watch(rankingProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your ranking'),
        actions: [
          IconButton(
            tooltip: 'Moments',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => context.push('/moments'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(switch (f) {
                        _Filter.top10 => 'Top 10',
                        _Filter.top100 => 'Top 100',
                        _Filter.all => 'All',
                        _Filter.settling => 'Still settling',
                        _Filter.unseen => 'Not yet seen',
                      }),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: ranking.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final items = _apply(all);
          if (items.isEmpty) {
            return const Center(
              child: Text('Nothing here yet — play a hand.', style: TextStyle(color: Colors.white60)),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 0.8),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final p = items[i];
              final rank = all.indexOf(p) + 1;
              return PhotoTile(
                mediaId: p.mediaId,
                size: ThumbCacheSizes.grid,
                borderRadius: 12,
                onTap: () => context.openPhoto(p.id),
                child: Stack(
                  children: [
                    if (p.observations > 0)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Pill('#$rank', color: rank <= 10 ? AppTheme.accent : null),
                      ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: _Confidence(score: p.rating.score, confidence: p.rating.confidence),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Confidence extends StatelessWidget {
  const _Confidence({required this.score, required this.confidence});
  final double score;
  final double confidence;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle)),
          CircularProgressIndicator(
            value: confidence,
            strokeWidth: 2.5,
            backgroundColor: Colors.white12,
            color: AppTheme.accent,
          ),
          Center(
            child: Text('${score.round()}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
