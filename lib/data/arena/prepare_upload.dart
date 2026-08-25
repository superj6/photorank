import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// What leaves the phone for Arena: a downsized JPEG with no metadata.
class PreparedUpload {
  const PreparedUpload({required this.bytes, required this.width, required this.height});
  final Uint8List bytes;
  final int width;
  final int height;
  String get contentType => 'image/jpeg';
}

/// Decodes [source], resizes so the long edge is at most [maxEdge], applies
/// the EXIF orientation, drops every other piece of metadata (GPS, camera,
/// timestamps) and re-encodes as JPEG at [quality].
///
/// Pure Dart: run it in an isolate (`compute`) from the UI.
PreparedUpload? prepareUpload(Uint8List source, {int maxEdge = 1280, int quality = 82}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(source);
  } catch (_) {
    return null; // not an image (a decoder may throw on garbage)
  }
  if (decoded == null) return null;
  decoded = img.bakeOrientation(decoded); // applies + clears EXIF orientation
  final long = decoded.width > decoded.height ? decoded.width : decoded.height;
  if (long > maxEdge) {
    decoded = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: maxEdge, interpolation: img.Interpolation.average)
        : img.copyResize(decoded, height: maxEdge, interpolation: img.Interpolation.average);
  }
  decoded.exif.clear();
  final bytes = img.encodeJpg(decoded, quality: quality);
  return PreparedUpload(bytes: Uint8List.fromList(bytes), width: decoded.width, height: decoded.height);
}
