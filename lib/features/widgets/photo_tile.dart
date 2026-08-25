import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

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
  AssetEntity? _entity;
  String? _for;

  void _resolve() {
    final id = widget.mediaId;
    _for = id;
    if (id == null) {
      _entity = null;
      return;
    }
    final cache = ref.read(thumbCacheProvider);
    _entity = cache.cached(id);
    if (_entity == null) {
      cache.entity(id).then((e) {
        if (mounted && _for == id) setState(() => _entity = e);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(PhotoTile old) {
    super.didUpdateWidget(old);
    if (old.mediaId != widget.mediaId) _resolve();
  }

  @override
  Widget build(BuildContext context) {
    final cache = ref.watch(thumbCacheProvider);
    final id = widget.mediaId;
    final e = _entity;
    final Widget image = id == null
        ? const _Missing()
        : e == null
            ? const _Placeholder()
            : Image(
                image: cache.provider(e, size: widget.size),
                fit: widget.fit,
                gaplessPlayback: true,
                frameBuilder: (_, child, frame, wasSync) => wasSync
                    ? child
                    : AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: const Duration(milliseconds: 180), child: child),
                errorBuilder: (_, _, _) => const _Missing(),
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

class _Placeholder extends StatelessWidget {
  const _Placeholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(color: AppTheme.surface);
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
        final cache = ref.watch(thumbCacheProvider);
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: FutureBuilder<AssetEntity?>(
            future: cache.entity(mediaId),
            builder: (context, snap) {
              final e = snap.data;
              if (e == null) return const SizedBox.expand();
              return InteractiveViewer(
                maxScale: 6,
                child: Center(child: Image(image: cache.original(e), fit: BoxFit.contain)),
              );
            },
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
