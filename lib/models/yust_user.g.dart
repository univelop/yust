// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustUser _$YustUserFromJson(Map json) {
  return YustUser(
    email: json['email'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    gender: _$enumDecodeNullable(_$YustGenderEnumMap, json['gender']),
  )
    ..id = json['id'] as String
    ..createdAt = json['createdAt'] as String
    ..userId = json['userId'] as String
    ..envId = json['envId'] as String
    ..envIds = (json['envIds'] as Map)?.map(
      (k, e) => MapEntry(k as String, e as bool),
    )
    ..currEnvId = json['currEnvId'] as String
    ..deviceIds =
        (json['deviceIds'] as List)?.map((e) => e as String)?.toList();
}

Map<String, dynamic> _$YustUserToJson(YustUser instance) => <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt,
      'userId': instance.userId,
      'envId': instance.envId,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'gender': _$YustGenderEnumMap[instance.gender],
      'envIds': instance.envIds,
      'currEnvId': instance.currEnvId,
      'deviceIds': instance.deviceIds,
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$YustGenderEnumMap = {
  YustGender.male: 'male',
  YustGender.female: 'female',
};
