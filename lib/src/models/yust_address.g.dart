// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustAddress _$YustAddressFromJson(Map json) => YustAddress(
  street: json['street'] as String?,
  number: json['number'] as String?,
  postcode: json['postcode'] as String?,
  city: json['city'] as String?,
  country: json['country'] as String?,
);

Map<String, dynamic> _$YustAddressToJson(YustAddress instance) =>
    <String, dynamic>{
      'street': instance.street,
      'number': instance.number,
      'postcode': instance.postcode,
      'city': instance.city,
      'country': instance.country,
    };
