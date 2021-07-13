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
    ..createdAt = YustDoc.dateTimeFromJson(json['createdAt'])
    ..createdBy = json['createdBy'] as String?
    ..modifiedAt = YustDoc.dateTimeFromJson(json['modifiedAt'])
    ..modifiedBy = json['modifiedBy'] as String?
    ..userId = json['userId'] as String?
    ..envId = json['envId'] as String?
    ..envIds = Map<String, bool>.from(json['envIds'] as Map)
    ..currEnvId = json['currEnvId'] as String?
    ..deviceIds =
        (json['deviceIds'] as List<dynamic>?)?.map((e) => e as String).toList();
}

Map<String, dynamic> _$YustUserToJson(YustUser instance) => <String, dynamic>{
      'id': instance.id,
      'createdAt': YustDoc.dateTimeToJson(instance.createdAt),
      'createdBy': instance.createdBy,
      'modifiedAt': YustDoc.dateTimeToJson(instance.modifiedAt),
      'modifiedBy': instance.modifiedBy,
      'userId': instance.userId,
      'envId': instance.envId,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'gender': _$YustGenderEnumMap[instance.gender],
      'envIds': YustDoc.mapToJson(instance.envIds),
      'currEnvId': instance.currEnvId,
      'deviceIds': instance.deviceIds,
    };

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

K? _$enumDecodeNullable<K, V>(
  Map<K, V> enumValues,
  dynamic source, {
  K? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<K, V>(enumValues, source, unknownValue: unknownValue);
}

const _$YustGenderEnumMap = {
  YustGender.male: 'male',
  YustGender.female: 'female',
};
