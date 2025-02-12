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
      location: json['location'] == null
          ? null
          : YustGeoLocation.fromJson(
              Map<String, dynamic>.from(json['geoLocation'] as Map)),
    );

Map<String, dynamic> _$YustImageToJson(YustImage instance) => <String, dynamic>{
      'name': instance.name,
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'url': instance.url,
      'hash': instance.hash,
      'geoLocation': instance.location?.toJson(),
    };
