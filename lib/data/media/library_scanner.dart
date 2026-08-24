import 'package:photo_manager/photo_manager.dart';

import '../repo/photo_repo.dart';
import 'scanned_asset.dart';

/// Which part of the device library to index.
class ScanScope {
  const ScanScope({this.albumIds, this.since});

  /// Restrict to these photo_manager album ids; null = everything.
  final Set<String>? albumIds;

  /// Only photos taken on/after this date; null = all time.
  final DateTime? since;

  static ScanScope lastMonths(int months, {Set<String>? albumIds, DateTime? now}) {
    final n = now ?? DateTime.now();
    return ScanScope(albumIds: albumIds, since: DateTime(n.year, n.month - months, n.day));
  }
}

class ScanProgress {
  const ScanProgress({required this.indexed, required this.total, this.done = false});
  final int indexed;
  final int total;
  final bool done;
}

class AlbumInfo {
  const AlbumInfo({required this.id, required this.name, required this.count, required this.isAll});
  final String id;
  final String name;
  final int count;
  final bool isAll;
}

/// Reads the device library via photo_manager and mirrors it into the DB.
class LibraryScanner {
  LibraryScanner(this.repo, {this.pageSize = 500});

  final PhotoRepo repo;
  final int pageSize;

  Future<PermissionState> requestPermission() => PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(type: RequestType.image, mediaLocation: false),
        ),
      );

  Future<List<AlbumInfo>> albums() async {
    final paths = await PhotoManager.getAssetPathList(type: RequestType.image);
    final out = <AlbumInfo>[];
    for (final p in paths) {
      out.add(AlbumInfo(
          id: p.id, name: p.name, count: await p.assetCountAsync, isAll: p.isAll));
    }
    out.sort((a, b) => b.count.compareTo(a.count));
    return out;
  }

  /// Streams progress while indexing [scope]. Play can start as soon as the
  /// first page lands.
  Stream<ScanProgress> scan(ScanScope scope, {bool markMissing = false}) async* {
    final filter = FilterOptionGroup(
      imageOption: const FilterOption(needTitle: false),
      createTimeCond: DateTimeCond(
        min: scope.since ?? DateTime(1970),
        max: DateTime.now().add(const Duration(days: 1)),
      ),
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
    );
    var paths = await PhotoManager.getAssetPathList(type: RequestType.image, filterOption: filter);
    if (scope.albumIds != null) {
      paths = paths.where((p) => scope.albumIds!.contains(p.id)).toList();
    } else {
      final all = paths.where((p) => p.isAll).toList();
      if (all.isNotEmpty) paths = all;
    }

    var total = 0;
    for (final p in paths) {
      total += await p.assetCountAsync;
    }
    var indexed = 0;
    final seen = <String>{};
    yield ScanProgress(indexed: 0, total: total);

    for (final path in paths) {
      for (var page = 0;; page++) {
        final assets = await path.getAssetListPaged(page: page, size: pageSize);
        if (assets.isEmpty) break;
        final batch = <ScannedAsset>[];
        for (final a in assets) {
          if (!seen.add(a.id)) continue;
          batch.add(ScannedAsset(
            mediaId: a.id,
            albumId: path.isAll ? null : path.id,
            takenAt: a.createDateTime,
            modifiedAt: a.modifiedDateTime,
            width: a.width,
            height: a.height,
          ));
        }
        await repo.upsertAssets(batch);
        indexed += assets.length;
        yield ScanProgress(indexed: indexed, total: total);
        if (assets.length < pageSize) break;
      }
    }
    if (markMissing) await repo.markMissingExcept(seen);
    await repo.clusterNewPhotos();
    yield ScanProgress(indexed: indexed, total: total, done: true);
  }
}
