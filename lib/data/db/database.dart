import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// One row per photo on the device that is inside the chosen scope.
@DataClassName('PhotoRow')
class Photos extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// photo_manager `AssetEntity.id` (MediaStore id on Android).
  TextColumn get mediaId => text().unique()();
  TextColumn get albumId => text().nullable()();
  DateTimeColumn get takenAt => dateTime().nullable()();
  DateTimeColumn get modifiedAt => dateTime().nullable()();
  IntColumn get width => integer().withDefault(const Constant(0))();
  IntColumn get height => integer().withDefault(const Constant(0))();
  IntColumn get clusterId => integer().nullable().references(Clusters, #id)();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get lastShownAt => dateTime().nullable()();
  IntColumn get views => integer().withDefault(const Constant(0))();

  /// Set when a rescan no longer finds the asset; kept so history survives.
  BoolColumn get missing => boolean().withDefault(const Constant(false))();
}

/// A ranking dimension. "Love" is the default; more can be added later.
@DataClassName('AxisRow')
class Axes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

/// Current standing of a photo on an axis (derived from observations).
@DataClassName('RatingRow')
class Ratings extends Table {
  IntColumn get photoId => integer().references(Photos, #id)();
  IntColumn get axisId => integer().references(Axes, #id)();
  RealColumn get mu => real().withDefault(const Constant(1500.0))();
  RealColumn get rd => real().withDefault(const Constant(350.0))();
  IntColumn get observations => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {photoId, axisId};
}

/// Append-only log of every pairwise fact, with pre-update snapshots so a
/// card can be undone exactly.
@DataClassName('ObservationRow')
class Observations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get axisId => integer().references(Axes, #id)();
  IntColumn get sessionId => integer().nullable().references(Sessions, #id)();
  TextColumn get cardId => text()();
  TextColumn get mode => text()();
  @ReferenceName('subjectObservations')
  IntColumn get subjectId => integer().references(Photos, #id)();
  @ReferenceName('opponentObservations')
  IntColumn get opponentId => integer().nullable().references(Photos, #id)();
  RealColumn get anchorMu => real().nullable()();
  TextColumn get outcome => text()();
  RealColumn get weight => real().withDefault(const Constant(1.0))();
  DateTimeColumn get createdAt => dateTime()();
  RealColumn get subjectMuBefore => real()();
  RealColumn get subjectRdBefore => real()();
  RealColumn get opponentMuBefore => real().nullable()();
  RealColumn get opponentRdBefore => real().nullable()();
}

@DataClassName('SessionRow')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get cards => integer().withDefault(const Constant(0))();
  TextColumn get mixJson => text().withDefault(const Constant('{}'))();
}

/// Burst clusters (photos captured seconds apart).
@DataClassName('ClusterRow')
class Clusters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get size => integer()();

  /// True once a member has beaten its siblings in Best-of-Burst.
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();
}

/// Browse history: powers Deep Cuts and (later) dwell signals.
@DataClassName('ViewRow')
class Views extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get photoId => integer().references(Photos, #id)();
  DateTimeColumn get viewedAt => dateTime()();
  TextColumn get source => text()();
  IntColumn get dwellMs => integer().withDefault(const Constant(0))();
}

/// Immutable log of beats (in-play moments) that were shown.
@DataClassName('BeatRow')
class Beats extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  IntColumn get decisionCount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get seenAt => dateTime().nullable()();
  DateTimeColumn get sharedAt => dateTime().nullable()();
}

/// One row per calendar day (first open): library shape for trends.
@DataClassName('DailySnapshotRow')
class DailySnapshots extends Table {
  /// yyyy-mm-dd in local time.
  TextColumn get day => text()();
  IntColumn get photos => integer()();
  IntColumn get settled => integer()();
  IntColumn get observations => integer()();
  TextColumn get top10Json => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {day};
}

/// Small key/value store for streaks, XP, settings.
@DataClassName('PrefRow')
class Prefs extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  Photos,
  Axes,
  Ratings,
  Observations,
  Sessions,
  Clusters,
  Views,
  Prefs,
  Beats,
  DailySnapshots,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'photorank'));

  static const defaultAxisName = 'Love';

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(axes).insert(
              AxesCompanion.insert(name: defaultAxisName, isDefault: const Value(true)));
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(beats);
            await m.createTable(dailySnapshots);
            // Existing installs keep every mode; only new installs unlock
            // modes progressively.
            await into(prefs).insertOnConflictUpdate(
                PrefsCompanion.insert(key: 'unlock_all', value: '1'));
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<int> defaultAxisId() async {
    final row = await (select(axes)..where((a) => a.isDefault)).getSingle();
    return row.id;
  }
}
