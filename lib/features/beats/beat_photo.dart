import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../widgets/photo_tile.dart';

/// A photo by DB id (beats reference photos outside the current hand).
class BeatPhoto extends ConsumerWidget {
  const BeatPhoto(this.photoId, {super.key, this.fit = BoxFit.cover, this.borderRadius = 20, this.size, this.child, this.onTap});

  final int photoId;
  final BoxFit fit;
  final double borderRadius;
  final dynamic size;
  final Widget? child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = ref.watch(photoRowProvider(photoId)).value;
    return PhotoTile(
      mediaId: row?.mediaId,
      fit: fit,
      borderRadius: borderRadius,
      size: size ?? ThumbCacheSizes.card,
      onTap: onTap,
      child: child,
    );
  }
}
