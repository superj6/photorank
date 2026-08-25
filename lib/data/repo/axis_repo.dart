import 'package:drift/drift.dart';

import '../db/database.dart';

/// Ranking dimensions. "Love" is the default; users can add their own.
class AxisRepo {
  AxisRepo(this.db);

  final AppDatabase db;

  static const presets = ['Funny', 'Beautiful', 'Nostalgic', 'Share-worthy'];
  static const prefCurrent = 'axis_id';

  Future<List<AxisRow>> all() => (db.select(db.axes)..orderBy([(a) => OrderingTerm.asc(a.id)])).get();

  Future<AxisRow?> byId(int id) => (db.select(db.axes)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<int> add(String name) => db.into(db.axes).insert(AxesCompanion.insert(name: name.trim()));

  Future<void> rename(int id, String name) =>
      (db.update(db.axes)..where((a) => a.id.equals(id))).write(AxesCompanion(name: Value(name.trim())));

  /// Removes a non-default axis and everything ranked on it.
  Future<bool> delete(int id) async {
    final row = await byId(id);
    if (row == null || row.isDefault) return false;
    await db.transaction(() async {
      await (db.delete(db.observations)..where((o) => o.axisId.equals(id))).go();
      await (db.delete(db.ratings)..where((r) => r.axisId.equals(id))).go();
      await (db.delete(db.axes)..where((a) => a.id.equals(id))).go();
    });
    return true;
  }

  /// The axis the app is currently playing on (falls back to the default).
  Future<int> current() async {
    final raw = await (db.select(db.prefs)..where((p) => p.key.equals(prefCurrent))).getSingleOrNull();
    final id = int.tryParse(raw?.value ?? '');
    if (id != null && await byId(id) != null) return id;
    return db.defaultAxisId();
  }

  Future<void> setCurrent(int id) =>
      db.into(db.prefs).insertOnConflictUpdate(PrefsCompanion.insert(key: prefCurrent, value: '$id'));
}
