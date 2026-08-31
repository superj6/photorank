import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import 'database.dart';

/// Export / import of the local ranking database (mobile + desktop; the web
/// app keeps its data in the browser and is excluded).
class DbBackup {
  DbBackup._();

  static bool get supported => !kIsWeb;

  /// The live database file, mirroring how [AppDatabase] opens it.
  static Future<File> liveFile() async {
    final dir = (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();
    return File('${dir.path}/photorank.sqlite');
  }

  /// Writes a consistent single-file snapshot of [db] (VACUUM INTO folds in
  /// the WAL and compacts) and returns it.
  static Future<File> snapshot(AppDatabase db) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now();
    final name = 'photorank-backup-${stamp.year}${stamp.month.toString().padLeft(2, '0')}${stamp.day.toString().padLeft(2, '0')}.sqlite';
    final out = File('${dir.path}/$name');
    if (out.existsSync()) out.deleteSync();
    await db.customStatement('VACUUM INTO ?', [out.path]);
    return out;
  }

  /// Opens [file] read-only and returns what it holds. Throws with a
  /// readable message when it is not a usable PhotoRank backup.
  static Future<BackupInfo> validate(File file) async {
    // Magic and user_version come straight from the file header (offset 60):
    // opening through AppDatabase would run migrations and rewrite it.
    final head = await file.openRead(0, 64).expand((c) => c).toList();
    if (head.length < 64 || String.fromCharCodes(head.take(15)).startsWith('SQLite format 3') != true) {
      throw StateError('That file is not a PhotoRank backup.');
    }
    final version = (head[60] << 24) | (head[61] << 16) | (head[62] << 8) | head[63];
    final db = AppDatabase(NativeDatabase(file));
    try {
      if (version > db.schemaVersion) {
        throw StateError('This backup is from a newer version of PhotoRank — update the app first.');
      }
      final photos = (await db.customSelect('SELECT count(*) AS n FROM photos').getSingle()).read<int>('n');
      final decisions = (await db.customSelect('SELECT count(*) AS n FROM observations').getSingle()).read<int>('n');
      return BackupInfo(photos: photos, decisions: decisions, schemaVersion: version);
    } on StateError {
      rethrow;
    } catch (_) {
      throw StateError('That file is not a PhotoRank backup.');
    } finally {
      await db.close();
    }
  }

  /// Replaces the live database with [backup]. [db] must be closed by the
  /// caller first; stale WAL/SHM sidecars are removed too. The app must be
  /// relaunched afterwards.
  static Future<void> replaceLive(File backup) async {
    final live = await liveFile();
    for (final suffix in ['-wal', '-shm']) {
      final f = File('${live.path}$suffix');
      if (f.existsSync()) f.deleteSync();
    }
    await backup.copy(live.path);
  }
}

class BackupInfo {
  const BackupInfo({required this.photos, required this.decisions, required this.schemaVersion});
  final int photos;
  final int decisions;
  final int schemaVersion;
}
