import '../dealer/photo_state.dart';

/// A ranked, auto-generated set of photos.
class Collection {
  const Collection({required this.id, required this.title, required this.subtitle, required this.ids});
  final String id;
  final String title;
  final String subtitle;

  /// Best first.
  final List<int> ids;
  int get coverId => ids.first;
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Derives collections from the ranking alone: no manual albums needed.
List<Collection> buildCollections(List<PhotoState> states, {DateTime? now, int minGroup = 6}) {
  final rated = states.where((s) => s.observations > 0).toList()..sort((a, b) => b.mu.compareTo(a.mu));
  final out = <Collection>[];
  if (rated.length >= 10) {
    out.add(Collection(id: 'top', title: 'Top 10 all-time', subtitle: 'Your shelf', ids: rated.take(10).map((s) => s.id).toList()));
  }
  final byYear = <int, List<PhotoState>>{};
  final byMonth = <String, List<PhotoState>>{};
  final byDay = <String, List<PhotoState>>{};
  final byCluster = <int, List<PhotoState>>{};
  for (final s in rated) {
    final t = s.takenAt;
    if (t != null) {
      byYear.putIfAbsent(t.year, () => []).add(s);
      byMonth.putIfAbsent('${t.year}-${t.month.toString().padLeft(2, '0')}', () => []).add(s);
      byDay.putIfAbsent('${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}', () => []).add(s);
    }
    if (s.clusterId != null) byCluster.putIfAbsent(s.clusterId!, () => []).add(s);
  }
  final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
  for (final y in years) {
    final g = byYear[y]!;
    if (g.length >= minGroup) out.add(Collection(id: 'year-$y', title: 'Best of $y', subtitle: '${g.length} ranked photos', ids: g.map((s) => s.id).toList()));
  }
  final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
  for (final m in months.take(12)) {
    final g = byMonth[m]!;
    if (g.length >= minGroup) {
      final parts = m.split('-');
      out.add(Collection(id: 'month-$m', title: '${_months[int.parse(parts[1]) - 1]} ${parts[0]}', subtitle: '${g.length} ranked photos', ids: g.map((s) => s.id).toList()));
    }
  }
  final days = byDay.entries.where((e) => e.value.length >= minGroup).toList()..sort((a, b) => b.key.compareTo(a.key));
  for (final d in days.take(12)) {
    final parts = d.key.split('-');
    out.add(Collection(id: 'day-${d.key}', title: 'Trip · ${_months[int.parse(parts[1]) - 1]} ${int.parse(parts[2])}, ${parts[0]}', subtitle: '${d.value.length} photos in one day', ids: d.value.map((s) => s.id).toList()));
  }
  final bursts = byCluster.entries.where((e) => e.value.length >= 3).toList()..sort((a, b) => b.value.first.mu.compareTo(a.value.first.mu));
  if (bursts.isNotEmpty) {
    out.add(Collection(id: 'bursts', title: 'Best of every burst', subtitle: '${bursts.length} bursts, one keeper each', ids: bursts.map((e) => e.value.first.id).toList()));
  }
  return out;
}

/// Photos taken on today's calendar day in other years (±[window] days if
/// the exact day is empty), best first.
List<PhotoState> thisDay(List<PhotoState> states, DateTime now, {int window = 3}) {
  List<PhotoState> pick(int w) => states.where((s) {
        final t = s.takenAt;
        if (t == null || t.year == now.year) return false;
        final sameYear = DateTime(now.year, t.month, t.day);
        return sameYear.difference(DateTime(now.year, now.month, now.day)).inDays.abs() <= w;
      }).toList()
        ..sort((a, b) => b.mu.compareTo(a.mu));
  final exact = pick(0);
  return exact.isNotEmpty ? exact : pick(window);
}
