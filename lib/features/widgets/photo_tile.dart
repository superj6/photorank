import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart' show ThumbnailSize;

import '../../app/providers.dart';
import '../../app/theme.dart';

/// A device photo by media id, with a soft fade-in. Long-press to peek at
/// full resolution when [peekable].
///
/// Holds one future per media id: rebuilding (animations, parents) must not
/// re-fetch and flash a placeholder.
class PhotoTile extends ConsumerStatefulWidget {
  const PhotoTile({
    super.key,
    required this.mediaId,
    this.fit = BoxFit.cover,
    this.size = ThumbCacheSizes.card,
    this.borderRadius = 20,
    this.peekable = true,
    this.onTap,
    this.onDoubleTap,
    this.child,
  });

  final String? mediaId;
  final BoxFit fit;
  final ThumbnailSize size;
  final double borderRadius;
  final bool peekable;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  /// Overlay content (badges, labels).
  final Widget? child;

  @override
  ConsumerState<PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends ConsumerState<PhotoTile> {
  static final _reported = <String>{};

  /// The file is gone since the last scan: take it out of play now, so the
  /// dealer stops offering it before the next rescan notices.
  void _reportMissing(String mediaId) {
    if (!_reported.add(mediaId)) return;
    ref.read(photoRepoProvider).markMissingByMediaId(mediaId);
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(photoSourceProvider);
    final id = widget.mediaId;
    final Widget image = id == null
        ? const _Missing()
        : Image(
            image: source.thumb(id, size: widget.size),
            fit: widget.fit,
            gaplessPlayback: true,
            frameBuilder: (_, child, frame, wasSync) => wasSync
                ? child
                : AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 180), child: child),
            errorBuilder: (_, _, _) {
              _reportMissing(id);
              return const _Missing();
            },
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.peekable && id != null ? () => PhotoPeek.show(context, id) : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: AppTheme.surface, child: image),
            ?widget.child,
          ],
        ),
      ),
    );
  }
}

class ThumbCacheSizes {
  static const card = ThumbnailSize(900, 900);
  static const grid = ThumbnailSize.square(360);
}

class _Missing extends StatelessWidget {
  const _Missing();
  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AppTheme.surface,
        child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.white24)),
      );
}

/// Full-resolution, pinch-to-zoom overlay.
class PhotoPeek {
  static Future<void> show(BuildContext context, String mediaId) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (context) => Consumer(builder: (context, ref, _) {
        final source = ref.watch(photoSourceProvider);
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            maxScale: 6,
            child: Center(child: Image(image: source.original(mediaId), fit: BoxFit.contain)),
          ),
        );
      }),
    );
  }
}

/// Small pill used for scores, ranks, and mode labels.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.icon, this.color});

  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? Colors.black).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 4)],
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}
