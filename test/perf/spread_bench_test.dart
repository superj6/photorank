import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/dealer/dealer.dart';
import 'package:photorank/core/rating/glicko.dart';

/// Diagnostic: which capture dates actually come up over a run of hands?
void main() {
  final now = DateTime(2026, 8, 27, 12);

  /// A bulk-imported library: all indexed today, photos spread over 5 years,
  /// shot in clumps (a few dozen photos per day, like real phone use).
  List<PhotoState> library({required bool importedToday}) {
    final rng = Random(4);
    final out = <PhotoState>[];
    var id = 0;
    for (var day = 0; day < 1800; day++) {
      final shots = rng.nextInt(12); // most days few, some days many
      for (var i = 0; i < shots; i++) {
        final takenAt = now.subtract(Duration(days: 1800 - day, minutes: rng.nextInt(600)));
        out.add(PhotoState(
          id: id++,
          rating: Rating.initial,
          takenAt: takenAt,
          addedAt: importedToday ? now : takenAt,
        ));
      }
    }
    return out;
  }

  void report(String label, List<PhotoState> photos) {
    final byId = {for (final p in photos) p.id: p};
    final years = <int, int>{};
    var cards = 0;
    for (var hand = 0; hand < 10; hand++) {
      for (final c in Dealer(rng: Random(hand)).dealHand(photos, config: const DealerConfig(), now: now)) {
        cards++;
        for (final id in c.photoIds) {
          final t = byId[id]!.takenAt!;
          years[t.year] = (years[t.year] ?? 0) + 1;
        }
      }
    }
    final keys = years.keys.toList()..sort();
    // ignore: avoid_print
    print('$label  library=${photos.length} cards=$cards  by year: '
        '${keys.map((y) => '$y:${years[y]}').join('  ')}');
  }

  test('date spread of dealt photos', () {
    report('bulk import (all indexed today):', library(importedToday: true));
    report('indexed as taken       :', library(importedToday: false));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
