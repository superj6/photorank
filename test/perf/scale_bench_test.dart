import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/dealer/dealer.dart';
import 'package:photorank/core/rating/glicko.dart';
import 'package:photorank/core/rating/observation.dart';
import 'package:photorank/core/sampler/moments.dart';
import 'package:photorank/data/db/database.dart';
import 'package:photorank/data/media/scanned_asset.dart';
import 'package:photorank/data/repo/photo_repo.dart';
import 'package:photorank/data/repo/ranking_repo.dart';

/// Not an assertion suite: prints where the time goes at library scale.
void main() {
  for (final n in [1000, 5000, 14000]) {
    test('scale $n', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final photos = PhotoRepo(db);
      final ranking = RankingRepo(db);
      final axis = await db.defaultAxisId();
      final now = DateTime(2026, 8, 27, 12);
      final rng = Random(1);

      var sw = Stopwatch()..start();
      await photos.upsertAssets([
        for (var i = 0; i < n; i++)
          ScannedAsset(mediaId: 'm$i', takenAt: now.subtract(Duration(minutes: i * 7)), width: 4000, height: 3000),
      ], now: now);
      final insertMs = sw.elapsedMilliseconds;

      sw = Stopwatch()..start();
      await photos.clusterNewPhotos();
      final clusterMs = sw.elapsedMilliseconds;

      // ~2 observations per 10 photos, like an early library.
      for (var i = 0; i < n ~/ 5; i++) {
        await ranking.applyCard(Decompose.duel(
            axisId: axis, cardId: 'c$i', winnerId: rng.nextInt(n) + 1, loserId: rng.nextInt(n) + 1, now: now));
      }

      sw = Stopwatch()..start();
      final states = await ranking.photoStates(axis);
      final statesMs = sw.elapsedMilliseconds;

      sw = Stopwatch()..start();
      final bursts = await ranking.eligibleBursts(axis);
      final burstsMs = sw.elapsedMilliseconds;

      sw = Stopwatch()..start();
      final keys = momentKeys(states);
      final momentMs = sw.elapsedMilliseconds;

      sw = Stopwatch()..start();
      final top = onePerMoment([...states]..sort((a, b) => b.mu.compareTo(a.mu)), keys: keys);
      final collapseMs = sw.elapsedMilliseconds;

      sw = Stopwatch()..start();
      final hand = Dealer(rng: Random(2)).dealHand(states, config: const DealerConfig(), bursts: bursts, now: now);
      final dealMs = sw.elapsedMilliseconds;

      // ignore: avoid_print
      print('n=$n insert=${insertMs}ms cluster=${clusterMs}ms photoStates=${statesMs}ms '
          'eligibleBursts=${burstsMs}ms momentKeys=${momentMs}ms collapse=${collapseMs}ms '
          'dealHand=${dealMs}ms (cards=${hand.length}, moments=${top.length})');
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
