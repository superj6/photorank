import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../widgets/photo_tile.dart';

/// A burst of near-identical shots. Tap the best one; it pops, the rest dim.
class BurstCard extends StatefulWidget {
  const BurstCard({super.key, required this.ids, required this.mediaOf, required this.onPick});

  final List<int> ids;
  final String? Function(int) mediaOf;
  final ValueChanged<int> onPick;

  @override
  State<BurstCard> createState() => _BurstCardState();
}

class _BurstCardState extends State<BurstCard> {
  int? _picked;

  void _pick(int id) {
    if (_picked != null) return;
    setState(() => _picked = id);
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (mounted) widget.onPick(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.ids.length <= 4 ? 2 : 3;
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
            itemCount: widget.ids.length,
            itemBuilder: (_, i) {
              final id = widget.ids[i];
              final picked = _picked == id;
              final lost = _picked != null && !picked;
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: lost ? 0.3 : 1,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  scale: picked ? 1.06 : 1,
                  child: PhotoTile(
                    mediaId: widget.mediaOf(id),
                    size: ThumbCacheSizes.grid,
                    borderRadius: 14,
                    onTap: () => _pick(id),
                    child: picked
                        ? Container(
                            decoration: BoxDecoration(border: Border.all(color: AppTheme.accent, width: 3), borderRadius: BorderRadius.circular(14)),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
