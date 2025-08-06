// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustImage _$YustImageFromJson(Map json) => YustImage(
      name: json['name'] as String?,
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      url: json['url'] as String?,
      hash: json['hash'] as String? ?? '',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      location: json['location'] == null
          ? null
          : YustGeoLocation.fromJson(
              Map<String, dynamic>.from(json['location'] as Map)),
    );

Map<String, dynamic> _$YustImageToJson(YustImage instance) => <String, dynamic>{
      'name': instance.name,
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'url': instance.url,
      'hash': instance.hash,
      'createdAt': instance.createdAt?.toIso8601String(),
      'location': instance.location?.toJson(),
    };
