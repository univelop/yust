// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustUser _$YustUserFromJson(Map json) => YustUser(
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      gender: $enumDecodeNullable(_$YustGenderEnumMap, json['gender']),
    )
      ..id = json['id'] as String
      ..createdAt = json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String)
      ..createdBy = json['createdBy'] as String?
      ..modifiedAt = json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String)
      ..modifiedBy = json['modifiedBy'] as String?
      ..userId = json['userId'] as String?
      ..envId = json['envId'] as String?
      ..envIds = Map<String, bool?>.from(json['envIds'] as Map)
      ..currEnvId = json['currEnvId'] as String?
      ..deviceIds = (json['deviceIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList();

Map<String, dynamic> _$YustUserToJson(YustUser instance) => <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt?.toIso8601String(),
      'createdBy': instance.createdBy,
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'modifiedBy': instance.modifiedBy,
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

const _$YustGenderEnumMap = {
  YustGender.male: 'male',
  YustGender.female: 'female',
};
