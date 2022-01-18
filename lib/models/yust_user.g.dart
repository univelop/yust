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
      ..createdAt = YustDoc.convertTimestamp(json['createdAt'])
      ..createdBy = json['createdBy'] as String?
      ..modifiedAt = YustDoc.convertTimestamp(json['modifiedAt'])
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
      'createdAt': YustDoc.convertToTimestamp(instance.createdAt),
      'createdBy': instance.createdBy,
      'modifiedAt': YustDoc.convertToTimestamp(instance.modifiedAt),
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

const _$YustGenderEnumMap = {
  YustGender.male: 'male',
  YustGender.female: 'female',
};
