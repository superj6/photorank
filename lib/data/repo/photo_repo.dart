import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/dealer/burst_cluster.dart';
import '../../core/dealer/photo_state.dart';
import '../../core/rating/glicko.dart';
import '../db/database.dart';
import '../media/scanned_asset.dart';

/// Photo inventory: syncing from the device, clusters, browse history.
class PhotoRepo {
  PhotoRepo(this.db);

  final AppDatabase db;

  /// Inserts new assets and refreshes metadata on known ones without touching
  /// ranking-related columns (addedAt, lastShownAt, views).
  Future<void> upsertAssets(Iterable<ScannedAsset> assets, {DateTime? now}) async {
    final ts = now ?? DateTime.now();
    final rows = [
      for (final a in assets)
        PhotosCompanion.insert(
          mediaId: a.mediaId,
          albumId: Value(a.albumId),
          takenAt: Value(a.takenAt),
          modifiedAt: Value(a.modifiedAt),
          width: Value(a.width),
          height: Value(a.height),
          addedAt: ts,
        ),
    ];
    if (rows.isEmpty) return;
    await db.batch((b) {
      b.insertAll(
        db.photos,
        rows,
        onConflict: DoUpdate<$PhotosTable, PhotoRow>.withExcluded(
          (old, excluded) => PhotosCompanion.custom(
            albumId: excluded.albumId,
            takenAt: excluded.takenAt,
            modifiedAt: excluded.modifiedAt,
            width: excluded.width,
            height: excluded.height,
            missing: const Constant(false),
          ),
          target: [db.photos.mediaId],
        ),
      );
    });
  }

  /// Media ids already indexed and in play, with the file modification time
  /// recorded for them. A scan uses this to skip re-reading headers of files
  /// that have not changed — opening a file costs ~40 ms on an external
  /// drive, a stat costs ~0.01 ms.
  ///
  /// Photos currently flagged missing are deliberately excluded, so they are
  /// re-read (and un-flagged) if they reappear.
  Future<Map<String, DateTime?>> indexedFingerprints() async {
    final rows = await (db.selectOnly(db.photos)
          ..addColumns([db.photos.mediaId, db.photos.modifiedAt])
          ..where(db.photos.missing.equals(false)))
        .get();
    return {
      for (final r in rows) r.read(db.photos.mediaId)!: r.read(db.photos.modifiedAt),
    };
  }

  Future<int> count({bool includeMissing = false}) async {
    final q = db.selectOnly(db.photos)..addColumns([db.photos.id.count()]);
    if (!includeMissing) q.where(db.photos.missing.equals(false));
    final row = await q.getSingle();
    return row.read(db.photos.id.count()) ?? 0;
  }

  /// After a full scan, flag anything the library no longer contains so it
  /// stops being dealt. Photos that come back are un-flagged by [upsertAssets].
  ///
  /// On desktop the scanner passes the folders currently in scope
  /// ([configuredRoots]) and the subset it could actually read
  /// ([readableRoots]). A photo leaves play when it sits outside every
  /// configured folder (that folder was removed from the scope) or when its
  /// folder was read and the file was not found (it was deleted). A photo in
  /// a configured folder that could not be read — an unplugged drive — is
  /// left alone, so the library never empties itself by accident.
  ///
  /// With no roots (the phone's media store) a scan that found nothing at all
  /// is treated as a failed scan rather than an emptied library.
  ///
  /// Batched: removing a folder of thousands of photos is a handful of
  /// statements, not one per photo.
  Future<int> markMissingExcept(
    Set<String> presentMediaIds, {
    List<String>? configuredRoots,
    List<String>? readableRoots,
  }) async {
    if (configuredRoots == null && presentMediaIds.isEmpty) return 0;
    final rows = await (db.selectOnly(db.photos)
          ..addColumns([db.photos.id, db.photos.mediaId])
          ..where(db.photos.missing.equals(false)))
        .get();

    bool under(List<String> roots, String mediaId) =>
        roots.any((root) => mediaId == root || p.isWithin(root, mediaId));

    bool isGone(String mediaId) {
      if (configuredRoots == null) return !presentMediaIds.contains(mediaId);
      // Outside every folder in scope: that folder is no longer listed.
      if (!under(configuredRoots, mediaId)) return true;
      // In scope but its folder could not be read right now: keep it.
      if (!under(readableRoots ?? const [], mediaId)) return false;
      return !presentMediaIds.contains(mediaId);
    }

    final gone = [
      for (final r in rows)
        if (isGone(r.read(db.photos.mediaId)!)) r.read(db.photos.id)!,
    ];
    if (gone.isEmpty) return 0;
    await db.batch((b) {
      for (var i = 0; i < gone.length; i += 400) {
        final chunk = gone.sublist(i, (i + 400).clamp(0, gone.length));
        b.update(db.photos, const PhotosCompanion(missing: Value(true)),
            where: (p) => p.id.isIn(chunk));
      }
    });
    return gone.length;
  }

  /// A photo that failed to load right now (deleted between scans): drop it
  /// from play immediately rather than showing a broken card again.
  Future<void> markMissingByMediaId(String mediaId) =>
      (db.update(db.photos)..where((p) => p.mediaId.equals(mediaId)))
          .write(const PhotosCompanion(missing: Value(true)));

  Future<PhotoRow?> byId(int id) =>
      (db.select(db.photos)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<List<PhotoRow>> byIds(Iterable<int> ids) =>
      (db.select(db.photos)..where((p) => p.id.isIn(ids.toList()))).get();

  /// Groups still-unclustered photos into bursts by capture time.
  Future<int> clusterNewPhotos() async {
    final rows = await (db.select(db.photos)
          ..where((p) => p.clusterId.isNull() & p.missing.equals(false)))
        .get();
    final states = [
      for (final p in rows)
        PhotoState(id: p.id, rating: Rating.initial, takenAt: p.takenAt),
    ];
    final clusters = clusterBursts(states);
    await db.transaction(() async {
      for (final c in clusters) {
        final clusterId = await db
            .into(db.clusters)
            .insert(ClustersCompanion.insert(size: c.length));
        await (db.update(db.photos)..where((p) => p.id.isIn(c.map((s) => s.id).toList())))
            .write(PhotosCompanion(clusterId: Value(clusterId)));
      }
    });
    return clusters.length;
  }

  /// Burst decided: siblings collapse behind the winner.
  Future<void> shadow(int winnerId, Iterable<int> siblingIds) =>
      (db.update(db.photos)..where((p) => p.id.isIn(siblingIds.where((s) => s != winnerId).toList())))
          .write(PhotosCompanion(shadowedBy: Value(winnerId)));

  Future<void> unshadow(Iterable<int> ids) =>
      (db.update(db.photos)..where((p) => p.id.isIn(ids.toList()))).write(const PhotosCompanion(shadowedBy: Value(null)));

  Future<void> resolveCluster(int clusterId) =>
      (db.update(db.clusters)..where((c) => c.id.equals(clusterId)))
          .write(const ClustersCompanion(resolved: Value(true)));

  Future<void> recordView(int photoId,
      {required String source, int dwellMs = 0, DateTime? now}) async {
    final ts = now ?? DateTime.now();
    await db.transaction(() async {
      await db.into(db.views).insert(ViewsCompanion.insert(
          photoId: photoId, viewedAt: ts, source: source, dwellMs: Value(dwellMs)));
      await db.customUpdate(
        'UPDATE photos SET views = views + 1 WHERE id = ?',
        variables: [Variable.withInt(photoId)],
        updates: {db.photos},
      );
    });
  }

  /// Passed cards still count as shown so they are not re-dealt at once.
  Future<void> markShown(Iterable<int> ids, {DateTime? now}) =>
      (db.update(db.photos)..where((p) => p.id.isIn(ids.toList())))
          .write(PhotosCompanion(lastShownAt: Value(now ?? DateTime.now())));

  /// Wins/losses involving [photoId] on [axisId], anchors included.
  Future<(int wins, int losses)> record(int axisId, int photoId) async {
    final rows = await (db.select(db.observations)
          ..where((o) =>
              o.axisId.equals(axisId) &
              (o.subjectId.equals(photoId) | o.opponentId.equals(photoId))))
        .get();
    var wins = 0, losses = 0;
    for (final r in rows) {
      final asSubject = r.subjectId == photoId;
      final won = asSubject ? r.outcome == 'win' : r.outcome == 'loss';
      final lost = asSubject ? r.outcome == 'loss' : r.outcome == 'win';
      if (won) wins++;
      if (lost) losses++;
    }
    return (wins, losses);
  }

  Future<String?> pref(String key) async {
    final row = await (db.select(db.prefs)..where((p) => p.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setPref(String key, String value) => db
      .into(db.prefs)
      .insertOnConflictUpdate(PrefsCompanion.insert(key: key, value: value));
}
