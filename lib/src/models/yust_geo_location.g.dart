// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_geo_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustGeoLocation _$YustGeoLocationFromJson(Map json) => YustGeoLocation(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      address: json['address'] == null
          ? const YustAddress()
          : YustAddress.fromJson(
              Map<String, dynamic>.from(json['address'] as Map)),
    );

Map<String, dynamic> _$YustGeoLocationToJson(YustGeoLocation instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy': instance.accuracy,
      'address': instance.address.toJson(),
    };
