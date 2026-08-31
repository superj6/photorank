import 'dart:io';

import 'database.dart';

/// Web: ranking data lives in the browser (IndexedDB); file backup does not
/// apply and the Settings entries are hidden ([supported] is false).
class DbBackup {
  DbBackup._();

  static bool get supported => false;

  static Future<File> liveFile() => throw UnsupportedError('no file database on the web');
  static Future<File> snapshot(AppDatabase db) => throw UnsupportedError('no file database on the web');
  static Future<BackupInfo> validate(File file) => throw UnsupportedError('no file database on the web');
  static Future<void> replaceLive(File backup) => throw UnsupportedError('no file database on the web');
}

class BackupInfo {
  const BackupInfo({required this.photos, required this.decisions, required this.schemaVersion});
  final int photos;
  final int decisions;
  final int schemaVersion;
}
