import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Decodes [source] with the browser (fast, handles HEIC-converted JPEGs and
/// EXIF orientation), scales so the long edge is at most [maxEdge], and
/// re-encodes as JPEG. Runs off the Dart heap: the browser does the work.
Future<({Uint8List bytes, int width, int height})?> downscaleToJpeg(Uint8List source, {int maxEdge = 1600, double quality = 0.85}) async {
  final blob = web.Blob([source.toJS].toJS, web.BlobPropertyBag(type: 'image/*'));
  final web.ImageBitmap bitmap;
  try {
    bitmap = await web.window.createImageBitmap(blob, web.ImageBitmapOptions(imageOrientation: 'from-image')).toDart;
  } catch (_) {
    return null; // not an image the browser can decode
  }
  final w = bitmap.width, h = bitmap.height;
  final scale = (w > h ? w : h) > maxEdge ? maxEdge / (w > h ? w : h) : 1.0;
  final tw = (w * scale).round(), th = (h * scale).round();
  final canvas = web.OffscreenCanvas(tw, th);
  final ctx = canvas.getContext('2d') as web.OffscreenCanvasRenderingContext2D;
  ctx.drawImage(bitmap, 0, 0, tw.toDouble(), th.toDouble());
  bitmap.close();
  final out = await canvas.convertToBlob(web.ImageEncodeOptions(type: 'image/jpeg', quality: quality)).toDart;
  final buffer = await out.arrayBuffer().toDart;
  return (bytes: buffer.toDart.asUint8List(), width: tw, height: th);
}
