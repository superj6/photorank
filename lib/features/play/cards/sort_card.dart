import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../widgets/photo_tile.dart';

/// Three photos. Tap them in order of preference, best first.
class SortCard extends StatefulWidget {
  const SortCard({super.key, required this.ids, required this.mediaOf, required this.onSorted});

  final List<int> ids;
  final String? Function(int) mediaOf;
  final ValueChanged<List<int>> onSorted;

  @override
  State<SortCard> createState() => _SortCardState();
}

class _SortCardState extends State<SortCard> {
  final _order = <int>[];

  void _tap(int id) {
    if (_order.contains(id)) {
      setState(() => _order.remove(id));
      return;
    }
    setState(() => _order.add(id));
    if (_order.length == widget.ids.length - 1) {
      // Last one is implied.
      final last = widget.ids.firstWhere((x) => !_order.contains(x));
      final full = [..._order, last];
      Future<void>.delayed(const Duration(milliseconds: 220), () => widget.onSorted(full));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            _order.isEmpty ? 'Tap your favourite first' : 'Now your next favourite',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        for (final id in widget.ids) ...[
          Expanded(
            child: PhotoTile(
              mediaId: widget.mediaOf(id),
              borderRadius: 16,
              onTap: () => _tap(id),
              child: _order.contains(id)
                  ? Container(
                      color: AppTheme.accent.withValues(alpha: 0.25),
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.all(10),
                      child: CircleAvatar(
                        backgroundColor: AppTheme.accent,
                        child: Text('${_order.indexOf(id) + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    )
                  : null,
            ),
          ),
          if (id != widget.ids.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
