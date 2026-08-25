import '../dealer/photo_state.dart';

/// A group of near-identical shots; [best] represents it in Top views.
class Moment {
  const Moment({required this.best, required this.similar});
  final PhotoState best;

  /// Other members, best first.
  final List<PhotoState> similar;
  int get size => similar.length + 1;
  List<PhotoState> get all => [best, ...similar];
}

/// Assigns a moment key to every photo. Bursts (cluster ids) are moments;
/// photos shot within [window] of each other with similar scores are too.
/// Photos with no capture time are their own moment.
Map<int, String> momentKeys(List<PhotoState> states, {Duration window = const Duration(minutes: 3), double scoreGap = 15}) {
  final keys = <int, String>{};
  final byTime = states.where((s) => s.takenAt != null).toList()..sort((a, b) => a.takenAt!.compareTo(b.takenAt!));
  String? currentKey;
  PhotoState? prev;
  for (final s in byTime) {
    if (s.clusterId != null) {
      keys[s.id] = 'c${s.clusterId}';
      prev = s;
      currentKey = null;
      continue;
    }
    final close = prev != null &&
        prev.clusterId == null &&
        s.takenAt!.difference(prev.takenAt!) <= window &&
        (s.rating.score - prev.rating.score).abs() <= scoreGap;
    if (close && currentKey != null) {
      keys[s.id] = currentKey;
    } else if (close) {
      currentKey = 't${prev.id}';
      keys[prev.id] = currentKey;
      keys[s.id] = currentKey;
    } else {
      currentKey = null;
      keys[s.id] = 'p${s.id}';
    }
    prev = s;
  }
  for (final s in states) {
    keys.putIfAbsent(s.id, () => 'p${s.id}');
  }
  return keys;
}

/// Collapses a best-first list into moments, preserving order of the best
/// member of each moment. Ratings are untouched; this is presentation.
List<Moment> collapseMoments(List<PhotoState> rankedBestFirst, {Map<int, String>? keys}) {
  final k = keys ?? momentKeys(rankedBestFirst);
  final order = <String>[];
  final members = <String, List<PhotoState>>{};
  for (final s in rankedBestFirst) {
    final key = k[s.id] ?? 'p${s.id}';
    if (!members.containsKey(key)) order.add(key);
    members.putIfAbsent(key, () => []).add(s);
  }
  // The face of a moment is its best *unshadowed* member: a burst keeper you
  // chose wins over a sibling that happens to score higher.
  return [
    for (final key in order)
      () {
        final list = members[key]!;
        final face = list.firstWhere((p) => p.shadowedBy == null, orElse: () => list.first);
        return Moment(best: face, similar: [for (final p in list) if (p != face) p]);
      }(),
  ];
}

/// Best-first list with one photo per moment — for Top N, shares, seeding.
List<PhotoState> onePerMoment(List<PhotoState> rankedBestFirst, {Map<int, String>? keys}) =>
    collapseMoments(rankedBestFirst, keys: keys).map((m) => m.best).toList();
