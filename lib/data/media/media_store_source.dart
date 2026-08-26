import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../repo/photo_repo.dart';
import 'library_scanner.dart';
import 'photo_source.dart';

/// Android / iOS: the system media library via photo_manager.
class MediaStoreSource extends PhotoSource {
  MediaStoreSource(PhotoRepo repo) : _scanner = LibraryScanner(repo);

  final LibraryScanner _scanner;

  @override
  bool get needsPermission => true;

  @override
  bool get usesFolders => false;

  @override
  Future<bool> requestAccess() async => (await _scanner.requestPermission()).hasAccess;

  @override
  Future<List<AlbumInfo>> albums() => _scanner.albums();

  @override
  Stream<ScanProgress> scan(ScanScope scope, {bool markMissing = false}) => _scanner.scan(scope, markMissing: markMissing);

  /// An entity shell by id is enough for the image provider: it asks the
  /// platform for the thumbnail by id, so no async lookup is needed.
  AssetEntity _shell(String id) => AssetEntity(id: id, typeInt: 1, width: 0, height: 0);

  @override
  ImageProvider thumb(String mediaId, {required ThumbnailSize size}) =>
      AssetEntityImageProvider(_shell(mediaId), isOriginal: false, thumbnailSize: size);

  @override
  ImageProvider original(String mediaId) => AssetEntityImageProvider(_shell(mediaId), isOriginal: true);

  @override
  Future<Uint8List?> originalBytes(String mediaId) async => (await AssetEntity.fromId(mediaId))?.originBytes;
}
