import 'package:drift/drift.dart';

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

  Future<int> count({bool includeMissing = false}) async {
    final q = db.selectOnly(db.photos)..addColumns([db.photos.id.count()]);
    if (!includeMissing) q.where(db.photos.missing.equals(false));
    final row = await q.getSingle();
    return row.read(db.photos.id.count()) ?? 0;
  }

  /// After a full scan, flag anything the device no longer has.
  Future<void> markMissingExcept(Set<String> presentMediaIds) async {
    final all = await db.select(db.photos).get();
    final gone = all.where((p) => !presentMediaIds.contains(p.mediaId)).map((p) => p.id);
    for (final id in gone) {
      await (db.update(db.photos)..where((p) => p.id.equals(id)))
          .write(const PhotosCompanion(missing: Value(true)));
    }
  }

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
