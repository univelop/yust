// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustUser _$YustUserFromJson(Map json) =>
    YustUser(
        email: json['email'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        gender: $enumDecodeNullable(
          _$YustGenderEnumMap,
          json['gender'],
          unknownValue: JsonKey.nullForUndefinedEnumValue,
        ),
        authId: json['authId'] as String?,
        locale: json['locale'] as String?,
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
      ..expiresAt = json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String)
      .._envIds =
          (json['envIds'] as Map?)?.map(
            (k, e) => MapEntry(k as String, e as bool?),
          ) ??
          {}
      ..currEnvId = json['currEnvId'] as String?
      .._deviceIds =
          (json['deviceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          []
      ..lastLogin = json['lastLogin'] == null
          ? null
          : DateTime.parse(json['lastLogin'] as String)
      ..lastLoginDomain = json['lastLoginDomain'] as String?
      ..authenticationMethod = $enumDecodeNullable(
        _$YustAuthenticationMethodEnumMap,
        json['authenticationMethod'],
        unknownValue: JsonKey.nullForUndefinedEnumValue,
      )
      ..domain = json['domain'] as String?
      ..profilePicture = json['profilePicture'] == null
          ? null
          : YustImage.fromJson(
              Map<String, dynamic>.from(json['profilePicture'] as Map),
            )
      .._userAttributes =
          (json['userAttributes'] as Map?)?.map(
            (k, e) => MapEntry(k as String, e),
          ) ??
          {};

Map<String, dynamic> _$YustUserToJson(YustUser instance) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt?.toIso8601String(),
  'createdBy': instance.createdBy,
  'modifiedAt': instance.modifiedAt?.toIso8601String(),
  'modifiedBy': instance.modifiedBy,
  'userId': instance.userId,
  'envId': instance.envId,
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'email': instance.email,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'gender': _$YustGenderEnumMap[instance.gender],
  'envIds': instance._envIds,
  'currEnvId': instance.currEnvId,
  'deviceIds': instance._deviceIds,
  'lastLogin': instance.lastLogin?.toIso8601String(),
  'lastLoginDomain': instance.lastLoginDomain,
  'authenticationMethod':
      _$YustAuthenticationMethodEnumMap[instance.authenticationMethod],
  'domain': instance.domain,
  'authId': instance.authId,
  'profilePicture': instance.profilePicture?.toJson(),
  'locale': instance.locale,
  'userAttributes': instance._userAttributes,
};

const _$YustGenderEnumMap = {
  YustGender.male: 'male',
  YustGender.female: 'female',
  YustGender.nonBinary: 'nonBinary',
  YustGender.other: 'other',
  YustGender.preferNotToSay: 'preferNotToSay',
};

const _$YustAuthenticationMethodEnumMap = {
  YustAuthenticationMethod.mail: 'mail',
  YustAuthenticationMethod.microsoft: 'microsoft',
  YustAuthenticationMethod.google: 'google',
  YustAuthenticationMethod.apple: 'apple',
  YustAuthenticationMethod.openId: 'openId',
};
