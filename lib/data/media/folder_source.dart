import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart' show ThumbnailSize;

import '../repo/photo_repo.dart';
import 'photo_source.dart';
import 'scanned_asset.dart';

/// Desktop: photos are files in folders you choose. Media id = absolute path.
/// Capture dates come from EXIF headers; thumbnails are generated on demand
/// and cached on disk.
class FolderSource extends PhotoSource {
  FolderSource(this.repo, {required this.cacheDir});

  final PhotoRepo repo;
  final Directory cacheDir;

  static const extensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.tif', '.tiff'};

  @override
  bool get needsPermission => false;

  @override
  bool get usesFolders => true;

  @override
  Future<bool> requestAccess() async => true;

  @override
  Future<List<AlbumInfo>> albums() async => const [];

  @override
  Stream<ScanProgress> scan(ScanScope scope, {bool markMissing = false}) async* {
    final folders = scope.folders ?? const <String>[];
    final files = <File>[];
    for (final f in folders) {
      final dir = Directory(f);
      if (!await dir.exists()) continue;
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (e is File && extensions.contains(p.extension(e.path).toLowerCase())) files.add(e);
      }
    }
    yield ScanProgress(indexed: 0, total: files.length);
    final seen = <String>{};
    var indexed = 0;
    const chunk = 64;
    for (var i = 0; i < files.length; i += chunk) {
      final paths = files.sublist(i, (i + chunk).clamp(0, files.length)).map((f) => f.path).toList();
      final batch = await compute(_readHeaders, paths);
      final kept = [
        for (final a in batch)
          if (scope.since == null || (a.takenAt != null && !a.takenAt!.isBefore(scope.since!))) a,
      ];
      seen.addAll(batch.map((a) => a.mediaId));
      await repo.upsertAssets(kept);
      indexed += paths.length;
      yield ScanProgress(indexed: indexed, total: files.length);
    }
    if (markMissing) await repo.markMissingExcept(seen);
    await repo.clusterNewPhotos();
    yield ScanProgress(indexed: indexed, total: files.length, done: true);
  }

  @override
  ImageProvider thumb(String mediaId, {required ThumbnailSize size}) =>
      FolderThumbProvider(mediaId, size: size.width > size.height ? size.width : size.height, cacheDir: cacheDir);

  @override
  ImageProvider original(String mediaId) => FileImage(File(mediaId));

  @override
  Future<Uint8List?> originalBytes(String mediaId) async {
    final f = File(mediaId);
    return await f.exists() ? f.readAsBytes() : null;
  }
}

/// Reads EXIF date + pixel size from the first part of each file (isolate).
List<ScannedAsset> _readHeaders(List<String> paths) {
  final out = <ScannedAsset>[];
  for (final path in paths) {
    try {
      final file = File(path);
      final stat = file.statSync();
      final raf = file.openSync();
      final head = raf.readSync(256 * 1024);
      raf.closeSync();
      out.add(readHeader(path, head, modifiedAt: stat.modified));
    } catch (_) {
      // unreadable file: skip
    }
  }
  return out;
}

/// Pure header parse (unit-tested): EXIF DateTimeOriginal, else file mtime.
ScannedAsset readHeader(String path, Uint8List head, {DateTime? modifiedAt}) {
  DateTime? taken;
  var width = 0, height = 0;
  try {
    var orientation = 1;
    final exif = img.decodeJpgExif(head); // null for non-JPEG or no EXIF
    if (exif != null) {
      final raw = exif.exifIfd['DateTimeOriginal']?.toString() ?? exif.imageIfd['DateTime']?.toString();
      if (raw != null) {
        final m = RegExp(r'^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})').firstMatch(raw);
        if (m != null) {
          taken = DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!), int.parse(m[4]!), int.parse(m[5]!), int.parse(m[6]!));
        }
      }
      orientation = exif.imageIfd['Orientation']?.toInt() ?? 1;
    }
    final info = img.findDecoderForData(head)?.startDecode(head);
    if (info != null) {
      width = info.width;
      height = info.height;
      if (orientation >= 5) {
        final t = width;
        width = height;
        height = t;
      }
    }
  } catch (_) {}
  return ScannedAsset(
    mediaId: path,
    albumId: p.dirname(path),
    takenAt: taken ?? modifiedAt,
    modifiedAt: modifiedAt,
    width: width,
    height: height,
  );
}

/// Generates (once) and serves a JPEG thumbnail for a file, cached on disk.
class FolderThumbProvider extends ImageProvider<FolderThumbProvider> {
  const FolderThumbProvider(this.path, {required this.size, required this.cacheDir});

  final String path;
  final int size;
  final Directory cacheDir;

  static final _inFlight = <String, Future<Uint8List?>>{};
  static int _active = 0;
  static const _maxActive = 3;
  static final _waiters = <Completer<void>>[];

  File get _cacheFile => File(p.join(cacheDir.path, 'thumbs', '${md5.convert(utf8.encode(path)).toString()}_$size.jpg'));

  @override
  Future<FolderThumbProvider> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(FolderThumbProvider key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _codec(decode), scale: 1, debugLabel: path);

  Future<ui.Codec> _codec(ImageDecoderCallback decode) async {
    final bytes = await _bytes();
    if (bytes == null) throw StateError('cannot thumbnail $path');
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  Future<Uint8List?> _bytes() {
    final key = _cacheFile.path;
    return _inFlight.putIfAbsent(key, () async {
      try {
        if (await _cacheFile.exists()) return await _cacheFile.readAsBytes();
        await _acquire();
        try {
          final out = await compute(_generate, (path, size));
          if (out != null) {
            await _cacheFile.parent.create(recursive: true);
            await _cacheFile.writeAsBytes(out, flush: true);
          }
          return out;
        } finally {
          _release();
        }
      } finally {
        _inFlight.remove(key);
      }
    });
  }

  static Future<void> _acquire() async {
    if (_active < _maxActive) {
      _active++;
      return;
    }
    final c = Completer<void>();
    _waiters.add(c);
    await c.future;
    _active++;
  }

  static void _release() {
    _active--;
    if (_waiters.isNotEmpty) _waiters.removeAt(0).complete();
  }

  @override
  bool operator ==(Object other) => other is FolderThumbProvider && other.path == path && other.size == size;

  @override
  int get hashCode => Object.hash(path, size);
}

/// Decode, apply orientation, shrink so the long edge is [size], JPEG-encode.
Uint8List? _generate((String, int) arg) {
  final (path, size) = arg;
  try {
    var image = img.decodeImage(File(path).readAsBytesSync());
    if (image == null) return null;
    image = img.bakeOrientation(image);
    final long = image.width > image.height ? image.width : image.height;
    if (long > size) {
      image = image.width >= image.height
          ? img.copyResize(image, width: size, interpolation: img.Interpolation.average)
          : img.copyResize(image, height: size, interpolation: img.Interpolation.average);
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 80));
  } catch (_) {
    return null;
  }
}
