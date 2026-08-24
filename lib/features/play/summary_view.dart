import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../shell/shell_screen.dart';
import '../widgets/photo_tile.dart';
import 'session_controller.dart';

/// End-of-hand reveal: what moved, what entered the Top 10, how sorted the
/// library is now.
class SummaryView extends ConsumerWidget {
  const SummaryView({super.key, required this.summary, required this.onAgain});

  final SessionSummary summary;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = (summary.sortedFraction * 100).round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text('Nice hand.', style: Theme.of(context).textTheme.headlineMedium)
            .animate()
            .fadeIn()
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 4),
        Text('${summary.answered} of ${summary.cards} cards answered',
            style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 24),
        _Stat(
          label: 'Library sorted',
          value: '$pct%',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: summary.sortedFraction,
              minHeight: 8,
              backgroundColor: Colors.white10,
              color: AppTheme.accent,
            ),
          ),
        ).animate(delay: 150.ms).fadeIn(),
        if (summary.newTopTen.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            summary.newTopTen.length == 1 ? 'New in your Top 10' : '${summary.newTopTen.length} new in your Top 10',
            style: Theme.of(context).textTheme.titleLarge,
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 10),
          _Strip(ids: summary.newTopTen).animate(delay: 350.ms).fadeIn().scale(begin: const Offset(0.95, 0.95)),
        ],
        if (summary.risers.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Biggest climbers', style: Theme.of(context).textTheme.titleLarge).animate(delay: 450.ms).fadeIn(),
          const SizedBox(height: 10),
          _Strip(
            ids: summary.risers.map((r) => r.$1).toList(),
            labels: summary.risers.map((r) => '+${r.$2.toStringAsFixed(0)}').toList(),
          ).animate(delay: 500.ms).fadeIn(),
        ],
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: onAgain,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Deal another hand'),
        ).animate(delay: 600.ms).fadeIn(),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.child});
  final String label;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Strip extends ConsumerWidget {
  const _Strip({required this.ids, this.labels});
  final List<int> ids;
  final List<String>? labels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ids.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final row = ref.watch(photoRowProvider(ids[i])).value;
          return SizedBox(
            width: 110,
            child: PhotoTile(
              mediaId: row?.mediaId,
              size: ThumbCacheSizes.grid,
              borderRadius: 14,
              onTap: () => context.openPhoto(ids[i]),
              child: labels == null
                  ? null
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(padding: const EdgeInsets.all(6), child: Pill(labels![i], color: AppTheme.accent)),
                    ),
            ),
          );
        },
      ),
    );
  }
}
