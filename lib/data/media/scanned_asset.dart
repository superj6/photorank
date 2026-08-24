/// What the library scanner learns about one on-device image. Pure data so
/// the repo layer stays free of photo_manager types.
class ScannedAsset {
  const ScannedAsset({
    required this.mediaId,
    this.albumId,
    this.takenAt,
    this.modifiedAt,
    this.width = 0,
    this.height = 0,
  });

  final String mediaId;
  final String? albumId;
  final DateTime? takenAt;
  final DateTime? modifiedAt;
  final int width;
  final int height;
}
