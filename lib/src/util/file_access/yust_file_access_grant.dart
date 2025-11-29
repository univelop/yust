import 'package:json_annotation/json_annotation.dart';
part 'yust_file_access_grant.g.dart';

/// Access grant which allows access to all files below a given path prefix.
@JsonSerializable()
class YustFileAccessGrant {
  const YustFileAccessGrant({
    required this.pathPrefix,
    required this.originalSignedUrlPart,
    required this.thumbnailSignedUrlPart,
  });

  /// Creates a new file access grant from a JSON map.
  factory YustFileAccessGrant.fromJson(Map<String, dynamic> json) =>
      _$YustFileAccessGrantFromJson(json);

  /// The path prefix of the grant.
  final String pathPrefix;

  /// The signed URL part for the original files.
  ///
  /// Must be appended to the file url
  final String originalSignedUrlPart;

  /// The signed URL part for the thumbnail files.
  ///
  /// Must be appended to the thumbnail url
  final String thumbnailSignedUrlPart;

  /// Converts the file access grant to a JSON map.
  Map<String, dynamic> toJson() => _$YustFileAccessGrantToJson(this);
}
