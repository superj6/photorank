import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Mirrors FolderThumbProvider._generate to show the per-photo cost.
void main() {
  test('thumbnail generation cost per photo', () {
    final dir = Directory('${Platform.environment['HOME']}/PhotoRank-seed');
    if (!dir.existsSync()) return;
    final files = dir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.jpg')).take(12).toList();
    final sw = Stopwatch()..start();
    for (final f in files) {
      final t = Stopwatch()..start();
      var image = img.decodeImage(f.readAsBytesSync())!;
      final decodeMs = t.elapsedMilliseconds;
      image = img.bakeOrientation(image);
      final long = image.width > image.height ? image.width : image.height;
      if (long > 360) {
        image = image.width >= image.height
            ? img.copyResize(image, width: 360, interpolation: img.Interpolation.average)
            : img.copyResize(image, height: 360, interpolation: img.Interpolation.average);
      }
      Uint8List.fromList(img.encodeJpg(image, quality: 80));
      // ignore: avoid_print
      print('${f.uri.pathSegments.last}: ${t.elapsedMilliseconds}ms (decode ${decodeMs}ms) ${image.width}x${image.height} src=${f.lengthSync() ~/ 1024}KB');
    }
    // ignore: avoid_print
    print('=== ${files.length} thumbs in ${sw.elapsedMilliseconds}ms  avg=${sw.elapsedMilliseconds ~/ files.length}ms/photo');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
