import 'package:flutter/material.dart';

import '../../widgets/photo_tile.dart';

/// Two photos stacked; tap the one you like more. The winner pops, the loser
/// fades, then the hand moves on. Also used for Challenger.
class DuelCard extends StatefulWidget {
  const DuelCard({
    super.key,
    required this.topId,
    required this.bottomId,
    required this.mediaOf,
    required this.onPick,
    this.fitOf,
    this.challenger = false,
    this.championId,
    this.hint,
  });

  final int topId;
  final int bottomId;
  final String? Function(int) mediaOf;
  final BoxFit Function(int)? fitOf;
  final ValueChanged<int> onPick;
  final bool challenger;

  /// In a Challenger card, the photo that is currently in the Top 50.
  final int? championId;
  final Widget? hint;

  @override
  State<DuelCard> createState() => _DuelCardState();
}

class _DuelCardState extends State<DuelCard> {
  int? _picked;

  void _pick(int id) {
    if (_picked != null) return;
    setState(() => _picked = id);
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) widget.onPick(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(int id, {bool top = false}) {
      final picked = _picked == id;
      final lost = _picked != null && !picked;
      return Expanded(
        flex: picked ? 11 : lost ? 8 : 10,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: lost ? 0.25 : 1,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            scale: picked ? 1.02 : 1,
            child: PhotoTile(
              mediaId: widget.mediaOf(id),
              fit: widget.fitOf?.call(id) ?? BoxFit.cover,
              onTap: () => _pick(id),
              child: Stack(children: [
                if (widget.challenger && id == (widget.championId ?? widget.bottomId))
                  const Positioned(left: 10, top: 10, child: Pill('Top 50', icon: Icons.emoji_events, color: Color(0xFFB8860B))),
                if (top && widget.hint != null) Positioned(left: 0, right: 0, top: 10, child: Center(child: widget.hint)),
                if (picked)
                  const Positioned(right: 10, bottom: 10, child: Pill('Winner', icon: Icons.check_rounded, color: Color(0xFFFF6B4A))),
              ]),
            ),
          ),
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      child: Column(children: [tile(widget.topId, top: true), const SizedBox(height: 8), tile(widget.bottomId)]),
    );
  }
}
