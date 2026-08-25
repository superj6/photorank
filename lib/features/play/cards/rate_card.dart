import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../widgets/photo_tile.dart';

/// One photo, five stars. Double-tap the photo for 5★.
class RateCard extends StatefulWidget {
  const RateCard({super.key, required this.mediaId, required this.onRate, this.fit = BoxFit.cover, this.hint});

  final String? mediaId;
  final ValueChanged<int> onRate;
  final BoxFit fit;
  final Widget? hint;

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
          child: PhotoTile(
            mediaId: widget.mediaId,
            fit: widget.fit,
            onDoubleTap: () => _pick(5),
            onTap: widget.mediaId == null ? null : () => PhotoPeek.show(context, widget.mediaId!),
            child: widget.hint == null ? null : Align(alignment: Alignment.topCenter, child: Padding(padding: const EdgeInsets.only(top: 10), child: widget.hint)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var s = 1; s <= 5; s++)
                AnimatedScale(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutBack,
                  scale: s <= _hover ? 1.25 : 1,
                  child: IconButton(
                    iconSize: 44,
                    onPressed: () => _pick(s),
                    icon: Icon(
                      s <= _hover ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: s <= _hover ? AppTheme.accent : Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
