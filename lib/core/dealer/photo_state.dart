import '../rating/glicko.dart';

/// Everything the dealer and sampler need to know about a photo on one axis.
class PhotoState {
  const PhotoState({
    required this.id,
    required this.rating,
    this.takenAt,
    this.addedAt,
    this.lastShownAt,
    this.clusterId,
    this.observations = 0,
    this.views = 0,
    this.mediaId,
  });

  final int id;
  final Rating rating;
  final DateTime? takenAt;
  final DateTime? addedAt;
  final DateTime? lastShownAt;
  final int? clusterId;
  final int observations;
  final int views;

  /// Device media id (photo_manager asset id); null in pure-core tests.
  final String? mediaId;

  double get mu => rating.mu;
  double get rd => rating.rd;
  bool get unseen => lastShownAt == null;

  PhotoState copyWith({Rating? rating, DateTime? lastShownAt, int? views}) =>
      PhotoState(
        id: id,
        rating: rating ?? this.rating,
        takenAt: takenAt,
        addedAt: addedAt,
        lastShownAt: lastShownAt ?? this.lastShownAt,
        clusterId: clusterId,
        observations: observations,
        views: views ?? this.views,
        mediaId: mediaId,
      );
}
