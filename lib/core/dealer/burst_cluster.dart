import 'photo_state.dart';

/// Groups photos captured within [gap] of their neighbour into burst clusters.
/// Returns clusters with at least [minSize] members, each sorted by time.
List<List<PhotoState>> clusterBursts(
  Iterable<PhotoState> photos, {
  Duration gap = const Duration(seconds: 10),
  int minSize = 3,
  int maxSize = 9,
}) {
  final dated = photos.where((p) => p.takenAt != null).toList()
    ..sort((a, b) => a.takenAt!.compareTo(b.takenAt!));
  final clusters = <List<PhotoState>>[];
  var current = <PhotoState>[];
  for (final p in dated) {
    if (current.isNotEmpty &&
        p.takenAt!.difference(current.last.takenAt!) > gap) {
      if (current.length >= minSize) clusters.add(current);
      current = <PhotoState>[];
    }
    current.add(p);
  }
  if (current.length >= minSize) clusters.add(current);
  // Split oversized clusters evenly so a Best-of-Burst grid stays tappable.
  return [
    for (final c in clusters) ..._splitEven(c, maxSize),
  ];
}

List<List<T>> _splitEven<T>(List<T> items, int maxSize) {
  if (items.length <= maxSize) return [items];
  final chunks = (items.length / maxSize).ceil();
  final size = (items.length / chunks).ceil();
  return [
    for (var i = 0; i < items.length; i += size)
      items.sublist(i, (i + size).clamp(0, items.length)),
  ];
}
