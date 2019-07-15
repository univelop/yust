// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustUser _$YustUserFromJson(Map<String, dynamic> json) {
  return YustUser(
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String)
    ..id = json['id'] as String
    ..createdAt = json['createdAt'] as String
    ..userId = json['userId'] as String
    ..envId = json['envId'] as String
    ..envIds = (json['envIds'] as List)?.map((e) => e as String)?.toList()
    ..currEnvId = json['currEnvId'] as String;
}

Map<String, dynamic> _$YustUserToJson(YustUser instance) => <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt,
      'userId': instance.userId,
      'envId': instance.envId,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'envIds': instance.envIds,
      'currEnvId': instance.currEnvId
    };
