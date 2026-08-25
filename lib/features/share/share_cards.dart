import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../beats/beat_photo.dart';
import '../widgets/photo_tile.dart';

/// Square 3×3 grid with the app mark — the classic "my top 9".
class TopNineCard extends StatelessWidget {
  const TopNineCard({super.key, required this.ids, this.title = 'My top 9'});

  final List<int> ids;
  final String title;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      title: title,
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final (i, id) in ids.take(9).indexed)
              BeatPhoto(id, borderRadius: 10, size: ThumbCacheSizes.grid, child: i == 0 ? const _Corner('#1') : null),
          ],
        ),
      ),
    );
  }
}

/// One photo, big, with a label such as "#1 of 2026".
class NumberOneCard extends StatelessWidget {
  const NumberOneCard({super.key, required this.photoId, required this.label});

  final int photoId;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      title: label,
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: BeatPhoto(photoId, borderRadius: 14, child: const _Corner('#1')),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topLeft,
        child: Padding(padding: const EdgeInsets.all(8), child: Pill(text, color: AppTheme.accent)),
      );
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(5)),
                child: const Icon(Icons.favorite, size: 11, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text('Ranked with PhotoRank', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
