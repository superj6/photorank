import 'dart:typed_data';

/// Pixel dimensions read from an image file's header bytes.
///
/// The `image` package can report this, but only by starting a real decode
/// (~110 ms for a 4000x3000 JPEG). Indexing a library needs nothing but the
/// numbers, and every format below states them in its first few hundred
/// bytes, so this reads them directly.
class ImageSize {
  const ImageSize(this.width, this.height);
  final int width;
  final int height;

  @override
  String toString() => '${width}x$height';

  @override
  bool operator ==(Object other) => other is ImageSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Reads the pixel size of [bytes] (a file's leading bytes are enough).
/// Returns null for formats or truncations it cannot read.
ImageSize? imageSizeFromHeader(Uint8List bytes) {
  final d = ByteData.sublistView(bytes);
  if (bytes.length < 16) return null;

  // JPEG: walk the marker segments to a start-of-frame.
  if (bytes[0] == 0xFF && bytes[1] == 0xD8) return _jpeg(bytes, d);

  // PNG: IHDR is always the first chunk.
  if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
    if (bytes.length < 24) return null;
    return ImageSize(d.getUint32(16), d.getUint32(20));
  }

  // GIF: logical screen descriptor.
  if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
    return ImageSize(d.getUint16(6, Endian.little), d.getUint16(8, Endian.little));
  }

  // BMP: DIB header.
  if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
    if (bytes.length < 26) return null;
    return ImageSize(d.getInt32(18, Endian.little).abs(), d.getInt32(22, Endian.little).abs());
  }

  // WebP: RIFF container, one of three chunk layouts.
  if (bytes.length > 30 &&
      bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
      bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
    return _webp(bytes, d);
  }
  return null;
}

ImageSize? _jpeg(Uint8List bytes, ByteData d) {
  var i = 2;
  while (i + 3 < bytes.length) {
    if (bytes[i] != 0xFF) {
      i++; // resync past fill bytes / padding
      continue;
    }
    final marker = bytes[i + 1];
    // Standalone markers carry no length: padding, SOI/EOI, restart markers.
    if (marker == 0xFF || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD9)) {
      i += 2;
      continue;
    }
    if (i + 3 >= bytes.length) return null;
    final length = d.getUint16(i + 2);
    if (length < 2) return null;
    // Start-of-frame markers hold the dimensions; C4/C8/CC are tables, not frames.
    final isFrame = (marker >= 0xC0 && marker <= 0xCF) && marker != 0xC4 && marker != 0xC8 && marker != 0xCC;
    if (isFrame) {
      if (i + 9 > bytes.length) return null;
      return ImageSize(d.getUint16(i + 7), d.getUint16(i + 5));
    }
    if (marker == 0xDA) return null; // scan data: no frame header found
    i += 2 + length;
  }
  return null;
}

ImageSize? _webp(Uint8List bytes, ByteData d) {
  final chunk = String.fromCharCodes(bytes.sublist(12, 16));
  switch (chunk) {
    case 'VP8 ': // lossy
      if (bytes.length < 30 || bytes[23] != 0x9D || bytes[24] != 0x01 || bytes[25] != 0x2A) return null;
      return ImageSize(d.getUint16(26, Endian.little) & 0x3FFF, d.getUint16(28, Endian.little) & 0x3FFF);
    case 'VP8L': // lossless
      if (bytes.length < 25 || bytes[20] != 0x2F) return null;
      final bits = d.getUint32(21, Endian.little);
      return ImageSize((bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1);
    case 'VP8X': // extended
      if (bytes.length < 30) return null;
      final w = bytes[24] | (bytes[25] << 8) | (bytes[26] << 16);
      final h = bytes[27] | (bytes[28] << 8) | (bytes[29] << 16);
      return ImageSize(w + 1, h + 1);
    default:
      return null;
  }
}
