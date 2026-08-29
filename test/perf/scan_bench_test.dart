@Tags(['perf'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photorank/data/media/folder_source.dart';
import 'package:photorank/data/media/image_header.dart';

/// Where the per-file indexing time goes on real camera JPEGs.
void main() {
  test('scan header cost breakdown', () {
    final dir = Directory('${Platform.environment['HOME']}/PhotoRank-big');
    if (!dir.existsSync()) return;
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.jpg')).take(40).toList();

    var sw = Stopwatch()..start();
    final heads = <Uint8List>[];
    for (final f in files) {
      final raf = f.openSync();
      heads.add(raf.readSync(256 * 1024));
      raf.closeSync();
    }
    final readMs = sw.elapsedMilliseconds;

    sw = Stopwatch()..start();
    for (final h in heads) {
      img.decodeJpgExif(h);
    }
    final exifMs = sw.elapsedMilliseconds;

    sw = Stopwatch()..start();
    for (final h in heads) {
      img.findDecoderForData(h)?.startDecode(h);
    }
    final decodeInfoMs = sw.elapsedMilliseconds;

    sw = Stopwatch()..start();
    for (final h in heads) {
      imageSizeFromHeader(h);
    }
    final headerMs = sw.elapsedMilliseconds;

    sw = Stopwatch()..start();
    for (final f in files) {
      readHeader(f.path, heads[files.indexOf(f)], modifiedAt: DateTime.now());
    }
    final fullMs = sw.elapsedMilliseconds;

    // ignore: avoid_print
    print('=== ${files.length} files: read256KB=${readMs}ms exif=${exifMs}ms '
        'startDecode(old)=${decodeInfoMs}ms headerParse(new)=${headerMs}ms '
        'readHeader total=${fullMs}ms (${(fullMs / files.length).toStringAsFixed(1)}ms/photo)');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
