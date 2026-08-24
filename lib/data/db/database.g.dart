// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ClustersTable extends Clusters
    with TableInfo<$ClustersTable, ClusterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClustersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedMeta = const VerificationMeta(
    'resolved',
  );
  @override
  late final GeneratedColumn<bool> resolved = GeneratedColumn<bool>(
    'resolved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("resolved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, size, resolved];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clusters';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClusterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('resolved')) {
      context.handle(
        _resolvedMeta,
        resolved.isAcceptableOrUnknown(data['resolved']!, _resolvedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClusterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClusterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      resolved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}resolved'],
      )!,
    );
  }

  @override
  $ClustersTable createAlias(String alias) {
    return $ClustersTable(attachedDatabase, alias);
  }
}

class ClusterRow extends DataClass implements Insertable<ClusterRow> {
  final int id;
  final int size;

  /// True once a member has beaten its siblings in Best-of-Burst.
  final bool resolved;
  const ClusterRow({
    required this.id,
    required this.size,
    required this.resolved,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['size'] = Variable<int>(size);
    map['resolved'] = Variable<bool>(resolved);
    return map;
  }

  ClustersCompanion toCompanion(bool nullToAbsent) {
    return ClustersCompanion(
      id: Value(id),
      size: Value(size),
      resolved: Value(resolved),
    );
  }

  factory ClusterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClusterRow(
      id: serializer.fromJson<int>(json['id']),
      size: serializer.fromJson<int>(json['size']),
      resolved: serializer.fromJson<bool>(json['resolved']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'size': serializer.toJson<int>(size),
      'resolved': serializer.toJson<bool>(resolved),
    };
  }

  ClusterRow copyWith({int? id, int? size, bool? resolved}) => ClusterRow(
    id: id ?? this.id,
    size: size ?? this.size,
    resolved: resolved ?? this.resolved,
  );
  ClusterRow copyWithCompanion(ClustersCompanion data) {
    return ClusterRow(
      id: data.id.present ? data.id.value : this.id,
      size: data.size.present ? data.size.value : this.size,
      resolved: data.resolved.present ? data.resolved.value : this.resolved,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClusterRow(')
          ..write('id: $id, ')
          ..write('size: $size, ')
          ..write('resolved: $resolved')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, size, resolved);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClusterRow &&
          other.id == this.id &&
          other.size == this.size &&
          other.resolved == this.resolved);
}

class ClustersCompanion extends UpdateCompanion<ClusterRow> {
  final Value<int> id;
  final Value<int> size;
  final Value<bool> resolved;
  const ClustersCompanion({
    this.id = const Value.absent(),
    this.size = const Value.absent(),
    this.resolved = const Value.absent(),
  });
  ClustersCompanion.insert({
    this.id = const Value.absent(),
    required int size,
    this.resolved = const Value.absent(),
  }) : size = Value(size);
  static Insertable<ClusterRow> custom({
    Expression<int>? id,
    Expression<int>? size,
    Expression<bool>? resolved,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (size != null) 'size': size,
      if (resolved != null) 'resolved': resolved,
    });
  }

  ClustersCompanion copyWith({
    Value<int>? id,
    Value<int>? size,
    Value<bool>? resolved,
  }) {
    return ClustersCompanion(
      id: id ?? this.id,
      size: size ?? this.size,
      resolved: resolved ?? this.resolved,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (resolved.present) {
      map['resolved'] = Variable<bool>(resolved.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClustersCompanion(')
          ..write('id: $id, ')
          ..write('size: $size, ')
          ..write('resolved: $resolved')
          ..write(')'))
        .toString();
  }
}

class $PhotosTable extends Photos with TableInfo<$PhotosTable, PhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _clusterIdMeta = const VerificationMeta(
    'clusterId',
  );
  @override
  late final GeneratedColumn<int> clusterId = GeneratedColumn<int>(
    'cluster_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clusters (id)',
    ),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastShownAtMeta = const VerificationMeta(
    'lastShownAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastShownAt = GeneratedColumn<DateTime>(
    'last_shown_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _viewsMeta = const VerificationMeta('views');
  @override
  late final GeneratedColumn<int> views = GeneratedColumn<int>(
    'views',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _missingMeta = const VerificationMeta(
    'missing',
  );
  @override
  late final GeneratedColumn<bool> missing = GeneratedColumn<bool>(
    'missing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("missing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaId,
    albumId,
    takenAt,
    modifiedAt,
    width,
    height,
    clusterId,
    addedAt,
    lastShownAt,
    views,
    missing,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhotoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('cluster_id')) {
      context.handle(
        _clusterIdMeta,
        clusterId.isAcceptableOrUnknown(data['cluster_id']!, _clusterIdMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('last_shown_at')) {
      context.handle(
        _lastShownAtMeta,
        lastShownAt.isAcceptableOrUnknown(
          data['last_shown_at']!,
          _lastShownAtMeta,
        ),
      );
    }
    if (data.containsKey('views')) {
      context.handle(
        _viewsMeta,
        views.isAcceptableOrUnknown(data['views']!, _viewsMeta),
      );
    }
    if (data.containsKey('missing')) {
      context.handle(
        _missingMeta,
        missing.isAcceptableOrUnknown(data['missing']!, _missingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      ),
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      clusterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cluster_id'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      lastShownAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_shown_at'],
      ),
      views: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}views'],
      )!,
      missing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}missing'],
      )!,
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }
}

class PhotoRow extends DataClass implements Insertable<PhotoRow> {
  final int id;

  /// photo_manager `AssetEntity.id` (MediaStore id on Android).
  final String mediaId;
  final String? albumId;
  final DateTime? takenAt;
  final DateTime? modifiedAt;
  final int width;
  final int height;
  final int? clusterId;
  final DateTime addedAt;
  final DateTime? lastShownAt;
  final int views;

  /// Set when a rescan no longer finds the asset; kept so history survives.
  final bool missing;
  const PhotoRow({
    required this.id,
    required this.mediaId,
    this.albumId,
    this.takenAt,
    this.modifiedAt,
    required this.width,
    required this.height,
    this.clusterId,
    required this.addedAt,
    this.lastShownAt,
    required this.views,
    required this.missing,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['media_id'] = Variable<String>(mediaId);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    if (!nullToAbsent || takenAt != null) {
      map['taken_at'] = Variable<DateTime>(takenAt);
    }
    if (!nullToAbsent || modifiedAt != null) {
      map['modified_at'] = Variable<DateTime>(modifiedAt);
    }
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    if (!nullToAbsent || clusterId != null) {
      map['cluster_id'] = Variable<int>(clusterId);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || lastShownAt != null) {
      map['last_shown_at'] = Variable<DateTime>(lastShownAt);
    }
    map['views'] = Variable<int>(views);
    map['missing'] = Variable<bool>(missing);
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      id: Value(id),
      mediaId: Value(mediaId),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      takenAt: takenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(takenAt),
      modifiedAt: modifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedAt),
      width: Value(width),
      height: Value(height),
      clusterId: clusterId == null && nullToAbsent
          ? const Value.absent()
          : Value(clusterId),
      addedAt: Value(addedAt),
      lastShownAt: lastShownAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastShownAt),
      views: Value(views),
      missing: Value(missing),
    );
  }

  factory PhotoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoRow(
      id: serializer.fromJson<int>(json['id']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      albumId: serializer.fromJson<String?>(json['albumId']),
      takenAt: serializer.fromJson<DateTime?>(json['takenAt']),
      modifiedAt: serializer.fromJson<DateTime?>(json['modifiedAt']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      clusterId: serializer.fromJson<int?>(json['clusterId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      lastShownAt: serializer.fromJson<DateTime?>(json['lastShownAt']),
      views: serializer.fromJson<int>(json['views']),
      missing: serializer.fromJson<bool>(json['missing']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mediaId': serializer.toJson<String>(mediaId),
      'albumId': serializer.toJson<String?>(albumId),
      'takenAt': serializer.toJson<DateTime?>(takenAt),
      'modifiedAt': serializer.toJson<DateTime?>(modifiedAt),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'clusterId': serializer.toJson<int?>(clusterId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'lastShownAt': serializer.toJson<DateTime?>(lastShownAt),
      'views': serializer.toJson<int>(views),
      'missing': serializer.toJson<bool>(missing),
    };
  }

  PhotoRow copyWith({
    int? id,
    String? mediaId,
    Value<String?> albumId = const Value.absent(),
    Value<DateTime?> takenAt = const Value.absent(),
    Value<DateTime?> modifiedAt = const Value.absent(),
    int? width,
    int? height,
    Value<int?> clusterId = const Value.absent(),
    DateTime? addedAt,
    Value<DateTime?> lastShownAt = const Value.absent(),
    int? views,
    bool? missing,
  }) => PhotoRow(
    id: id ?? this.id,
    mediaId: mediaId ?? this.mediaId,
    albumId: albumId.present ? albumId.value : this.albumId,
    takenAt: takenAt.present ? takenAt.value : this.takenAt,
    modifiedAt: modifiedAt.present ? modifiedAt.value : this.modifiedAt,
    width: width ?? this.width,
    height: height ?? this.height,
    clusterId: clusterId.present ? clusterId.value : this.clusterId,
    addedAt: addedAt ?? this.addedAt,
    lastShownAt: lastShownAt.present ? lastShownAt.value : this.lastShownAt,
    views: views ?? this.views,
    missing: missing ?? this.missing,
  );
  PhotoRow copyWithCompanion(PhotosCompanion data) {
    return PhotoRow(
      id: data.id.present ? data.id.value : this.id,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      clusterId: data.clusterId.present ? data.clusterId.value : this.clusterId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastShownAt: data.lastShownAt.present
          ? data.lastShownAt.value
          : this.lastShownAt,
      views: data.views.present ? data.views.value : this.views,
      missing: data.missing.present ? data.missing.value : this.missing,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoRow(')
          ..write('id: $id, ')
          ..write('mediaId: $mediaId, ')
          ..write('albumId: $albumId, ')
          ..write('takenAt: $takenAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('clusterId: $clusterId, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastShownAt: $lastShownAt, ')
          ..write('views: $views, ')
          ..write('missing: $missing')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mediaId,
    albumId,
    takenAt,
    modifiedAt,
    width,
    height,
    clusterId,
    addedAt,
    lastShownAt,
    views,
    missing,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoRow &&
          other.id == this.id &&
          other.mediaId == this.mediaId &&
          other.albumId == this.albumId &&
          other.takenAt == this.takenAt &&
          other.modifiedAt == this.modifiedAt &&
          other.width == this.width &&
          other.height == this.height &&
          other.clusterId == this.clusterId &&
          other.addedAt == this.addedAt &&
          other.lastShownAt == this.lastShownAt &&
          other.views == this.views &&
          other.missing == this.missing);
}

class PhotosCompanion extends UpdateCompanion<PhotoRow> {
  final Value<int> id;
  final Value<String> mediaId;
  final Value<String?> albumId;
  final Value<DateTime?> takenAt;
  final Value<DateTime?> modifiedAt;
  final Value<int> width;
  final Value<int> height;
  final Value<int?> clusterId;
  final Value<DateTime> addedAt;
  final Value<DateTime?> lastShownAt;
  final Value<int> views;
  final Value<bool> missing;
  const PhotosCompanion({
    this.id = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.clusterId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastShownAt = const Value.absent(),
    this.views = const Value.absent(),
    this.missing = const Value.absent(),
  });
  PhotosCompanion.insert({
    this.id = const Value.absent(),
    required String mediaId,
    this.albumId = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.clusterId = const Value.absent(),
    required DateTime addedAt,
    this.lastShownAt = const Value.absent(),
    this.views = const Value.absent(),
    this.missing = const Value.absent(),
  }) : mediaId = Value(mediaId),
       addedAt = Value(addedAt);
  static Insertable<PhotoRow> custom({
    Expression<int>? id,
    Expression<String>? mediaId,
    Expression<String>? albumId,
    Expression<DateTime>? takenAt,
    Expression<DateTime>? modifiedAt,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? clusterId,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? lastShownAt,
    Expression<int>? views,
    Expression<bool>? missing,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaId != null) 'media_id': mediaId,
      if (albumId != null) 'album_id': albumId,
      if (takenAt != null) 'taken_at': takenAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (clusterId != null) 'cluster_id': clusterId,
      if (addedAt != null) 'added_at': addedAt,
      if (lastShownAt != null) 'last_shown_at': lastShownAt,
      if (views != null) 'views': views,
      if (missing != null) 'missing': missing,
    });
  }

  PhotosCompanion copyWith({
    Value<int>? id,
    Value<String>? mediaId,
    Value<String?>? albumId,
    Value<DateTime?>? takenAt,
    Value<DateTime?>? modifiedAt,
    Value<int>? width,
    Value<int>? height,
    Value<int?>? clusterId,
    Value<DateTime>? addedAt,
    Value<DateTime?>? lastShownAt,
    Value<int>? views,
    Value<bool>? missing,
  }) {
    return PhotosCompanion(
      id: id ?? this.id,
      mediaId: mediaId ?? this.mediaId,
      albumId: albumId ?? this.albumId,
      takenAt: takenAt ?? this.takenAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      width: width ?? this.width,
      height: height ?? this.height,
      clusterId: clusterId ?? this.clusterId,
      addedAt: addedAt ?? this.addedAt,
      lastShownAt: lastShownAt ?? this.lastShownAt,
      views: views ?? this.views,
      missing: missing ?? this.missing,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (clusterId.present) {
      map['cluster_id'] = Variable<int>(clusterId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (lastShownAt.present) {
      map['last_shown_at'] = Variable<DateTime>(lastShownAt.value);
    }
    if (views.present) {
      map['views'] = Variable<int>(views.value);
    }
    if (missing.present) {
      map['missing'] = Variable<bool>(missing.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('id: $id, ')
          ..write('mediaId: $mediaId, ')
          ..write('albumId: $albumId, ')
          ..write('takenAt: $takenAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('clusterId: $clusterId, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastShownAt: $lastShownAt, ')
          ..write('views: $views, ')
          ..write('missing: $missing')
          ..write(')'))
        .toString();
  }
}

class $AxesTable extends Axes with TableInfo<$AxesTable, AxisRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AxesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, isDefault];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'axes';
  @override
  VerificationContext validateIntegrity(
    Insertable<AxisRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AxisRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AxisRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $AxesTable createAlias(String alias) {
    return $AxesTable(attachedDatabase, alias);
  }
}

class AxisRow extends DataClass implements Insertable<AxisRow> {
  final int id;
  final String name;
  final bool isDefault;
  const AxisRow({
    required this.id,
    required this.name,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  AxesCompanion toCompanion(bool nullToAbsent) {
    return AxesCompanion(
      id: Value(id),
      name: Value(name),
      isDefault: Value(isDefault),
    );
  }

  factory AxisRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AxisRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  AxisRow copyWith({int? id, String? name, bool? isDefault}) => AxisRow(
    id: id ?? this.id,
    name: name ?? this.name,
    isDefault: isDefault ?? this.isDefault,
  );
  AxisRow copyWithCompanion(AxesCompanion data) {
    return AxisRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AxisRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AxisRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.isDefault == this.isDefault);
}

class AxesCompanion extends UpdateCompanion<AxisRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> isDefault;
  const AxesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
  });
  AxesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.isDefault = const Value.absent(),
  }) : name = Value(name);
  static Insertable<AxisRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? isDefault,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isDefault != null) 'is_default': isDefault,
    });
  }

  AxesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? isDefault,
  }) {
    return AxesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AxesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }
}

class $RatingsTable extends Ratings with TableInfo<$RatingsTable, RatingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RatingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<int> photoId = GeneratedColumn<int>(
    'photo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES photos (id)',
    ),
  );
  static const VerificationMeta _axisIdMeta = const VerificationMeta('axisId');
  @override
  late final GeneratedColumn<int> axisId = GeneratedColumn<int>(
    'axis_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES axes (id)',
    ),
  );
  static const VerificationMeta _muMeta = const VerificationMeta('mu');
  @override
  late final GeneratedColumn<double> mu = GeneratedColumn<double>(
    'mu',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1500.0),
  );
  static const VerificationMeta _rdMeta = const VerificationMeta('rd');
  @override
  late final GeneratedColumn<double> rd = GeneratedColumn<double>(
    'rd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(350.0),
  );
  static const VerificationMeta _observationsMeta = const VerificationMeta(
    'observations',
  );
  @override
  late final GeneratedColumn<int> observations = GeneratedColumn<int>(
    'observations',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    photoId,
    axisId,
    mu,
    rd,
    observations,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ratings';
  @override
  VerificationContext validateIntegrity(
    Insertable<RatingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('axis_id')) {
      context.handle(
        _axisIdMeta,
        axisId.isAcceptableOrUnknown(data['axis_id']!, _axisIdMeta),
      );
    } else if (isInserting) {
      context.missing(_axisIdMeta);
    }
    if (data.containsKey('mu')) {
      context.handle(_muMeta, mu.isAcceptableOrUnknown(data['mu']!, _muMeta));
    }
    if (data.containsKey('rd')) {
      context.handle(_rdMeta, rd.isAcceptableOrUnknown(data['rd']!, _rdMeta));
    }
    if (data.containsKey('observations')) {
      context.handle(
        _observationsMeta,
        observations.isAcceptableOrUnknown(
          data['observations']!,
          _observationsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {photoId, axisId};
  @override
  RatingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RatingRow(
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}photo_id'],
      )!,
      axisId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}axis_id'],
      )!,
      mu: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mu'],
      )!,
      rd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rd'],
      )!,
      observations: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}observations'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RatingsTable createAlias(String alias) {
    return $RatingsTable(attachedDatabase, alias);
  }
}

class RatingRow extends DataClass implements Insertable<RatingRow> {
  final int photoId;
  final int axisId;
  final double mu;
  final double rd;
  final int observations;
  final DateTime updatedAt;
  const RatingRow({
    required this.photoId,
    required this.axisId,
    required this.mu,
    required this.rd,
    required this.observations,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['photo_id'] = Variable<int>(photoId);
    map['axis_id'] = Variable<int>(axisId);
    map['mu'] = Variable<double>(mu);
    map['rd'] = Variable<double>(rd);
    map['observations'] = Variable<int>(observations);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RatingsCompanion toCompanion(bool nullToAbsent) {
    return RatingsCompanion(
      photoId: Value(photoId),
      axisId: Value(axisId),
      mu: Value(mu),
      rd: Value(rd),
      observations: Value(observations),
      updatedAt: Value(updatedAt),
    );
  }

  factory RatingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RatingRow(
      photoId: serializer.fromJson<int>(json['photoId']),
      axisId: serializer.fromJson<int>(json['axisId']),
      mu: serializer.fromJson<double>(json['mu']),
      rd: serializer.fromJson<double>(json['rd']),
      observations: serializer.fromJson<int>(json['observations']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'photoId': serializer.toJson<int>(photoId),
      'axisId': serializer.toJson<int>(axisId),
      'mu': serializer.toJson<double>(mu),
      'rd': serializer.toJson<double>(rd),
      'observations': serializer.toJson<int>(observations),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RatingRow copyWith({
    int? photoId,
    int? axisId,
    double? mu,
    double? rd,
    int? observations,
    DateTime? updatedAt,
  }) => RatingRow(
    photoId: photoId ?? this.photoId,
    axisId: axisId ?? this.axisId,
    mu: mu ?? this.mu,
    rd: rd ?? this.rd,
    observations: observations ?? this.observations,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RatingRow copyWithCompanion(RatingsCompanion data) {
    return RatingRow(
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      axisId: data.axisId.present ? data.axisId.value : this.axisId,
      mu: data.mu.present ? data.mu.value : this.mu,
      rd: data.rd.present ? data.rd.value : this.rd,
      observations: data.observations.present
          ? data.observations.value
          : this.observations,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RatingRow(')
          ..write('photoId: $photoId, ')
          ..write('axisId: $axisId, ')
          ..write('mu: $mu, ')
          ..write('rd: $rd, ')
          ..write('observations: $observations, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(photoId, axisId, mu, rd, observations, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RatingRow &&
          other.photoId == this.photoId &&
          other.axisId == this.axisId &&
          other.mu == this.mu &&
          other.rd == this.rd &&
          other.observations == this.observations &&
          other.updatedAt == this.updatedAt);
}

class RatingsCompanion extends UpdateCompanion<RatingRow> {
  final Value<int> photoId;
  final Value<int> axisId;
  final Value<double> mu;
  final Value<double> rd;
  final Value<int> observations;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RatingsCompanion({
    this.photoId = const Value.absent(),
    this.axisId = const Value.absent(),
    this.mu = const Value.absent(),
    this.rd = const Value.absent(),
    this.observations = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RatingsCompanion.insert({
    required int photoId,
    required int axisId,
    this.mu = const Value.absent(),
    this.rd = const Value.absent(),
    this.observations = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : photoId = Value(photoId),
       axisId = Value(axisId),
       updatedAt = Value(updatedAt);
  static Insertable<RatingRow> custom({
    Expression<int>? photoId,
    Expression<int>? axisId,
    Expression<double>? mu,
    Expression<double>? rd,
    Expression<int>? observations,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (photoId != null) 'photo_id': photoId,
      if (axisId != null) 'axis_id': axisId,
      if (mu != null) 'mu': mu,
      if (rd != null) 'rd': rd,
      if (observations != null) 'observations': observations,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RatingsCompanion copyWith({
    Value<int>? photoId,
    Value<int>? axisId,
    Value<double>? mu,
    Value<double>? rd,
    Value<int>? observations,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RatingsCompanion(
      photoId: photoId ?? this.photoId,
      axisId: axisId ?? this.axisId,
      mu: mu ?? this.mu,
      rd: rd ?? this.rd,
      observations: observations ?? this.observations,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (photoId.present) {
      map['photo_id'] = Variable<int>(photoId.value);
    }
    if (axisId.present) {
      map['axis_id'] = Variable<int>(axisId.value);
    }
    if (mu.present) {
      map['mu'] = Variable<double>(mu.value);
    }
    if (rd.present) {
      map['rd'] = Variable<double>(rd.value);
    }
    if (observations.present) {
      map['observations'] = Variable<int>(observations.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RatingsCompanion(')
          ..write('photoId: $photoId, ')
          ..write('axisId: $axisId, ')
          ..write('mu: $mu, ')
          ..write('rd: $rd, ')
          ..write('observations: $observations, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions
    with TableInfo<$SessionsTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardsMeta = const VerificationMeta('cards');
  @override
  late final GeneratedColumn<int> cards = GeneratedColumn<int>(
    'cards',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mixJsonMeta = const VerificationMeta(
    'mixJson',
  );
  @override
  late final GeneratedColumn<String> mixJson = GeneratedColumn<String>(
    'mix_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    cards,
    mixJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('cards')) {
      context.handle(
        _cardsMeta,
        cards.isAcceptableOrUnknown(data['cards']!, _cardsMeta),
      );
    }
    if (data.containsKey('mix_json')) {
      context.handle(
        _mixJsonMeta,
        mixJson.isAcceptableOrUnknown(data['mix_json']!, _mixJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      cards: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cards'],
      )!,
      mixJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mix_json'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int cards;
  final String mixJson;
  const SessionRow({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.cards,
    required this.mixJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['cards'] = Variable<int>(cards);
    map['mix_json'] = Variable<String>(mixJson);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      cards: Value(cards),
      mixJson: Value(mixJson),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      cards: serializer.fromJson<int>(json['cards']),
      mixJson: serializer.fromJson<String>(json['mixJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'cards': serializer.toJson<int>(cards),
      'mixJson': serializer.toJson<String>(mixJson),
    };
  }

  SessionRow copyWith({
    int? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? cards,
    String? mixJson,
  }) => SessionRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    cards: cards ?? this.cards,
    mixJson: mixJson ?? this.mixJson,
  );
  SessionRow copyWithCompanion(SessionsCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      cards: data.cards.present ? data.cards.value : this.cards,
      mixJson: data.mixJson.present ? data.mixJson.value : this.mixJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('cards: $cards, ')
          ..write('mixJson: $mixJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startedAt, endedAt, cards, mixJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.cards == this.cards &&
          other.mixJson == this.mixJson);
}

class SessionsCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> cards;
  final Value<String> mixJson;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.cards = const Value.absent(),
    this.mixJson = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.cards = const Value.absent(),
    this.mixJson = const Value.absent(),
  }) : startedAt = Value(startedAt);
  static Insertable<SessionRow> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? cards,
    Expression<String>? mixJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (cards != null) 'cards': cards,
      if (mixJson != null) 'mix_json': mixJson,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? cards,
    Value<String>? mixJson,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      cards: cards ?? this.cards,
      mixJson: mixJson ?? this.mixJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (cards.present) {
      map['cards'] = Variable<int>(cards.value);
    }
    if (mixJson.present) {
      map['mix_json'] = Variable<String>(mixJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('cards: $cards, ')
          ..write('mixJson: $mixJson')
          ..write(')'))
        .toString();
  }
}

class $ObservationsTable extends Observations
    with TableInfo<$ObservationsTable, ObservationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ObservationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _axisIdMeta = const VerificationMeta('axisId');
  @override
  late final GeneratedColumn<int> axisId = GeneratedColumn<int>(
    'axis_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES axes (id)',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES photos (id)',
    ),
  );
  static const VerificationMeta _opponentIdMeta = const VerificationMeta(
    'opponentId',
  );
  @override
  late final GeneratedColumn<int> opponentId = GeneratedColumn<int>(
    'opponent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES photos (id)',
    ),
  );
  static const VerificationMeta _anchorMuMeta = const VerificationMeta(
    'anchorMu',
  );
  @override
  late final GeneratedColumn<double> anchorMu = GeneratedColumn<double>(
    'anchor_mu',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMuBeforeMeta = const VerificationMeta(
    'subjectMuBefore',
  );
  @override
  late final GeneratedColumn<double> subjectMuBefore = GeneratedColumn<double>(
    'subject_mu_before',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectRdBeforeMeta = const VerificationMeta(
    'subjectRdBefore',
  );
  @override
  late final GeneratedColumn<double> subjectRdBefore = GeneratedColumn<double>(
    'subject_rd_before',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opponentMuBeforeMeta = const VerificationMeta(
    'opponentMuBefore',
  );
  @override
  late final GeneratedColumn<double> opponentMuBefore = GeneratedColumn<double>(
    'opponent_mu_before',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _opponentRdBeforeMeta = const VerificationMeta(
    'opponentRdBefore',
  );
  @override
  late final GeneratedColumn<double> opponentRdBefore = GeneratedColumn<double>(
    'opponent_rd_before',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    axisId,
    sessionId,
    cardId,
    mode,
    subjectId,
    opponentId,
    anchorMu,
    outcome,
    weight,
    createdAt,
    subjectMuBefore,
    subjectRdBefore,
    opponentMuBefore,
    opponentRdBefore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'observations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ObservationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('axis_id')) {
      context.handle(
        _axisIdMeta,
        axisId.isAcceptableOrUnknown(data['axis_id']!, _axisIdMeta),
      );
    } else if (isInserting) {
      context.missing(_axisIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('opponent_id')) {
      context.handle(
        _opponentIdMeta,
        opponentId.isAcceptableOrUnknown(data['opponent_id']!, _opponentIdMeta),
      );
    }
    if (data.containsKey('anchor_mu')) {
      context.handle(
        _anchorMuMeta,
        anchorMu.isAcceptableOrUnknown(data['anchor_mu']!, _anchorMuMeta),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('subject_mu_before')) {
      context.handle(
        _subjectMuBeforeMeta,
        subjectMuBefore.isAcceptableOrUnknown(
          data['subject_mu_before']!,
          _subjectMuBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectMuBeforeMeta);
    }
    if (data.containsKey('subject_rd_before')) {
      context.handle(
        _subjectRdBeforeMeta,
        subjectRdBefore.isAcceptableOrUnknown(
          data['subject_rd_before']!,
          _subjectRdBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subjectRdBeforeMeta);
    }
    if (data.containsKey('opponent_mu_before')) {
      context.handle(
        _opponentMuBeforeMeta,
        opponentMuBefore.isAcceptableOrUnknown(
          data['opponent_mu_before']!,
          _opponentMuBeforeMeta,
        ),
      );
    }
    if (data.containsKey('opponent_rd_before')) {
      context.handle(
        _opponentRdBeforeMeta,
        opponentRdBefore.isAcceptableOrUnknown(
          data['opponent_rd_before']!,
          _opponentRdBeforeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ObservationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ObservationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      axisId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}axis_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      ),
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      )!,
      opponentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opponent_id'],
      ),
      anchorMu: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}anchor_mu'],
      ),
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      subjectMuBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subject_mu_before'],
      )!,
      subjectRdBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subject_rd_before'],
      )!,
      opponentMuBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opponent_mu_before'],
      ),
      opponentRdBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opponent_rd_before'],
      ),
    );
  }

  @override
  $ObservationsTable createAlias(String alias) {
    return $ObservationsTable(attachedDatabase, alias);
  }
}

class ObservationRow extends DataClass implements Insertable<ObservationRow> {
  final int id;
  final int axisId;
  final int? sessionId;
  final String cardId;
  final String mode;
  final int subjectId;
  final int? opponentId;
  final double? anchorMu;
  final String outcome;
  final double weight;
  final DateTime createdAt;
  final double subjectMuBefore;
  final double subjectRdBefore;
  final double? opponentMuBefore;
  final double? opponentRdBefore;
  const ObservationRow({
    required this.id,
    required this.axisId,
    this.sessionId,
    required this.cardId,
    required this.mode,
    required this.subjectId,
    this.opponentId,
    this.anchorMu,
    required this.outcome,
    required this.weight,
    required this.createdAt,
    required this.subjectMuBefore,
    required this.subjectRdBefore,
    this.opponentMuBefore,
    this.opponentRdBefore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['axis_id'] = Variable<int>(axisId);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<int>(sessionId);
    }
    map['card_id'] = Variable<String>(cardId);
    map['mode'] = Variable<String>(mode);
    map['subject_id'] = Variable<int>(subjectId);
    if (!nullToAbsent || opponentId != null) {
      map['opponent_id'] = Variable<int>(opponentId);
    }
    if (!nullToAbsent || anchorMu != null) {
      map['anchor_mu'] = Variable<double>(anchorMu);
    }
    map['outcome'] = Variable<String>(outcome);
    map['weight'] = Variable<double>(weight);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['subject_mu_before'] = Variable<double>(subjectMuBefore);
    map['subject_rd_before'] = Variable<double>(subjectRdBefore);
    if (!nullToAbsent || opponentMuBefore != null) {
      map['opponent_mu_before'] = Variable<double>(opponentMuBefore);
    }
    if (!nullToAbsent || opponentRdBefore != null) {
      map['opponent_rd_before'] = Variable<double>(opponentRdBefore);
    }
    return map;
  }

  ObservationsCompanion toCompanion(bool nullToAbsent) {
    return ObservationsCompanion(
      id: Value(id),
      axisId: Value(axisId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      cardId: Value(cardId),
      mode: Value(mode),
      subjectId: Value(subjectId),
      opponentId: opponentId == null && nullToAbsent
          ? const Value.absent()
          : Value(opponentId),
      anchorMu: anchorMu == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorMu),
      outcome: Value(outcome),
      weight: Value(weight),
      createdAt: Value(createdAt),
      subjectMuBefore: Value(subjectMuBefore),
      subjectRdBefore: Value(subjectRdBefore),
      opponentMuBefore: opponentMuBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(opponentMuBefore),
      opponentRdBefore: opponentRdBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(opponentRdBefore),
    );
  }

  factory ObservationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ObservationRow(
      id: serializer.fromJson<int>(json['id']),
      axisId: serializer.fromJson<int>(json['axisId']),
      sessionId: serializer.fromJson<int?>(json['sessionId']),
      cardId: serializer.fromJson<String>(json['cardId']),
      mode: serializer.fromJson<String>(json['mode']),
      subjectId: serializer.fromJson<int>(json['subjectId']),
      opponentId: serializer.fromJson<int?>(json['opponentId']),
      anchorMu: serializer.fromJson<double?>(json['anchorMu']),
      outcome: serializer.fromJson<String>(json['outcome']),
      weight: serializer.fromJson<double>(json['weight']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      subjectMuBefore: serializer.fromJson<double>(json['subjectMuBefore']),
      subjectRdBefore: serializer.fromJson<double>(json['subjectRdBefore']),
      opponentMuBefore: serializer.fromJson<double?>(json['opponentMuBefore']),
      opponentRdBefore: serializer.fromJson<double?>(json['opponentRdBefore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'axisId': serializer.toJson<int>(axisId),
      'sessionId': serializer.toJson<int?>(sessionId),
      'cardId': serializer.toJson<String>(cardId),
      'mode': serializer.toJson<String>(mode),
      'subjectId': serializer.toJson<int>(subjectId),
      'opponentId': serializer.toJson<int?>(opponentId),
      'anchorMu': serializer.toJson<double?>(anchorMu),
      'outcome': serializer.toJson<String>(outcome),
      'weight': serializer.toJson<double>(weight),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'subjectMuBefore': serializer.toJson<double>(subjectMuBefore),
      'subjectRdBefore': serializer.toJson<double>(subjectRdBefore),
      'opponentMuBefore': serializer.toJson<double?>(opponentMuBefore),
      'opponentRdBefore': serializer.toJson<double?>(opponentRdBefore),
    };
  }

  ObservationRow copyWith({
    int? id,
    int? axisId,
    Value<int?> sessionId = const Value.absent(),
    String? cardId,
    String? mode,
    int? subjectId,
    Value<int?> opponentId = const Value.absent(),
    Value<double?> anchorMu = const Value.absent(),
    String? outcome,
    double? weight,
    DateTime? createdAt,
    double? subjectMuBefore,
    double? subjectRdBefore,
    Value<double?> opponentMuBefore = const Value.absent(),
    Value<double?> opponentRdBefore = const Value.absent(),
  }) => ObservationRow(
    id: id ?? this.id,
    axisId: axisId ?? this.axisId,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    cardId: cardId ?? this.cardId,
    mode: mode ?? this.mode,
    subjectId: subjectId ?? this.subjectId,
    opponentId: opponentId.present ? opponentId.value : this.opponentId,
    anchorMu: anchorMu.present ? anchorMu.value : this.anchorMu,
    outcome: outcome ?? this.outcome,
    weight: weight ?? this.weight,
    createdAt: createdAt ?? this.createdAt,
    subjectMuBefore: subjectMuBefore ?? this.subjectMuBefore,
    subjectRdBefore: subjectRdBefore ?? this.subjectRdBefore,
    opponentMuBefore: opponentMuBefore.present
        ? opponentMuBefore.value
        : this.opponentMuBefore,
    opponentRdBefore: opponentRdBefore.present
        ? opponentRdBefore.value
        : this.opponentRdBefore,
  );
  ObservationRow copyWithCompanion(ObservationsCompanion data) {
    return ObservationRow(
      id: data.id.present ? data.id.value : this.id,
      axisId: data.axisId.present ? data.axisId.value : this.axisId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      mode: data.mode.present ? data.mode.value : this.mode,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      opponentId: data.opponentId.present
          ? data.opponentId.value
          : this.opponentId,
      anchorMu: data.anchorMu.present ? data.anchorMu.value : this.anchorMu,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      weight: data.weight.present ? data.weight.value : this.weight,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      subjectMuBefore: data.subjectMuBefore.present
          ? data.subjectMuBefore.value
          : this.subjectMuBefore,
      subjectRdBefore: data.subjectRdBefore.present
          ? data.subjectRdBefore.value
          : this.subjectRdBefore,
      opponentMuBefore: data.opponentMuBefore.present
          ? data.opponentMuBefore.value
          : this.opponentMuBefore,
      opponentRdBefore: data.opponentRdBefore.present
          ? data.opponentRdBefore.value
          : this.opponentRdBefore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ObservationRow(')
          ..write('id: $id, ')
          ..write('axisId: $axisId, ')
          ..write('sessionId: $sessionId, ')
          ..write('cardId: $cardId, ')
          ..write('mode: $mode, ')
          ..write('subjectId: $subjectId, ')
          ..write('opponentId: $opponentId, ')
          ..write('anchorMu: $anchorMu, ')
          ..write('outcome: $outcome, ')
          ..write('weight: $weight, ')
          ..write('createdAt: $createdAt, ')
          ..write('subjectMuBefore: $subjectMuBefore, ')
          ..write('subjectRdBefore: $subjectRdBefore, ')
          ..write('opponentMuBefore: $opponentMuBefore, ')
          ..write('opponentRdBefore: $opponentRdBefore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    axisId,
    sessionId,
    cardId,
    mode,
    subjectId,
    opponentId,
    anchorMu,
    outcome,
    weight,
    createdAt,
    subjectMuBefore,
    subjectRdBefore,
    opponentMuBefore,
    opponentRdBefore,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ObservationRow &&
          other.id == this.id &&
          other.axisId == this.axisId &&
          other.sessionId == this.sessionId &&
          other.cardId == this.cardId &&
          other.mode == this.mode &&
          other.subjectId == this.subjectId &&
          other.opponentId == this.opponentId &&
          other.anchorMu == this.anchorMu &&
          other.outcome == this.outcome &&
          other.weight == this.weight &&
          other.createdAt == this.createdAt &&
          other.subjectMuBefore == this.subjectMuBefore &&
          other.subjectRdBefore == this.subjectRdBefore &&
          other.opponentMuBefore == this.opponentMuBefore &&
          other.opponentRdBefore == this.opponentRdBefore);
}

class ObservationsCompanion extends UpdateCompanion<ObservationRow> {
  final Value<int> id;
  final Value<int> axisId;
  final Value<int?> sessionId;
  final Value<String> cardId;
  final Value<String> mode;
  final Value<int> subjectId;
  final Value<int?> opponentId;
  final Value<double?> anchorMu;
  final Value<String> outcome;
  final Value<double> weight;
  final Value<DateTime> createdAt;
  final Value<double> subjectMuBefore;
  final Value<double> subjectRdBefore;
  final Value<double?> opponentMuBefore;
  final Value<double?> opponentRdBefore;
  const ObservationsCompanion({
    this.id = const Value.absent(),
    this.axisId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.cardId = const Value.absent(),
    this.mode = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.opponentId = const Value.absent(),
    this.anchorMu = const Value.absent(),
    this.outcome = const Value.absent(),
    this.weight = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.subjectMuBefore = const Value.absent(),
    this.subjectRdBefore = const Value.absent(),
    this.opponentMuBefore = const Value.absent(),
    this.opponentRdBefore = const Value.absent(),
  });
  ObservationsCompanion.insert({
    this.id = const Value.absent(),
    required int axisId,
    this.sessionId = const Value.absent(),
    required String cardId,
    required String mode,
    required int subjectId,
    this.opponentId = const Value.absent(),
    this.anchorMu = const Value.absent(),
    required String outcome,
    this.weight = const Value.absent(),
    required DateTime createdAt,
    required double subjectMuBefore,
    required double subjectRdBefore,
    this.opponentMuBefore = const Value.absent(),
    this.opponentRdBefore = const Value.absent(),
  }) : axisId = Value(axisId),
       cardId = Value(cardId),
       mode = Value(mode),
       subjectId = Value(subjectId),
       outcome = Value(outcome),
       createdAt = Value(createdAt),
       subjectMuBefore = Value(subjectMuBefore),
       subjectRdBefore = Value(subjectRdBefore);
  static Insertable<ObservationRow> custom({
    Expression<int>? id,
    Expression<int>? axisId,
    Expression<int>? sessionId,
    Expression<String>? cardId,
    Expression<String>? mode,
    Expression<int>? subjectId,
    Expression<int>? opponentId,
    Expression<double>? anchorMu,
    Expression<String>? outcome,
    Expression<double>? weight,
    Expression<DateTime>? createdAt,
    Expression<double>? subjectMuBefore,
    Expression<double>? subjectRdBefore,
    Expression<double>? opponentMuBefore,
    Expression<double>? opponentRdBefore,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (axisId != null) 'axis_id': axisId,
      if (sessionId != null) 'session_id': sessionId,
      if (cardId != null) 'card_id': cardId,
      if (mode != null) 'mode': mode,
      if (subjectId != null) 'subject_id': subjectId,
      if (opponentId != null) 'opponent_id': opponentId,
      if (anchorMu != null) 'anchor_mu': anchorMu,
      if (outcome != null) 'outcome': outcome,
      if (weight != null) 'weight': weight,
      if (createdAt != null) 'created_at': createdAt,
      if (subjectMuBefore != null) 'subject_mu_before': subjectMuBefore,
      if (subjectRdBefore != null) 'subject_rd_before': subjectRdBefore,
      if (opponentMuBefore != null) 'opponent_mu_before': opponentMuBefore,
      if (opponentRdBefore != null) 'opponent_rd_before': opponentRdBefore,
    });
  }

  ObservationsCompanion copyWith({
    Value<int>? id,
    Value<int>? axisId,
    Value<int?>? sessionId,
    Value<String>? cardId,
    Value<String>? mode,
    Value<int>? subjectId,
    Value<int?>? opponentId,
    Value<double?>? anchorMu,
    Value<String>? outcome,
    Value<double>? weight,
    Value<DateTime>? createdAt,
    Value<double>? subjectMuBefore,
    Value<double>? subjectRdBefore,
    Value<double?>? opponentMuBefore,
    Value<double?>? opponentRdBefore,
  }) {
    return ObservationsCompanion(
      id: id ?? this.id,
      axisId: axisId ?? this.axisId,
      sessionId: sessionId ?? this.sessionId,
      cardId: cardId ?? this.cardId,
      mode: mode ?? this.mode,
      subjectId: subjectId ?? this.subjectId,
      opponentId: opponentId ?? this.opponentId,
      anchorMu: anchorMu ?? this.anchorMu,
      outcome: outcome ?? this.outcome,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      subjectMuBefore: subjectMuBefore ?? this.subjectMuBefore,
      subjectRdBefore: subjectRdBefore ?? this.subjectRdBefore,
      opponentMuBefore: opponentMuBefore ?? this.opponentMuBefore,
      opponentRdBefore: opponentRdBefore ?? this.opponentRdBefore,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (axisId.present) {
      map['axis_id'] = Variable<int>(axisId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (opponentId.present) {
      map['opponent_id'] = Variable<int>(opponentId.value);
    }
    if (anchorMu.present) {
      map['anchor_mu'] = Variable<double>(anchorMu.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (subjectMuBefore.present) {
      map['subject_mu_before'] = Variable<double>(subjectMuBefore.value);
    }
    if (subjectRdBefore.present) {
      map['subject_rd_before'] = Variable<double>(subjectRdBefore.value);
    }
    if (opponentMuBefore.present) {
      map['opponent_mu_before'] = Variable<double>(opponentMuBefore.value);
    }
    if (opponentRdBefore.present) {
      map['opponent_rd_before'] = Variable<double>(opponentRdBefore.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ObservationsCompanion(')
          ..write('id: $id, ')
          ..write('axisId: $axisId, ')
          ..write('sessionId: $sessionId, ')
          ..write('cardId: $cardId, ')
          ..write('mode: $mode, ')
          ..write('subjectId: $subjectId, ')
          ..write('opponentId: $opponentId, ')
          ..write('anchorMu: $anchorMu, ')
          ..write('outcome: $outcome, ')
          ..write('weight: $weight, ')
          ..write('createdAt: $createdAt, ')
          ..write('subjectMuBefore: $subjectMuBefore, ')
          ..write('subjectRdBefore: $subjectRdBefore, ')
          ..write('opponentMuBefore: $opponentMuBefore, ')
          ..write('opponentRdBefore: $opponentRdBefore')
          ..write(')'))
        .toString();
  }
}

class $ViewsTable extends Views with TableInfo<$ViewsTable, ViewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ViewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<int> photoId = GeneratedColumn<int>(
    'photo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES photos (id)',
    ),
  );
  static const VerificationMeta _viewedAtMeta = const VerificationMeta(
    'viewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> viewedAt = GeneratedColumn<DateTime>(
    'viewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dwellMsMeta = const VerificationMeta(
    'dwellMs',
  );
  @override
  late final GeneratedColumn<int> dwellMs = GeneratedColumn<int>(
    'dwell_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    photoId,
    viewedAt,
    source,
    dwellMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'views';
  @override
  VerificationContext validateIntegrity(
    Insertable<ViewRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('viewed_at')) {
      context.handle(
        _viewedAtMeta,
        viewedAt.isAcceptableOrUnknown(data['viewed_at']!, _viewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_viewedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('dwell_ms')) {
      context.handle(
        _dwellMsMeta,
        dwellMs.isAcceptableOrUnknown(data['dwell_ms']!, _dwellMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ViewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ViewRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}photo_id'],
      )!,
      viewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}viewed_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      dwellMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dwell_ms'],
      )!,
    );
  }

  @override
  $ViewsTable createAlias(String alias) {
    return $ViewsTable(attachedDatabase, alias);
  }
}

class ViewRow extends DataClass implements Insertable<ViewRow> {
  final int id;
  final int photoId;
  final DateTime viewedAt;
  final String source;
  final int dwellMs;
  const ViewRow({
    required this.id,
    required this.photoId,
    required this.viewedAt,
    required this.source,
    required this.dwellMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['photo_id'] = Variable<int>(photoId);
    map['viewed_at'] = Variable<DateTime>(viewedAt);
    map['source'] = Variable<String>(source);
    map['dwell_ms'] = Variable<int>(dwellMs);
    return map;
  }

  ViewsCompanion toCompanion(bool nullToAbsent) {
    return ViewsCompanion(
      id: Value(id),
      photoId: Value(photoId),
      viewedAt: Value(viewedAt),
      source: Value(source),
      dwellMs: Value(dwellMs),
    );
  }

  factory ViewRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ViewRow(
      id: serializer.fromJson<int>(json['id']),
      photoId: serializer.fromJson<int>(json['photoId']),
      viewedAt: serializer.fromJson<DateTime>(json['viewedAt']),
      source: serializer.fromJson<String>(json['source']),
      dwellMs: serializer.fromJson<int>(json['dwellMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'photoId': serializer.toJson<int>(photoId),
      'viewedAt': serializer.toJson<DateTime>(viewedAt),
      'source': serializer.toJson<String>(source),
      'dwellMs': serializer.toJson<int>(dwellMs),
    };
  }

  ViewRow copyWith({
    int? id,
    int? photoId,
    DateTime? viewedAt,
    String? source,
    int? dwellMs,
  }) => ViewRow(
    id: id ?? this.id,
    photoId: photoId ?? this.photoId,
    viewedAt: viewedAt ?? this.viewedAt,
    source: source ?? this.source,
    dwellMs: dwellMs ?? this.dwellMs,
  );
  ViewRow copyWithCompanion(ViewsCompanion data) {
    return ViewRow(
      id: data.id.present ? data.id.value : this.id,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      viewedAt: data.viewedAt.present ? data.viewedAt.value : this.viewedAt,
      source: data.source.present ? data.source.value : this.source,
      dwellMs: data.dwellMs.present ? data.dwellMs.value : this.dwellMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ViewRow(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('viewedAt: $viewedAt, ')
          ..write('source: $source, ')
          ..write('dwellMs: $dwellMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, photoId, viewedAt, source, dwellMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ViewRow &&
          other.id == this.id &&
          other.photoId == this.photoId &&
          other.viewedAt == this.viewedAt &&
          other.source == this.source &&
          other.dwellMs == this.dwellMs);
}

class ViewsCompanion extends UpdateCompanion<ViewRow> {
  final Value<int> id;
  final Value<int> photoId;
  final Value<DateTime> viewedAt;
  final Value<String> source;
  final Value<int> dwellMs;
  const ViewsCompanion({
    this.id = const Value.absent(),
    this.photoId = const Value.absent(),
    this.viewedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.dwellMs = const Value.absent(),
  });
  ViewsCompanion.insert({
    this.id = const Value.absent(),
    required int photoId,
    required DateTime viewedAt,
    required String source,
    this.dwellMs = const Value.absent(),
  }) : photoId = Value(photoId),
       viewedAt = Value(viewedAt),
       source = Value(source);
  static Insertable<ViewRow> custom({
    Expression<int>? id,
    Expression<int>? photoId,
    Expression<DateTime>? viewedAt,
    Expression<String>? source,
    Expression<int>? dwellMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (photoId != null) 'photo_id': photoId,
      if (viewedAt != null) 'viewed_at': viewedAt,
      if (source != null) 'source': source,
      if (dwellMs != null) 'dwell_ms': dwellMs,
    });
  }

  ViewsCompanion copyWith({
    Value<int>? id,
    Value<int>? photoId,
    Value<DateTime>? viewedAt,
    Value<String>? source,
    Value<int>? dwellMs,
  }) {
    return ViewsCompanion(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      viewedAt: viewedAt ?? this.viewedAt,
      source: source ?? this.source,
      dwellMs: dwellMs ?? this.dwellMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (photoId.present) {
      map['photo_id'] = Variable<int>(photoId.value);
    }
    if (viewedAt.present) {
      map['viewed_at'] = Variable<DateTime>(viewedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (dwellMs.present) {
      map['dwell_ms'] = Variable<int>(dwellMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ViewsCompanion(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('viewedAt: $viewedAt, ')
          ..write('source: $source, ')
          ..write('dwellMs: $dwellMs')
          ..write(')'))
        .toString();
  }
}

class $PrefsTable extends Prefs with TableInfo<$PrefsTable, PrefRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrefRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  PrefRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrefRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PrefsTable createAlias(String alias) {
    return $PrefsTable(attachedDatabase, alias);
  }
}

class PrefRow extends DataClass implements Insertable<PrefRow> {
  final String key;
  final String value;
  const PrefRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PrefsCompanion toCompanion(bool nullToAbsent) {
    return PrefsCompanion(key: Value(key), value: Value(value));
  }

  factory PrefRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrefRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  PrefRow copyWith({String? key, String? value}) =>
      PrefRow(key: key ?? this.key, value: value ?? this.value);
  PrefRow copyWithCompanion(PrefsCompanion data) {
    return PrefRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrefRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrefRow && other.key == this.key && other.value == this.value);
}

class PrefsCompanion extends UpdateCompanion<PrefRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PrefsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrefsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<PrefRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrefsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PrefsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrefsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ClustersTable clusters = $ClustersTable(this);
  late final $PhotosTable photos = $PhotosTable(this);
  late final $AxesTable axes = $AxesTable(this);
  late final $RatingsTable ratings = $RatingsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $ObservationsTable observations = $ObservationsTable(this);
  late final $ViewsTable views = $ViewsTable(this);
  late final $PrefsTable prefs = $PrefsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    clusters,
    photos,
    axes,
    ratings,
    sessions,
    observations,
    views,
    prefs,
  ];
}

typedef $$ClustersTableCreateCompanionBuilder = ClustersCompanion Function({
  Value<int> id,
  required int size,
  Value<bool> resolved,
});
typedef $$ClustersTableUpdateCompanionBuilder = ClustersCompanion Function({
  Value<int> id,
  Value<int> size,
  Value<bool> resolved,
});

final class $$ClustersTableReferences
    extends BaseReferences<_$AppDatabase, $ClustersTable, ClusterRow> {
  $$ClustersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PhotosTable, List<PhotoRow>> _photosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.photos,
    aliasName: 'clusters__id__photos__cluster_id',
  );

  $$PhotosTableProcessedTableManager get photosRefs {
    final manager = $$PhotosTableTableManager(
      $_db,
      $_db.photos,
    ).filter((f) => f.clusterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_photosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClustersTableFilterComposer
    extends Composer<_$AppDatabase, $ClustersTable> {
  $$ClustersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get resolved => $composableBuilder(
    column: $table.resolved,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> photosRefs(
    Expression<bool> Function($$PhotosTableFilterComposer f) f,
  ) {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.clusterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClustersTableOrderingComposer
    extends Composer<_$AppDatabase, $ClustersTable> {
  $$ClustersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get resolved => $composableBuilder(
    column: $table.resolved,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClustersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClustersTable> {
  $$ClustersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<bool> get resolved =>
      $composableBuilder(column: $table.resolved, builder: (column) => column);

  Expression<T> photosRefs<T extends Object>(
    Expression<T> Function($$PhotosTableAnnotationComposer a) f,
  ) {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.clusterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClustersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClustersTable,
          ClusterRow,
          $$ClustersTableFilterComposer,
          $$ClustersTableOrderingComposer,
          $$ClustersTableAnnotationComposer,
          $$ClustersTableCreateCompanionBuilder,
          $$ClustersTableUpdateCompanionBuilder,
          (ClusterRow, $$ClustersTableReferences),
          ClusterRow,
          PrefetchHooks Function({bool photosRefs})
        > {
  $$ClustersTableTableManager(_$AppDatabase db, $ClustersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClustersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClustersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClustersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> size = const Value.absent(),
            Value<bool> resolved = const Value.absent(),
          }) => ClustersCompanion(id: id, size: size, resolved: resolved),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int size,
                Value<bool> resolved = const Value.absent(),
              }) => ClustersCompanion.insert(
                id: id,
                size: size,
                resolved: resolved,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ClustersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({photosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (photosRefs) db.photos],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (photosRefs)
                    await $_getPrefetchedData<
                      ClusterRow,
                      $ClustersTable,
                      PhotoRow
                    >(
                      currentTable: table,
                      referencedTable: $$ClustersTableReferences
                          ._photosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ClustersTableReferences(db, table, p0).photosRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.clusterId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ClustersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClustersTable,
      ClusterRow,
      $$ClustersTableFilterComposer,
      $$ClustersTableOrderingComposer,
      $$ClustersTableAnnotationComposer,
      $$ClustersTableCreateCompanionBuilder,
      $$ClustersTableUpdateCompanionBuilder,
      (ClusterRow, $$ClustersTableReferences),
      ClusterRow,
      PrefetchHooks Function({bool photosRefs})
    >;
typedef $$PhotosTableCreateCompanionBuilder = PhotosCompanion Function({
  Value<int> id,
  required String mediaId,
  Value<String?> albumId,
  Value<DateTime?> takenAt,
  Value<DateTime?> modifiedAt,
  Value<int> width,
  Value<int> height,
  Value<int?> clusterId,
  required DateTime addedAt,
  Value<DateTime?> lastShownAt,
  Value<int> views,
  Value<bool> missing,
});
typedef $$PhotosTableUpdateCompanionBuilder = PhotosCompanion Function({
  Value<int> id,
  Value<String> mediaId,
  Value<String?> albumId,
  Value<DateTime?> takenAt,
  Value<DateTime?> modifiedAt,
  Value<int> width,
  Value<int> height,
  Value<int?> clusterId,
  Value<DateTime> addedAt,
  Value<DateTime?> lastShownAt,
  Value<int> views,
  Value<bool> missing,
});

final class $$PhotosTableReferences
    extends BaseReferences<_$AppDatabase, $PhotosTable, PhotoRow> {
  $$PhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ClustersTable _clusterIdTable(_$AppDatabase db) =>
      db.clusters.createAlias('photos__cluster_id__clusters__id');

  $$ClustersTableProcessedTableManager? get clusterId {
    final $_column = $_itemColumn<int>('cluster_id');
    if ($_column == null) return null;
    final manager = $$ClustersTableTableManager(
      $_db,
      $_db.clusters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clusterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RatingsTable, List<RatingRow>> _ratingsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ratings,
    aliasName: 'photos__id__ratings__photo_id',
  );

  $$RatingsTableProcessedTableManager get ratingsRefs {
    final manager = $$RatingsTableTableManager(
      $_db,
      $_db.ratings,
    ).filter((f) => f.photoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ratingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ObservationsTable, List<ObservationRow>>
  _subjectObservationsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.observations,
    aliasName: 'photos__id__observations__subject_id',
  );

  $$ObservationsTableProcessedTableManager get subjectObservations {
    final manager = $$ObservationsTableTableManager(
      $_db,
      $_db.observations,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _subjectObservationsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ObservationsTable, List<ObservationRow>>
  _opponentObservationsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.observations,
    aliasName: 'photos__id__observations__opponent_id',
  );

  $$ObservationsTableProcessedTableManager get opponentObservations {
    final manager = $$ObservationsTableTableManager(
      $_db,
      $_db.observations,
    ).filter((f) => f.opponentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _opponentObservationsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ViewsTable, List<ViewRow>> _viewsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.views,
    aliasName: 'photos__id__views__photo_id',
  );

  $$ViewsTableProcessedTableManager get viewsRefs {
    final manager = $$ViewsTableTableManager(
      $_db,
      $_db.views,
    ).filter((f) => f.photoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_viewsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastShownAt => $composableBuilder(
    column: $table.lastShownAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get views => $composableBuilder(
    column: $table.views,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get missing => $composableBuilder(
    column: $table.missing,
    builder: (column) => ColumnFilters(column),
  );

  $$ClustersTableFilterComposer get clusterId {
    final $$ClustersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clusterId,
      referencedTable: $db.clusters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClustersTableFilterComposer(
            $db: $db,
            $table: $db.clusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ratingsRefs(
    Expression<bool> Function($$RatingsTableFilterComposer f) f,
  ) {
    final $$RatingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ratings,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingsTableFilterComposer(
            $db: $db,
            $table: $db.ratings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> subjectObservations(
    Expression<bool> Function($$ObservationsTableFilterComposer f) f,
  ) {
    final $$ObservationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.observations,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObservationsTableFilterComposer(
            $db: $db,
            $table: $db.observations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> opponentObservations(
    Expression<bool> Function($$ObservationsTableFilterComposer f) f,
  ) {
    final $$ObservationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.observations,
      getReferencedColumn: (t) => t.opponentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObservationsTableFilterComposer(
            $db: $db,
            $table: $db.observations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> viewsRefs(
    Expression<bool> Function($$ViewsTableFilterComposer f) f,
  ) {
    final $$ViewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.views,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ViewsTableFilterComposer(
            $db: $db,
            $table: $db.views,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastShownAt => $composableBuilder(
    column: $table.lastShownAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get views => $composableBuilder(
    column: $table.views,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get missing => $composableBuilder(
    column: $table.missing,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClustersTableOrderingComposer get clusterId {
    final $$ClustersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clusterId,
      referencedTable: $db.clusters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClustersTableOrderingComposer(
            $db: $db,
            $table: $db.clusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastShownAt => $composableBuilder(
    column: $table.lastShownAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get views =>
      $composableBuilder(column: $table.views, builder: (column) => column);

  GeneratedColumn<bool> get missing =>
      $composableBuilder(column: $table.missing, builder: (column) => column);

  $$ClustersTableAnnotationComposer get clusterId {
    final $$ClustersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clusterId,
      referencedTable: $db.clusters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClustersTableAnnotationComposer(
            $db: $db,
            $table: $db.clusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ratingsRefs<T extends Object>(
    Expression<T> Function($$RatingsTableAnnotationComposer a) f,
  ) {
    final $$RatingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ratings,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingsTableAnnotationComposer(
            $db: $db,
            $table: $db.ratings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> subjectObservations<T extends Object>(
    Expression<T> Function($$ObservationsTableAnnotationComposer a) f,
  ) {
    final $$ObservationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.observations,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObservationsTableAnnotationComposer(
            $db: $db,
            $table: $db.observations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> opponentObservations<T extends Object>(
    Expression<T> Function($$ObservationsTableAnnotationComposer a) f,
  ) {
    final $$ObservationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.observations,
      getReferencedColumn: (t) => t.opponentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObservationsTableAnnotationComposer(
            $db: $db,
            $table: $db.observations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> viewsRefs<T extends Object>(
    Expression<T> Function($$ViewsTableAnnotationComposer a) f,
  ) {
    final $$ViewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.views,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ViewsTableAnnotationComposer(
            $db: $db,
            $table: $db.views,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotosTable,
          PhotoRow,
          $$PhotosTableFilterComposer,
          $$PhotosTableOrderingComposer,
          $$PhotosTableAnnotationComposer,
          $$PhotosTableCreateCompanionBuilder,
          $$PhotosTableUpdateCompanionBuilder,
          (PhotoRow, $$PhotosTableReferences),
          PhotoRow,
          PrefetchHooks Function({
            bool clusterId,
            bool ratingsRefs,
            bool subjectObservations,
            bool opponentObservations,
            bool viewsRefs,
          })
        > {
  $$PhotosTableTableManager(_$AppDatabase db, $PhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<DateTime?> takenAt = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int?> clusterId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime?> lastShownAt = const Value.absent(),
                Value<int> views = const Value.absent(),
                Value<bool> missing = const Value.absent(),
              }) => PhotosCompanion(
                id: id,
                mediaId: mediaId,
                albumId: albumId,
                takenAt: takenAt,
                modifiedAt: modifiedAt,
                width: width,
                height: height,
                clusterId: clusterId,
                addedAt: addedAt,
                lastShownAt: lastShownAt,
                views: views,
                missing: missing,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String mediaId,
                Value<String?> albumId = const Value.absent(),
                Value<DateTime?> takenAt = const Value.absent(),
                Value<DateTime?> modifiedAt = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int?> clusterId = const Value.absent(),
                required DateTime addedAt,
                Value<DateTime?> lastShownAt = const Value.absent(),
                Value<int> views = const Value.absent(),
                Value<bool> missing = const Value.absent(),
              }) => PhotosCompanion.insert(
                id: id,
                mediaId: mediaId,
                albumId: albumId,
                takenAt: takenAt,
                modifiedAt: modifiedAt,
                width: width,
                height: height,
                clusterId: clusterId,
                addedAt: addedAt,
                lastShownAt: lastShownAt,
                views: views,
                missing: missing,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PhotosTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                clusterId = false,
                ratingsRefs = false,
                subjectObservations = false,
                opponentObservations = false,
                viewsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ratingsRefs) db.ratings,
                    if (subjectObservations) db.observations,
                    if (opponentObservations) db.observations,
                    if (viewsRefs) db.views,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (clusterId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.clusterId,
                            referencedTable: $$PhotosTableReferences
                                ._clusterIdTable(db),
                            referencedColumn: $$PhotosTableReferences
                                ._clusterIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ratingsRefs)
                        await $_getPrefetchedData<
                          PhotoRow,
                          $PhotosTable,
                          RatingRow
                        >(
                          currentTable: table,
                          referencedTable: $$PhotosTableReferences
                              ._ratingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PhotosTableReferences(
                                db,
                                table,
                                p0,
                              ).ratingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.photoId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (subjectObservations)
                        await $_getPrefetchedData<
                          PhotoRow,
                          $PhotosTable,
                          ObservationRow
                        >(
                          currentTable: table,
                          referencedTable: $$PhotosTableReferences
                              ._subjectObservationsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PhotosTableReferences(
                                db,
                                table,
                                p0,
                              ).subjectObservations,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.subjectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (opponentObservations)
                        await $_getPrefetchedData<
                          PhotoRow,
                          $PhotosTable,
                          ObservationRow
                        >(
                          currentTable: table,
                          referencedTable: $$PhotosTableReferences
                              ._opponentObservationsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PhotosTableReferences(
                                db,
                                table,
                                p0,
                              ).opponentObservations,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.opponentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (viewsRefs)
                        await $_getPrefetchedData<
                          PhotoRow,
                          $PhotosTable,
                          ViewRow
                        >(
                          currentTable: table,
                          referencedTable: $$PhotosTableReferences
                              ._viewsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PhotosTableReferences(db, table, p0).viewsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.photoId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotosTable,
      PhotoRow,
      $$PhotosTableFilterComposer,
      $$PhotosTableOrderingComposer,
      $$PhotosTableAnnotationComposer,
      $$PhotosTableCreateCompanionBuilder,
      $$PhotosTableUpdateCompanionBuilder,
      (PhotoRow, $$PhotosTableReferences),
      PhotoRow,
      PrefetchHooks Function({
        bool clusterId,
        bool ratingsRefs,
        bool subjectObservations,
        bool opponentObservations,
        bool viewsRefs,
      })
    >;
typedef $$AxesTableCreateCompanionBuilder = AxesCompanion Function({
  Value<int> id,
  required String name,
  Value<bool> isDefault,
});
typedef $$AxesTableUpdateCompanionBuilder = AxesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<bool> isDefault,
});

final class $$AxesTableReferences
    extends BaseReferences<_$AppDatabase, $AxesTable, AxisRow> {
  $$AxesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RatingsTable, List<RatingRow>> _ratingsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ratings,
    aliasName: 'axes__id__ratings__axis_id',
  );

  $$RatingsTableProcessedTableManager get ratingsRefs {
    final manager = $$RatingsTableTableManager(
      $_db,
      $_db.ratings,
    ).filter((f) => f.axisId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ratingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ObservationsTable, List<ObservationRow>>
  _observationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.observations,
    aliasName: 'axes__id__observations__axis_id',
  );

  $$ObservationsTableProcessedTableManager get observationsRefs {
    final manager = $$ObservationsTableTableManager(
      $_db,
      $_db.observations,
    ).filter((f) => f.axisId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_observationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AxesTableFilterComposer extends Composer<_$AppDatabase, $AxesTable> {
  $$AxesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ratingsRefs(
    Expression<bool> Function($$RatingsTableFilterComposer f) f,
  ) {
    final $$RatingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ratings,
      getReferencedColumn: (t) => t.axisId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingsTableFilterComposer(
            $db: $db,
            $table: $db.ratings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> observationsRefs(
    Expression<bool> Function($$ObservationsTableFilterComposer f) f,
  ) {
    final $$ObservationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.observations,
      getReferencedColumn: (t) => t.axisId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObservationsTableFilterComposer(
            $db: $db,
            $table: $db.observations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AxesTableOrderingComposer extends Composer<_$AppDatabase, $AxesTable> {
  $$AxesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AxesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AxesTable> {
  $$AxesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  Expression<T> ratingsRefs<T extends Object>(
    Expression<T> Function($$RatingsTableAnnotationComposer a) f,
  ) {
    final $$RatingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ratings,
      getReferencedColumn: (t) => t.axisId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingsTableAnnotationComposer(
            $db: $db,
            $table: $db.ratings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> observationsRefs<T extends Object>(
    Expression<T> Function($$ObservationsTableAnnotationComposer a) f,
  ) {
    final $$ObservationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.observations,
      getReferencedColumn: (t) => t.axisId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObservationsTableAnnotationComposer(
            $db: $db,
            $table: $db.observations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AxesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AxesTable,
          AxisRow,
          $$AxesTableFilterComposer,
          $$AxesTableOrderingComposer,
          $$AxesTableAnnotationComposer,
          $$AxesTableCreateCompanionBuilder,
          $$AxesTableUpdateCompanionBuilder,
          (AxisRow, $$AxesTableReferences),
          AxisRow,
          PrefetchHooks Function({bool ratingsRefs, bool observationsRefs})
        > {
  $$AxesTableTableManager(_$AppDatabase db, $AxesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AxesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AxesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AxesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isDefault = const Value.absent(),
          }) => AxesCompanion(id: id, name: name, isDefault: isDefault),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<bool> isDefault = const Value.absent(),
          }) => AxesCompanion.insert(id: id, name: name, isDefault: isDefault),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AxesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({ratingsRefs = false, observationsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ratingsRefs) db.ratings,
                    if (observationsRefs) db.observations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ratingsRefs)
                        await $_getPrefetchedData<
                          AxisRow,
                          $AxesTable,
                          RatingRow
                        >(
                          currentTable: table,
                          referencedTable: $$AxesTableReferences
                              ._ratingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AxesTableReferences(db, table, p0).ratingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.axisId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (observationsRefs)
                        await $_getPrefetchedData<
                          AxisRow,
                          $AxesTable,
                          ObservationRow
                        >(
                          currentTable: table,
                          referencedTable: $$AxesTableReferences
                              ._observationsRefsTable(db),
                          managerFromTypedResult: (p0) => $$AxesTableReferences(
                            db,
                            table,
                            p0,
                          ).observationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.axisId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AxesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AxesTable,
      AxisRow,
      $$AxesTableFilterComposer,
      $$AxesTableOrderingComposer,
      $$AxesTableAnnotationComposer,
      $$AxesTableCreateCompanionBuilder,
      $$AxesTableUpdateCompanionBuilder,
      (AxisRow, $$AxesTableReferences),
      AxisRow,
      PrefetchHooks Function({bool ratingsRefs, bool observationsRefs})
    >;
typedef $$RatingsTableCreateCompanionBuilder = RatingsCompanion Function({
  required int photoId,
  required int axisId,
  Value<double> mu,
  Value<double> rd,
  Value<int> observations,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$RatingsTableUpdateCompanionBuilder = RatingsCompanion Function({
  Value<int> photoId,
  Value<int> axisId,
  Value<double> mu,
  Value<double> rd,
  Value<int> observations,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$RatingsTableReferences
    extends BaseReferences<_$AppDatabase, $RatingsTable, RatingRow> {
  $$RatingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PhotosTable _photoIdTable(_$AppDatabase db) =>
      db.photos.createAlias('ratings__photo_id__photos__id');

  $$PhotosTableProcessedTableManager get photoId {
    final $_column = $_itemColumn<int>('photo_id')!;

    final manager = $$PhotosTableTableManager(
      $_db,
      $_db.photos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_photoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AxesTable _axisIdTable(_$AppDatabase db) =>
      db.axes.createAlias('ratings__axis_id__axes__id');

  $$AxesTableProcessedTableManager get axisId {
    final $_column = $_itemColumn<int>('axis_id')!;

    final manager = $$AxesTableTableManager(
      $_db,
      $_db.axes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_axisIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RatingsTableFilterComposer
    extends Composer<_$AppDatabase, $RatingsTable> {
  $$RatingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get mu => $composableBuilder(
    column: $table.mu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rd => $composableBuilder(
    column: $table.rd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get observations => $composableBuilder(
    column: $table.observations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PhotosTableFilterComposer get photoId {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AxesTableFilterComposer get axisId {
    final $$AxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.axisId,
      referencedTable: $db.axes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AxesTableFilterComposer(
            $db: $db,
            $table: $db.axes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RatingsTableOrderingComposer
    extends Composer<_$AppDatabase, $RatingsTable> {
  $$RatingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get mu => $composableBuilder(
    column: $table.mu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rd => $composableBuilder(
    column: $table.rd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get observations => $composableBuilder(
    column: $table.observations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PhotosTableOrderingComposer get photoId {
    final $$PhotosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableOrderingComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AxesTableOrderingComposer get axisId {
    final $$AxesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.axisId,
      referencedTable: $db.axes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AxesTableOrderingComposer(
            $db: $db,
            $table: $db.axes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RatingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RatingsTable> {
  $$RatingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get mu =>
      $composableBuilder(column: $table.mu, builder: (column) => column);

  GeneratedColumn<double> get rd =>
      $composableBuilder(column: $table.rd, builder: (column) => column);

  GeneratedColumn<int> get observations => $composableBuilder(
    column: $table.observations,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PhotosTableAnnotationComposer get photoId {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AxesTableAnnotationComposer get axisId {
    final $$AxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.axisId,
      referencedTable: $db.axes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AxesTableAnnotationComposer(
            $db: $db,
            $table: $db.axes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RatingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RatingsTable,
          RatingRow,
          $$RatingsTableFilterComposer,
          $$RatingsTableOrderingComposer,
          $$RatingsTableAnnotationComposer,
          $$RatingsTableCreateCompanionBuilder,
          $$RatingsTableUpdateCompanionBuilder,
          (RatingRow, $$RatingsTableReferences),
          RatingRow,
          PrefetchHooks Function({bool photoId, bool axisId})
        > {
  $$RatingsTableTableManager(_$AppDatabase db, $RatingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RatingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RatingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RatingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> photoId = const Value.absent(),
                Value<int> axisId = const Value.absent(),
                Value<double> mu = const Value.absent(),
                Value<double> rd = const Value.absent(),
                Value<int> observations = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatingsCompanion(
                photoId: photoId,
                axisId: axisId,
                mu: mu,
                rd: rd,
                observations: observations,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int photoId,
                required int axisId,
                Value<double> mu = const Value.absent(),
                Value<double> rd = const Value.absent(),
                Value<int> observations = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RatingsCompanion.insert(
                photoId: photoId,
                axisId: axisId,
                mu: mu,
                rd: rd,
                observations: observations,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RatingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({photoId = false, axisId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (photoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.photoId,
                        referencedTable: $$RatingsTableReferences._photoIdTable(
                          db,
                        ),
                        referencedColumn: $$RatingsTableReferences
                            ._photoIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (axisId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.axisId,
                        referencedTable: $$RatingsTableReferences._axisIdTable(
                          db,
                        ),
                        referencedColumn: $$RatingsTableReferences
                            ._axisIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RatingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RatingsTable,
      RatingRow,
      $$RatingsTableFilterComposer,
      $$RatingsTableOrderingComposer,
      $$RatingsTableAnnotationComposer,
      $$RatingsTableCreateCompanionBuilder,
      $$RatingsTableUpdateCompanionBuilder,
      (RatingRow, $$RatingsTableReferences),
      RatingRow,
      PrefetchHooks Function({bool photoId, bool axisId})
    >;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<int> cards,
  Value<String> mixJson,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<int> cards,
  Value<String> mixJson,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, SessionRow> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ObservationsTable, List<ObservationRow>>
  _observationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.observations,
    aliasName: 'sessions__id__observations__session_id',
  );

  $$ObservationsTableProcessedTableManager get observationsRefs {
    final manager = $$ObservationsTableTableManager(
      $_db,
      $_db.observations,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_observationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cards => $composableBuilder(
    column: $table.cards,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mixJson => $composableBuilder(
    column: $table.mixJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> observationsRefs(
    Expression<bool> Function($$ObservationsTableFilterComposer f) f,
  ) {
    final $$ObservationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.observations,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObservationsTableFilterComposer(
            $db: $db,
            $table: $db.observations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cards => $composableBuilder(
    column: $table.cards,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mixJson => $composableBuilder(
    column: $table.mixJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get cards =>
      $composableBuilder(column: $table.cards, builder: (column) => column);

  GeneratedColumn<String> get mixJson =>
      $composableBuilder(column: $table.mixJson, builder: (column) => column);

  Expression<T> observationsRefs<T extends Object>(
    Expression<T> Function($$ObservationsTableAnnotationComposer a) f,
  ) {
    final $$ObservationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.observations,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ObservationsTableAnnotationComposer(
            $db: $db,
            $table: $db.observations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          SessionRow,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (SessionRow, $$SessionsTableReferences),
          SessionRow,
          PrefetchHooks Function({bool observationsRefs})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> cards = const Value.absent(),
                Value<String> mixJson = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                cards: cards,
                mixJson: mixJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> cards = const Value.absent(),
                Value<String> mixJson = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                cards: cards,
                mixJson: mixJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({observationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (observationsRefs) db.observations],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (observationsRefs)
                    await $_getPrefetchedData<
                      SessionRow,
                      $SessionsTable,
                      ObservationRow
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._observationsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SessionsTableReferences(
                        db,
                        table,
                        p0,
                      ).observationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      SessionRow,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (SessionRow, $$SessionsTableReferences),
      SessionRow,
      PrefetchHooks Function({bool observationsRefs})
    >;
typedef $$ObservationsTableCreateCompanionBuilder =
    ObservationsCompanion Function({
      Value<int> id,
      required int axisId,
      Value<int?> sessionId,
      required String cardId,
      required String mode,
      required int subjectId,
      Value<int?> opponentId,
      Value<double?> anchorMu,
      required String outcome,
      Value<double> weight,
      required DateTime createdAt,
      required double subjectMuBefore,
      required double subjectRdBefore,
      Value<double?> opponentMuBefore,
      Value<double?> opponentRdBefore,
    });
typedef $$ObservationsTableUpdateCompanionBuilder =
    ObservationsCompanion Function({
      Value<int> id,
      Value<int> axisId,
      Value<int?> sessionId,
      Value<String> cardId,
      Value<String> mode,
      Value<int> subjectId,
      Value<int?> opponentId,
      Value<double?> anchorMu,
      Value<String> outcome,
      Value<double> weight,
      Value<DateTime> createdAt,
      Value<double> subjectMuBefore,
      Value<double> subjectRdBefore,
      Value<double?> opponentMuBefore,
      Value<double?> opponentRdBefore,
    });

final class $$ObservationsTableReferences
    extends BaseReferences<_$AppDatabase, $ObservationsTable, ObservationRow> {
  $$ObservationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AxesTable _axisIdTable(_$AppDatabase db) =>
      db.axes.createAlias('observations__axis_id__axes__id');

  $$AxesTableProcessedTableManager get axisId {
    final $_column = $_itemColumn<int>('axis_id')!;

    final manager = $$AxesTableTableManager(
      $_db,
      $_db.axes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_axisIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('observations__session_id__sessions__id');

  $$SessionsTableProcessedTableManager? get sessionId {
    final $_column = $_itemColumn<int>('session_id');
    if ($_column == null) return null;
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PhotosTable _subjectIdTable(_$AppDatabase db) =>
      db.photos.createAlias('observations__subject_id__photos__id');

  $$PhotosTableProcessedTableManager get subjectId {
    final $_column = $_itemColumn<int>('subject_id')!;

    final manager = $$PhotosTableTableManager(
      $_db,
      $_db.photos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PhotosTable _opponentIdTable(_$AppDatabase db) =>
      db.photos.createAlias('observations__opponent_id__photos__id');

  $$PhotosTableProcessedTableManager? get opponentId {
    final $_column = $_itemColumn<int>('opponent_id');
    if ($_column == null) return null;
    final manager = $$PhotosTableTableManager(
      $_db,
      $_db.photos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_opponentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ObservationsTableFilterComposer
    extends Composer<_$AppDatabase, $ObservationsTable> {
  $$ObservationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get anchorMu => $composableBuilder(
    column: $table.anchorMu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subjectMuBefore => $composableBuilder(
    column: $table.subjectMuBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subjectRdBefore => $composableBuilder(
    column: $table.subjectRdBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get opponentMuBefore => $composableBuilder(
    column: $table.opponentMuBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get opponentRdBefore => $composableBuilder(
    column: $table.opponentRdBefore,
    builder: (column) => ColumnFilters(column),
  );

  $$AxesTableFilterComposer get axisId {
    final $$AxesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.axisId,
      referencedTable: $db.axes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AxesTableFilterComposer(
            $db: $db,
            $table: $db.axes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PhotosTableFilterComposer get subjectId {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PhotosTableFilterComposer get opponentId {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.opponentId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ObservationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ObservationsTable> {
  $$ObservationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get anchorMu => $composableBuilder(
    column: $table.anchorMu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subjectMuBefore => $composableBuilder(
    column: $table.subjectMuBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subjectRdBefore => $composableBuilder(
    column: $table.subjectRdBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get opponentMuBefore => $composableBuilder(
    column: $table.opponentMuBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get opponentRdBefore => $composableBuilder(
    column: $table.opponentRdBefore,
    builder: (column) => ColumnOrderings(column),
  );

  $$AxesTableOrderingComposer get axisId {
    final $$AxesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.axisId,
      referencedTable: $db.axes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AxesTableOrderingComposer(
            $db: $db,
            $table: $db.axes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PhotosTableOrderingComposer get subjectId {
    final $$PhotosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableOrderingComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PhotosTableOrderingComposer get opponentId {
    final $$PhotosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.opponentId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableOrderingComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ObservationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ObservationsTable> {
  $$ObservationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<double> get anchorMu =>
      $composableBuilder(column: $table.anchorMu, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<double> get subjectMuBefore => $composableBuilder(
    column: $table.subjectMuBefore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subjectRdBefore => $composableBuilder(
    column: $table.subjectRdBefore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get opponentMuBefore => $composableBuilder(
    column: $table.opponentMuBefore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get opponentRdBefore => $composableBuilder(
    column: $table.opponentRdBefore,
    builder: (column) => column,
  );

  $$AxesTableAnnotationComposer get axisId {
    final $$AxesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.axisId,
      referencedTable: $db.axes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AxesTableAnnotationComposer(
            $db: $db,
            $table: $db.axes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PhotosTableAnnotationComposer get subjectId {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PhotosTableAnnotationComposer get opponentId {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.opponentId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ObservationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ObservationsTable,
          ObservationRow,
          $$ObservationsTableFilterComposer,
          $$ObservationsTableOrderingComposer,
          $$ObservationsTableAnnotationComposer,
          $$ObservationsTableCreateCompanionBuilder,
          $$ObservationsTableUpdateCompanionBuilder,
          (ObservationRow, $$ObservationsTableReferences),
          ObservationRow,
          PrefetchHooks Function({
            bool axisId,
            bool sessionId,
            bool subjectId,
            bool opponentId,
          })
        > {
  $$ObservationsTableTableManager(_$AppDatabase db, $ObservationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ObservationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ObservationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ObservationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> axisId = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int> subjectId = const Value.absent(),
                Value<int?> opponentId = const Value.absent(),
                Value<double?> anchorMu = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<double> weight = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<double> subjectMuBefore = const Value.absent(),
                Value<double> subjectRdBefore = const Value.absent(),
                Value<double?> opponentMuBefore = const Value.absent(),
                Value<double?> opponentRdBefore = const Value.absent(),
              }) => ObservationsCompanion(
                id: id,
                axisId: axisId,
                sessionId: sessionId,
                cardId: cardId,
                mode: mode,
                subjectId: subjectId,
                opponentId: opponentId,
                anchorMu: anchorMu,
                outcome: outcome,
                weight: weight,
                createdAt: createdAt,
                subjectMuBefore: subjectMuBefore,
                subjectRdBefore: subjectRdBefore,
                opponentMuBefore: opponentMuBefore,
                opponentRdBefore: opponentRdBefore,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int axisId,
                Value<int?> sessionId = const Value.absent(),
                required String cardId,
                required String mode,
                required int subjectId,
                Value<int?> opponentId = const Value.absent(),
                Value<double?> anchorMu = const Value.absent(),
                required String outcome,
                Value<double> weight = const Value.absent(),
                required DateTime createdAt,
                required double subjectMuBefore,
                required double subjectRdBefore,
                Value<double?> opponentMuBefore = const Value.absent(),
                Value<double?> opponentRdBefore = const Value.absent(),
              }) => ObservationsCompanion.insert(
                id: id,
                axisId: axisId,
                sessionId: sessionId,
                cardId: cardId,
                mode: mode,
                subjectId: subjectId,
                opponentId: opponentId,
                anchorMu: anchorMu,
                outcome: outcome,
                weight: weight,
                createdAt: createdAt,
                subjectMuBefore: subjectMuBefore,
                subjectRdBefore: subjectRdBefore,
                opponentMuBefore: opponentMuBefore,
                opponentRdBefore: opponentRdBefore,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ObservationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                axisId = false,
                sessionId = false,
                subjectId = false,
                opponentId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (axisId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.axisId,
                            referencedTable: $$ObservationsTableReferences
                                ._axisIdTable(db),
                            referencedColumn: $$ObservationsTableReferences
                                ._axisIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (sessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sessionId,
                            referencedTable: $$ObservationsTableReferences
                                ._sessionIdTable(db),
                            referencedColumn: $$ObservationsTableReferences
                                ._sessionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (subjectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.subjectId,
                            referencedTable: $$ObservationsTableReferences
                                ._subjectIdTable(db),
                            referencedColumn: $$ObservationsTableReferences
                                ._subjectIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (opponentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.opponentId,
                            referencedTable: $$ObservationsTableReferences
                                ._opponentIdTable(db),
                            referencedColumn: $$ObservationsTableReferences
                                ._opponentIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ObservationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ObservationsTable,
      ObservationRow,
      $$ObservationsTableFilterComposer,
      $$ObservationsTableOrderingComposer,
      $$ObservationsTableAnnotationComposer,
      $$ObservationsTableCreateCompanionBuilder,
      $$ObservationsTableUpdateCompanionBuilder,
      (ObservationRow, $$ObservationsTableReferences),
      ObservationRow,
      PrefetchHooks Function({
        bool axisId,
        bool sessionId,
        bool subjectId,
        bool opponentId,
      })
    >;
typedef $$ViewsTableCreateCompanionBuilder = ViewsCompanion Function({
  Value<int> id,
  required int photoId,
  required DateTime viewedAt,
  required String source,
  Value<int> dwellMs,
});
typedef $$ViewsTableUpdateCompanionBuilder = ViewsCompanion Function({
  Value<int> id,
  Value<int> photoId,
  Value<DateTime> viewedAt,
  Value<String> source,
  Value<int> dwellMs,
});

final class $$ViewsTableReferences
    extends BaseReferences<_$AppDatabase, $ViewsTable, ViewRow> {
  $$ViewsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PhotosTable _photoIdTable(_$AppDatabase db) =>
      db.photos.createAlias('views__photo_id__photos__id');

  $$PhotosTableProcessedTableManager get photoId {
    final $_column = $_itemColumn<int>('photo_id')!;

    final manager = $$PhotosTableTableManager(
      $_db,
      $_db.photos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_photoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ViewsTableFilterComposer extends Composer<_$AppDatabase, $ViewsTable> {
  $$ViewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get viewedAt => $composableBuilder(
    column: $table.viewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dwellMs => $composableBuilder(
    column: $table.dwellMs,
    builder: (column) => ColumnFilters(column),
  );

  $$PhotosTableFilterComposer get photoId {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ViewsTableOrderingComposer
    extends Composer<_$AppDatabase, $ViewsTable> {
  $$ViewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get viewedAt => $composableBuilder(
    column: $table.viewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dwellMs => $composableBuilder(
    column: $table.dwellMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$PhotosTableOrderingComposer get photoId {
    final $$PhotosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableOrderingComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ViewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ViewsTable> {
  $$ViewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get viewedAt =>
      $composableBuilder(column: $table.viewedAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get dwellMs =>
      $composableBuilder(column: $table.dwellMs, builder: (column) => column);

  $$PhotosTableAnnotationComposer get photoId {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ViewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ViewsTable,
          ViewRow,
          $$ViewsTableFilterComposer,
          $$ViewsTableOrderingComposer,
          $$ViewsTableAnnotationComposer,
          $$ViewsTableCreateCompanionBuilder,
          $$ViewsTableUpdateCompanionBuilder,
          (ViewRow, $$ViewsTableReferences),
          ViewRow,
          PrefetchHooks Function({bool photoId})
        > {
  $$ViewsTableTableManager(_$AppDatabase db, $ViewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ViewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ViewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ViewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> photoId = const Value.absent(),
                Value<DateTime> viewedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> dwellMs = const Value.absent(),
              }) => ViewsCompanion(
                id: id,
                photoId: photoId,
                viewedAt: viewedAt,
                source: source,
                dwellMs: dwellMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int photoId,
                required DateTime viewedAt,
                required String source,
                Value<int> dwellMs = const Value.absent(),
              }) => ViewsCompanion.insert(
                id: id,
                photoId: photoId,
                viewedAt: viewedAt,
                source: source,
                dwellMs: dwellMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ViewsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({photoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (photoId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.photoId,
                        referencedTable: $$ViewsTableReferences._photoIdTable(
                          db,
                        ),
                        referencedColumn: $$ViewsTableReferences
                            ._photoIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ViewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ViewsTable,
      ViewRow,
      $$ViewsTableFilterComposer,
      $$ViewsTableOrderingComposer,
      $$ViewsTableAnnotationComposer,
      $$ViewsTableCreateCompanionBuilder,
      $$ViewsTableUpdateCompanionBuilder,
      (ViewRow, $$ViewsTableReferences),
      ViewRow,
      PrefetchHooks Function({bool photoId})
    >;
typedef $$PrefsTableCreateCompanionBuilder = PrefsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$PrefsTableUpdateCompanionBuilder = PrefsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$PrefsTableFilterComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrefsTable,
          PrefRow,
          $$PrefsTableFilterComposer,
          $$PrefsTableOrderingComposer,
          $$PrefsTableAnnotationComposer,
          $$PrefsTableCreateCompanionBuilder,
          $$PrefsTableUpdateCompanionBuilder,
          (PrefRow, BaseReferences<_$AppDatabase, $PrefsTable, PrefRow>),
          PrefRow,
          PrefetchHooks Function()
        > {
  $$PrefsTableTableManager(_$AppDatabase db, $PrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrefsTable,
      PrefRow,
      $$PrefsTableFilterComposer,
      $$PrefsTableOrderingComposer,
      $$PrefsTableAnnotationComposer,
      $$PrefsTableCreateCompanionBuilder,
      $$PrefsTableUpdateCompanionBuilder,
      (PrefRow, BaseReferences<_$AppDatabase, $PrefsTable, PrefRow>),
      PrefRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ClustersTableTableManager get clusters =>
      $$ClustersTableTableManager(_db, _db.clusters);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db, _db.photos);
  $$AxesTableTableManager get axes => $$AxesTableTableManager(_db, _db.axes);
  $$RatingsTableTableManager get ratings =>
      $$RatingsTableTableManager(_db, _db.ratings);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$ObservationsTableTableManager get observations =>
      $$ObservationsTableTableManager(_db, _db.observations);
  $$ViewsTableTableManager get views =>
      $$ViewsTableTableManager(_db, _db.views);
  $$PrefsTableTableManager get prefs =>
      $$PrefsTableTableManager(_db, _db.prefs);
}
