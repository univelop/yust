import 'package:json_annotation/json_annotation.dart';
part 'yust_file_access_grant.g.dart';

@JsonSerializable()
class YustFileAccessGrant {
  const YustFileAccessGrant({
    required this.pathPrefix,
    required this.originalSignedUrlPart,
    required this.thumbnailSignedUrlPart,
  });

  factory YustFileAccessGrant.fromJson(Map<String, dynamic> json) =>
      _$YustFileAccessGrantFromJson(json);

  final String pathPrefix;
  final String originalSignedUrlPart;
  final String thumbnailSignedUrlPart;

  Map<String, dynamic> toJson() => _$YustFileAccessGrantToJson(this);
}
