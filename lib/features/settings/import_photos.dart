import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../../data/media/web_source.dart';

/// Web: open the browser's picker and import the chosen images. Returns the
/// final progress, or null when the picker was cancelled.
Future<ImportProgress?> importPhotos(WebSource source, {void Function(ImportProgress p)? onProgress}) async {
  const group = XTypeGroup(label: 'Photos', extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'], mimeTypes: ['image/*']);
  final files = await openFiles(acceptedTypeGroups: [group]);
  if (files.isEmpty) return null;
  final loaded = <({String name, Uint8List bytes, DateTime? modified})>[];
  for (final f in files) {
    DateTime? modified;
    try {
      modified = await f.lastModified();
    } catch (_) {}
    loaded.add((name: f.name, bytes: await f.readAsBytes(), modified: modified));
  }
  ImportProgress? last;
  await for (final p in source.import(loaded)) {
    last = p;
    onProgress?.call(p);
  }
  return last;
}
