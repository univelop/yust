// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$YustFileToJson(YustFile instance) => <String, dynamic>{
      'name': instance.name,
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'url': instance.url,
      'hash': instance.hash,
      'createdAt': instance.createdAt?.toIso8601String(),
      'path': instance.path,
      'thumbnails': instance.thumbnails
          ?.map((k, e) => MapEntry(_$YustFileThumbnailSizeEnumMap[k]!, e)),
    };

const _$YustFileThumbnailSizeEnumMap = {
  YustFileThumbnailSize.small: 'small',
};
