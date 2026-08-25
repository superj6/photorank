import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photorank/data/arena/prepare_upload.dart';

void main() {
  test('downsizes to the long edge, strips EXIF, re-encodes as JPEG', () {
    final src = img.Image(width: 4000, height: 3000);
    img.fill(src, color: img.ColorRgb8(200, 80, 60));
    src.exif.imageIfd['Make'] = 'TestCam';
    src.exif.gpsIfd['GPSLatitude'] = [1, 2, 3];
    final jpg = Uint8List.fromList(img.encodeJpg(src, quality: 90));
    expect(img.decodeJpgExif(jpg)?.imageIfd['Make']?.toString(), 'TestCam');

    final out = prepareUpload(jpg, maxEdge: 1280)!;
    expect(out.width, 1280);
    expect(out.height, 960);
    expect(out.bytes.length, lessThan(jpg.length));
    final exif = img.decodeJpgExif(out.bytes);
    expect(exif == null || (exif.imageIfd['Make'] == null && exif.gpsIfd.isEmpty), isTrue);
  });

  test('portrait keeps orientation, small images are not upscaled', () {
    final src = img.Image(width: 600, height: 900);
    final out = prepareUpload(Uint8List.fromList(img.encodePng(src)))!;
    expect((out.width, out.height), (600, 900));
  });

  test('garbage input yields null', () {
    expect(prepareUpload(Uint8List.fromList([1, 2, 3])), isNull);
  });
}
