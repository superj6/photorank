import 'package:flutter/material.dart';

import '../../widgets/photo_tile.dart';

/// A burst of near-identical shots. Tap the best one.
class BurstCard extends StatelessWidget {
  const BurstCard({super.key, required this.ids, required this.mediaOf, required this.onPick});

  final List<int> ids;
  final String? Function(int) mediaOf;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final columns = ids.length <= 4 ? 2 : 3;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Best of the burst?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: columns == 2 ? 0.8 : 0.72,
            ),
            itemCount: ids.length,
            itemBuilder: (_, i) => PhotoTile(
              mediaId: mediaOf(ids[i]),
              size: ThumbCacheSizes.grid,
              borderRadius: 14,
              onTap: () => onPick(ids[i]),
            ),
          ),
        ),
      ],
    );
  }
}
