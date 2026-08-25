import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'arena_providers.dart';

/// A remote Arena photo by storage path. `fake://` paths (in-memory API)
/// render as a deterministic colour block so the UI is exercisable offline.
class ArenaImage extends ConsumerWidget {
  const ArenaImage(this.storagePath, {super.key, this.fit = BoxFit.cover, this.borderRadius = 16, this.onTap, this.onLongPress, this.child});

  final String storagePath;
  final BoxFit fit;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(arenaImageUrlProvider(storagePath)).value;
    Widget image;
    if (url == null) {
      image = const ColoredBox(color: AppTheme.surface);
    } else if (url.startsWith('fake://')) {
      final h = storagePath.hashCode;
      image = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [HSLColor.fromAHSL(1, (h % 360).toDouble(), 0.6, 0.55).toColor(), HSLColor.fromAHSL(1, ((h ~/ 7) % 360).toDouble(), 0.6, 0.35).toColor()],
          ),
        ),
        child: Center(child: Icon(Icons.photo_rounded, color: Colors.white.withValues(alpha: 0.5), size: 48)),
      );
    } else {
      image = Image.network(
        url,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (_, child, progress) => progress == null ? child : const ColoredBox(color: AppTheme.surface),
        errorBuilder: (_, _, _) => const ColoredBox(color: AppTheme.surface, child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.white24))),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(fit: StackFit.expand, children: [image, ?child]),
      ),
    );
  }
}
