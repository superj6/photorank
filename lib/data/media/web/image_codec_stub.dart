import 'dart:typed_data';

/// Non-web platforms never call this; the web source is only created on web.
Future<({Uint8List bytes, int width, int height})?> downscaleToJpeg(Uint8List source, {int maxEdge = 1600, double quality = 0.85}) async =>
    throw UnsupportedError('browser image codec is only available on the web');
