import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

/// Pushes the ranking back into the system gallery.
///
/// - [markFavorites]: sets the OS favourite flag (Google Photos / Gallery
///   show a heart). Nothing is copied. Android 11+ shows a one-time consent.
/// - [exportAlbum]: creates an album with copies of the files (Android) or
///   references (iOS). Explicit, because it duplicates files on Android.
class FavoritesSync {
  FavoritesSync._();

  static const albumName = 'PhotoRank Favorites';

  static Future<int> markFavorites(Iterable<String> mediaIds, {bool favorite = true}) async {
    var n = 0;
    for (final id in mediaIds) {
      final e = await AssetEntity.fromId(id);
      if (e == null) continue;
      try {
        if (Platform.isAndroid) {
          await PhotoManager.editor.android.favoriteAsset(entity: e, favorite: favorite);
        } else if (Platform.isIOS || Platform.isMacOS) {
          await PhotoManager.editor.darwin.favoriteAsset(entity: e, favorite: favorite);
        } else {
          continue;
        }
        n++;
      } catch (_) {
        // Unsupported on this device/OS version or user declined; keep going.
      }
    }
    return n;
  }

  static Future<int> exportAlbum(Iterable<String> mediaIds) async {
    var n = 0;
    if (Platform.isAndroid) {
      // Android has no "create album" — an album is a folder. Save copies there.
      for (final id in mediaIds) {
        final e = await AssetEntity.fromId(id);
        final file = await e?.file;
        if (e == null || file == null) continue;
        try {
          await PhotoManager.editor.saveImageWithPath(
            file.path,
            title: e.title ?? 'photorank_$id.jpg',
            relativePath: 'Pictures/$albumName',
          );
          n++;
        } catch (_) {}
      }
      return n;
    }
    AssetPathEntity? album;
    for (final p in await PhotoManager.getAssetPathList(type: RequestType.image)) {
      if (p.name == albumName) album = p;
    }
    album ??= await PhotoManager.editor.darwin.createAlbum(albumName);
    if (album == null) return 0;
    for (final id in mediaIds) {
      final e = await AssetEntity.fromId(id);
      if (e == null) continue;
      try {
        await PhotoManager.editor.copyAssetToPath(asset: e, pathEntity: album);
        n++;
      } catch (_) {}
    }
    return n;
  }
}
