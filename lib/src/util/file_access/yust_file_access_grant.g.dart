// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_file_access_grant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustFileAccessGrant _$YustFileAccessGrantFromJson(Map json) =>
    YustFileAccessGrant(
      pathPrefix: json['pathPrefix'] as String,
      originalSignedUrlPart: json['originalSignedUrlPart'] as String,
      thumbnailSignedUrlPart: json['thumbnailSignedUrlPart'] as String?,
    );

Map<String, dynamic> _$YustFileAccessGrantToJson(
  YustFileAccessGrant instance,
) => <String, dynamic>{
  'pathPrefix': instance.pathPrefix,
  'originalSignedUrlPart': instance.originalSignedUrlPart,
  'thumbnailSignedUrlPart': instance.thumbnailSignedUrlPart,
};
