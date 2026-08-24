import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../widgets/photo_tile.dart';

/// One photo. Swipe right = feeling it, left = not feeling it.
class VibeCard extends StatefulWidget {
  const VibeCard({super.key, required this.mediaId, required this.onAnswer});

  final String? mediaId;
  final ValueChanged<bool> onAnswer;

  @override
  State<VibeCard> createState() => _VibeCardState();
}

class _VibeCardState extends State<VibeCard> {
  bool _gone = false;

  void _answer(bool feelingIt) {
    // Dismissible must leave the tree the same frame it is dismissed.
    setState(() => _gone = true);
    widget.onAnswer(feelingIt);
  }

  @override
  Widget build(BuildContext context) {
    final mediaId = widget.mediaId;
    final onAnswer = _answer;
    return Column(
      children: [
        Expanded(
          child: _gone
              ? const SizedBox.expand()
              : Dismissible(
                  key: ValueKey(mediaId),
                  direction: DismissDirection.horizontal,
                  dismissThresholds: const {
                    DismissDirection.startToEnd: 0.3,
                    DismissDirection.endToStart: 0.3,
                  },
                  onDismissed: (d) => onAnswer(d == DismissDirection.startToEnd),
                  background: _Hint(Icons.favorite, 'Feeling it', Alignment.centerLeft, AppTheme.accent),
                  secondaryBackground:
                      _Hint(Icons.remove_circle_outline, 'Not feeling it', Alignment.centerRight, Colors.blueGrey),
                  child: PhotoTile(mediaId: mediaId),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Button(
                icon: Icons.remove_circle_outline,
                label: 'Not feeling it',
                color: Colors.blueGrey,
                onTap: () => onAnswer(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Button(
                icon: Icons.favorite,
                label: 'Feeling it',
                color: AppTheme.accent,
                onTap: () => onAnswer(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.icon, this.label, this.align, this.color);
  final IconData icon;
  final String label;
  final Alignment align;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: color),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.18),
        foregroundColor: color,
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
