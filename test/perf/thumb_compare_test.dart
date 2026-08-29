@Tags(['perf'])
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Old pipeline (pure-Dart decode + resize) vs new (engine codec at target
/// size), on realistic 4000x3000 camera-sized JPEGs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('thumbnail pipelines on full-size photos', () async {
    final dir = Directory('${Platform.environment['HOME']}/PhotoRank-big');
    if (!dir.existsSync()) return;
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.jpg')).take(8).toList();

    var sw = Stopwatch()..start();
    for (final f in files) {
      var image = img.decodeImage(f.readAsBytesSync())!;
      image = img.bakeOrientation(image);
      image = image.width >= image.height
          ? img.copyResize(image, width: 360, interpolation: img.Interpolation.average)
          : img.copyResize(image, height: 360, interpolation: img.Interpolation.average);
      Uint8List.fromList(img.encodeJpg(image, quality: 80));
    }
    final oldMs = sw.elapsedMilliseconds;

    sw = Stopwatch()..start();
    for (final f in files) {
      final buffer = await ui.ImmutableBuffer.fromFilePath(f.path);
      final codec = await ui.instantiateImageCodecWithSize(buffer,
          getTargetSize: (w, h) => w >= h ? const ui.TargetImageSize(width: 360) : const ui.TargetImageSize(height: 360));
      (await codec.getNextFrame()).image.dispose();
      codec.dispose();
    }
    final newMs = sw.elapsedMilliseconds;

    // ignore: avoid_print
    print('=== ${files.length} photos @4000x3000 — pure-Dart ${oldMs}ms (${oldMs ~/ files.length}ms each) '
        'vs engine ${newMs}ms (${newMs ~/ files.length}ms each) — ${(oldMs / newMs).toStringAsFixed(1)}x faster');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
