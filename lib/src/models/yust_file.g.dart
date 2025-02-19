// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustFile _$YustFileFromJson(Map json) => YustFile(
      name: json['name'] as String?,
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      url: json['url'] as String?,
      hash: json['hash'] as String? ?? '',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$YustFileToJson(YustFile instance) => <String, dynamic>{
      'name': instance.name,
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'url': instance.url,
      'hash': instance.hash,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
