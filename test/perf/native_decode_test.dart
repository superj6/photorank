import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Flutter's own codec can decode straight to a target size (Skia, C++),
/// instead of the pure-Dart decode+resize the folder source uses today.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('native decode at target size', () async {
    final dir = Directory('${Platform.environment['HOME']}/PhotoRank-seed');
    if (!dir.existsSync()) return;
    final files = dir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.jpg')).take(12).toList();
    final sw = Stopwatch()..start();
    for (final f in files) {
      final t = Stopwatch()..start();
      final buffer = await ui.ImmutableBuffer.fromFilePath(f.path);
      final codec = await ui.instantiateImageCodecWithSize(buffer,
          getTargetSize: (w, h) => ui.TargetImageSize(width: w >= h ? 360 : null, height: h > w ? 360 : null));
      final frame = await codec.getNextFrame();
      // ignore: avoid_print
      print('${f.uri.pathSegments.last}: ${t.elapsedMilliseconds}ms -> ${frame.image.width}x${frame.image.height}');
      frame.image.dispose();
      codec.dispose();
    }
    // ignore: avoid_print
    print('=== ${files.length} native decodes in ${sw.elapsedMilliseconds}ms  avg=${sw.elapsedMilliseconds ~/ files.length}ms/photo');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
