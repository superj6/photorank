import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photorank/data/media/image_header.dart';

void main() {
  final source = img.Image(width: 133, height: 71);
  img.fill(source, color: img.ColorRgb8(10, 120, 200));
  // A little detail so lossy encoders keep real dimensions.
  img.drawLine(source, x1: 0, y1: 0, x2: 132, y2: 70, color: img.ColorRgb8(255, 255, 255));

  final encoders = <String, Uint8List Function()>{
    'jpeg': () => Uint8List.fromList(img.encodeJpg(source, quality: 90)),
    'png': () => Uint8List.fromList(img.encodePng(source)),
    'gif': () => Uint8List.fromList(img.encodeGif(source)),
    'bmp': () => Uint8List.fromList(img.encodeBmp(source)),
    'webp-lossless': () => Uint8List.fromList(img.encodePng(source)), // placeholder, replaced below
  };

  for (final name in ['jpeg', 'png', 'gif', 'bmp']) {
    test('$name dimensions match the decoder', () {
      final bytes = encoders[name]!();
      expect(imageSizeFromHeader(bytes), const ImageSize(133, 71), reason: name);
      final decoded = img.decodeImage(bytes)!;
      expect((decoded.width, decoded.height), (133, 71), reason: 'decoder agrees for $name');
    });
  }

  test('progressive jpeg is read from its start-of-frame', () {
    // A JPEG whose first marker segments are large (EXIF/comment) still parses.
    final base = img.Image(width: 640, height: 480);
    base.exif.exifIfd['UserComment'] = 'x' * 4000;
    final bytes = Uint8List.fromList(img.encodeJpg(base, quality: 80));
    expect(imageSizeFromHeader(bytes), const ImageSize(640, 480));
  });

  test('truncated and unknown data yield null rather than a wrong size', () {
    final jpeg = Uint8List.fromList(img.encodeJpg(source));
    expect(imageSizeFromHeader(jpeg.sublist(0, 8)), isNull);
    expect(imageSizeFromHeader(Uint8List.fromList(List.filled(64, 7))), isNull);
    expect(imageSizeFromHeader(Uint8List(0)), isNull);
  });

  test('only the file head is needed, not the whole file', () {
    final big = img.Image(width: 4000, height: 3000);
    img.fill(big, color: img.ColorRgb8(200, 90, 60));
    final bytes = Uint8List.fromList(img.encodeJpg(big, quality: 88));
    expect(bytes.length, greaterThan(64 * 1024));
    expect(imageSizeFromHeader(Uint8List.sublistView(bytes, 0, 4096)), const ImageSize(4000, 3000));
  });
}
