import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/dealer/dealer.dart';
import '../../data/repo/photo_repo.dart';
import '../../data/repo/ranking_repo.dart';
import '../../core/rating/observation.dart';

/// "Today's Duel" home-screen widget: the app pre-deals one duel, writes two
/// thumbnails to app storage, and the Android provider shows them. Tapping a
/// side opens the app onto that duel with the tap already counted.
class DuelWidget {
  DuelWidget._();

  static const androidName = 'DuelWidgetProvider';

  /// Deal a fresh duel and push it to the widget. Safe to call often.
  static Future<void> refresh({required RankingRepo ranking, required PhotoRepo photos, required int axis}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final states = await ranking.photoStates(axis);
      if (states.length < 2) return;
      final cards = Dealer().dealHand(states,
          config: const DealerConfig(modeWeights: {GameMode.duel: 1}, handSize: 1), now: DateTime.now());
      if (cards.isEmpty) return;
      final ids = cards.first.photoIds;
      final rows = await photos.byIds(ids);
      final dir = await getApplicationSupportDirectory();
      final paths = <String>[];
      for (final id in ids) {
        final row = rows.where((r) => r.id == id).firstOrNull;
        final entity = row == null ? null : await AssetEntity.fromId(row.mediaId);
        final bytes = await entity?.thumbnailDataWithSize(const ThumbnailSize(400, 400));
        if (bytes == null) return;
        final file = File('${dir.path}/widget_duel_$id.jpg');
        await file.writeAsBytes(bytes, flush: true);
        paths.add(file.path);
      }
      await HomeWidget.saveWidgetData<String>('duel_a_id', '${ids[0]}');
      await HomeWidget.saveWidgetData<String>('duel_b_id', '${ids[1]}');
      await HomeWidget.saveWidgetData<String>('duel_a_path', paths[0]);
      await HomeWidget.saveWidgetData<String>('duel_b_path', paths[1]);
      await HomeWidget.updateWidget(androidName: androidName, qualifiedAndroidName: 'dev.photorank.photorank.$androidName');
    } catch (e) {
      debugPrint('widget refresh failed: $e');
    }
  }

  /// Parses `photorank://duel?a=1&b=2&pick=1` into (a, b, pick?).
  static (int, int, int?)? parse(Uri? uri) {
    if (uri == null || uri.scheme != 'photorank' || uri.host != 'duel') return null;
    final a = int.tryParse(uri.queryParameters['a'] ?? '');
    final b = int.tryParse(uri.queryParameters['b'] ?? '');
    if (a == null || b == null) return null;
    return (a, b, int.tryParse(uri.queryParameters['pick'] ?? ''));
  }
}
