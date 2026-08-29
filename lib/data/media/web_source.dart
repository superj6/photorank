import 'dart:async';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart' show sha1;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart' show ThumbnailSize;

import '../db/database.dart';
import '../repo/photo_repo.dart';
import 'photo_source.dart';
import 'scanned_asset.dart';
import 'web/image_codec_stub.dart' if (dart.library.js_interop) 'web/image_codec_web.dart';

/// Web / PWA: there is no camera roll to read, so photos are *imported*
/// through the browser's file picker, downscaled by the browser and kept in
/// the app's own database (IndexedDB) — nothing is uploaded. Media id =
/// a content hash, so re-importing the same photo is a no-op.
class WebSource extends PhotoSource {
  WebSource(this.repo, this.db);

  final PhotoRepo repo;
  final AppDatabase db;
  final _bytesCache = <String, Uint8List>{};

  @override
  bool get needsPermission => false;

  @override
  bool get usesFolders => false;

  /// Photos are added explicitly rather than scanned.
  bool get importsPhotos => true;

  @override
  Future<bool> requestAccess() async => true;

  @override
  Future<List<AlbumInfo>> albums() async => const [];

  /// Nothing to sync: everything indexed is already in the database.
  @override
  Stream<ScanProgress> scan(ScanScope scope, {bool markMissing = false}) async* {
    final n = await repo.count();
    yield ScanProgress(indexed: n, total: n, done: true);
  }

  /// Imports picked files: decode + downscale in the browser, read the EXIF
  /// capture date, store. Yields progress; [ImportResult] tells what happened.
  Stream<ImportProgress> import(List<({String name, Uint8List bytes, DateTime? modified})> files) async* {
    var done = 0, added = 0, skipped = 0;
    for (final f in files) {
      try {
        final id = _hash(f.bytes);
        if (await repo.byMediaId(id) != null) {
          skipped++;
        } else {
          final scaled = await downscaleToJpeg(f.bytes);
          if (scaled == null) {
            skipped++;
          } else {
            final takenAt = _exifDate(f.bytes) ?? f.modified;
            await db.into(db.webImages).insertOnConflictUpdate(WebImagesCompanion.insert(mediaId: id, bytes: scaled.bytes, width: scaled.width, height: scaled.height));
            await repo.upsertAssets([ScannedAsset(mediaId: id, takenAt: takenAt, modifiedAt: f.modified, width: scaled.width, height: scaled.height)]);
            added++;
          }
        }
      } catch (e) {
        debugPrint('import failed for ${f.name}: $e');
        skipped++;
      }
      done++;
      yield ImportProgress(done: done, total: files.length, added: added, skipped: skipped);
    }
  }

  /// Removes an imported photo and its bytes (its rating history stays).
  Future<void> remove(String mediaId) async {
    await (db.delete(db.webImages)..where((t) => t.mediaId.equals(mediaId))).go();
    await repo.markMissingByMediaId(mediaId);
    _bytesCache.remove(mediaId);
  }

  /// Content hash so re-importing the same photo is a no-op.
  static String _hash(Uint8List bytes) => 'web:${sha1.convert(bytes)}';

  static DateTime? _exifDate(Uint8List bytes) {
    try {
      final exif = img.decodeJpgExif(bytes);
      final raw = exif?.exifIfd['DateTimeOriginal']?.toString() ?? exif?.imageIfd['DateTime']?.toString();
      if (raw == null) return null;
      final m = RegExp(r'^(\d{4}):(\d{2}):(\d{2})[ T](\d{2}):(\d{2}):(\d{2})').firstMatch(raw);
      if (m == null) return null;
      return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!), int.parse(m[4]!), int.parse(m[5]!), int.parse(m[6]!));
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _bytes(String mediaId) async {
    final cached = _bytesCache[mediaId];
    if (cached != null) return cached;
    final row = await (db.select(db.webImages)..where((t) => t.mediaId.equals(mediaId))).getSingleOrNull();
    if (row == null) return null;
    if (_bytesCache.length > 64) _bytesCache.remove(_bytesCache.keys.first);
    return _bytesCache[mediaId] = row.bytes;
  }

  @override
  ImageProvider thumb(String mediaId, {required ThumbnailSize size}) => WebImageProvider(this, mediaId, size: size.width > size.height ? size.width : size.height);

  @override
  ImageProvider original(String mediaId) => WebImageProvider(this, mediaId, size: 0);

  @override
  Future<Uint8List?> originalBytes(String mediaId) => _bytes(mediaId);
}

class ImportProgress {
  const ImportProgress({required this.done, required this.total, required this.added, required this.skipped});
  final int done;
  final int total;
  final int added;
  final int skipped;
}

/// Decodes a stored photo at the size it is shown at.
class WebImageProvider extends ImageProvider<WebImageProvider> {
  const WebImageProvider(this.source, this.mediaId, {required this.size});

  final WebSource source;
  final String mediaId;

  /// Long-edge target in logical pixels; 0 = stored size.
  final int size;

  @override
  Future<WebImageProvider> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(WebImageProvider key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _codec(), scale: 1, debugLabel: mediaId);

  Future<ui.Codec> _codec() async {
    final bytes = await source._bytes(mediaId);
    if (bytes == null) throw StateError('photo $mediaId is not in the library');
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    if (size <= 0) return ui.instantiateImageCodecWithSize(buffer);
    return ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (w, h) => w >= h ? ui.TargetImageSize(width: size) : ui.TargetImageSize(height: size),
    );
  }

  @override
  bool operator ==(Object other) => other is WebImageProvider && other.mediaId == mediaId && other.size == size;

  @override
  int get hashCode => Object.hash(mediaId, size);
}
