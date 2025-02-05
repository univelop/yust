// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustImage _$YustImageFromJson(Map json) => YustImage(
      name: json['name'] as String?,
      url: json['url'] as String?,
      geoLocation: json['geoLocation'] == null
          ? null
          : YustGeoLocation.fromJson(
              Map<String, dynamic>.from(json['geoLocation'] as Map)),
      hash: json['hash'] as String?,
    )..modifiedAt = json['modifiedAt'] == null
        ? null
        : DateTime.parse(json['modifiedAt'] as String);

Map<String, dynamic> _$YustImageToJson(YustImage instance) => <String, dynamic>{
      'name': instance.name,
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'url': instance.url,
      'hash': instance.hash,
      'geoLocation': instance.geoLocation?.toJson(),
    };
