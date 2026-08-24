import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../widgets/photo_tile.dart';

/// One photo, five stars. Double-tap the photo for 5★.
class RateCard extends StatefulWidget {
  const RateCard({super.key, required this.mediaId, required this.onRate});

  final String? mediaId;
  final ValueChanged<int> onRate;

  @override
  State<RateCard> createState() => _RateCardState();
}

class _RateCardState extends State<RateCard> {
  int _hover = 0;

  void _pick(int stars) {
    setState(() => _hover = stars);
    Future<void>.delayed(const Duration(milliseconds: 160), () => widget.onRate(stars));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PhotoTile(mediaId: widget.mediaId, onDoubleTap: () => _pick(5)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var s = 1; s <= 5; s++)
                IconButton(
                  iconSize: 44,
                  onPressed: () => _pick(s),
                  icon: Icon(
                    s <= _hover ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: s <= _hover ? AppTheme.accent : Colors.white70,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
