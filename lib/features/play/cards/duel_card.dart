import 'package:flutter/material.dart';

import '../../widgets/photo_tile.dart';

/// Two photos stacked; tap the one you like more. Also used for Challenger,
/// where the second photo is flagged as one of the current Top 50.
class DuelCard extends StatelessWidget {
  const DuelCard({
    super.key,
    required this.topId,
    required this.bottomId,
    required this.mediaOf,
    required this.onPick,
    this.challenger = false,
  });

  final int topId;
  final int bottomId;
  final String? Function(int) mediaOf;
  final ValueChanged<int> onPick;
  final bool challenger;

  @override
  Widget build(BuildContext context) {
    Widget tile(int id, {bool top = false}) => Expanded(
          child: PhotoTile(
            mediaId: mediaOf(id),
            onTap: () => onPick(id),
            child: challenger && !top
                ? const Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Pill('Top 50', icon: Icons.emoji_events, color: Color(0xFFB8860B)),
                    ),
                  )
                : null,
          ),
        );
    return Column(
      children: [
        tile(topId, top: true),
        const SizedBox(height: 8),
        tile(bottomId),
      ],
    );
  }
}
