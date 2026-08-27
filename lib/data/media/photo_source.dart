
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart' show ThumbnailSize;

import 'library_scanner.dart' show AlbumInfo, ScanProgress, ScanScope;

export 'library_scanner.dart' show AlbumInfo, ScanProgress, ScanScope;

/// Where photos come from. Mobile reads the system media library; desktop
/// reads folders. Everything above this layer only sees media ids.
abstract class PhotoSource {
  /// Whether the platform needs an explicit permission step before scanning.
  bool get needsPermission;

  /// Whether scope is expressed as folders (desktop) rather than albums/dates.
  bool get usesFolders;

  /// Returns true when the library can be read.
  Future<bool> requestAccess();

  Future<List<AlbumInfo>> albums();

  Stream<ScanProgress> scan(ScanScope scope, {bool markMissing = false});

  /// Synchronous: the image widget starts loading immediately.
  ImageProvider thumb(String mediaId, {required ThumbnailSize size});

  ImageProvider original(String mediaId);

  Future<Uint8List?> originalBytes(String mediaId);

  /// Warms the image cache for photos about to be shown. Best-effort: a photo
  /// deleted or moved since the scan must not break the hand it appears in
  /// (the tile itself falls back to a "missing" placeholder).
  Future<void> precache(BuildContext context, Iterable<String> mediaIds, {required ThumbnailSize size}) async {
    for (final id in mediaIds) {
      if (!context.mounted) return;
      await precacheImage(thumb(id, size: size), context, onError: (e, _) {
        debugPrint('precache skipped $id: $e');
      });
    }
  }
}
