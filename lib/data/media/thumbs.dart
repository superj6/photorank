import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

/// Resolves DB media ids to photo_manager entities with a small LRU so the
/// play/browse screens never re-query MediaStore for the same photo.
class ThumbCache {
  ThumbCache({this.capacity = 512});

  final int capacity;
  final _entities = <String, AssetEntity>{};

  Future<AssetEntity?> entity(String mediaId) async {
    final hit = _entities.remove(mediaId);
    if (hit != null) {
      _entities[mediaId] = hit;
      return hit;
    }
    final e = await AssetEntity.fromId(mediaId);
    if (e != null) {
      _entities[mediaId] = e;
      if (_entities.length > capacity) _entities.remove(_entities.keys.first);
    }
    return e;
  }

  static const thumb = ThumbnailSize(720, 720);
  static const grid = ThumbnailSize.square(320);

  ImageProvider provider(AssetEntity e, {ThumbnailSize size = thumb}) =>
      AssetEntityImageProvider(e, isOriginal: false, thumbnailSize: size);

  ImageProvider original(AssetEntity e) => AssetEntityImageProvider(e, isOriginal: true);

  /// Warm the image cache for upcoming cards.
  Future<void> precache(BuildContext context, Iterable<String> mediaIds,
      {ThumbnailSize size = thumb}) async {
    for (final id in mediaIds) {
      final e = await entity(id);
      if (e != null && context.mounted) {
        await precacheImage(provider(e, size: size), context);
      }
    }
  }
}
