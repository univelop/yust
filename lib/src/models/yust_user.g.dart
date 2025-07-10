// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustUser _$YustUserFromJson(Map json) => YustUser(
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      gender: $enumDecodeNullable(_$YustGenderEnumMap, json['gender'],
          unknownValue: JsonKey.nullForUndefinedEnumValue),
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
      ..envIds = (json['envIds'] as Map?)?.map(
            (k, e) => MapEntry(k as String, e as bool?),
          ) ??
          {}
      ..currEnvId = json['currEnvId'] as String?
      ..deviceIds = (json['deviceIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..lastLogin = json['lastLogin'] == null
          ? null
          : DateTime.parse(json['lastLogin'] as String)
      ..lastLoginDomain = json['lastLoginDomain'] as String?
      ..authenticationMethod = $enumDecodeNullable(
          _$YustAuthenticationMethodEnumMap, json['authenticationMethod'],
          unknownValue: JsonKey.nullForUndefinedEnumValue)
      ..domain = json['domain'] as String?
      ..profilePicture = json['profilePicture'] == null
          ? null
          : YustImage.fromJson(
              Map<String, dynamic>.from(json['profilePicture'] as Map))
      ..userAttributes = (json['userAttributes'] as Map?)?.map(
            (k, e) => MapEntry(k as String, e),
          ) ??
          {};

Map<String, dynamic> _$YustUserToJson(YustUser instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'createdAt': instance.createdAt?.toIso8601String(),
    'createdBy': instance.createdBy,
    'modifiedAt': instance.modifiedAt?.toIso8601String(),
    'modifiedBy': instance.modifiedBy,
    'userId': instance.userId,
    'envId': instance.envId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('expiresAt', instance.expiresAt?.toIso8601String());
  val['email'] = instance.email;
  val['firstName'] = instance.firstName;
  val['lastName'] = instance.lastName;
  val['gender'] = _$YustGenderEnumMap[instance.gender];
  val['envIds'] = instance.envIds;
  val['currEnvId'] = instance.currEnvId;
  val['deviceIds'] = instance.deviceIds;
  val['lastLogin'] = instance.lastLogin?.toIso8601String();
  val['lastLoginDomain'] = instance.lastLoginDomain;
  val['authenticationMethod'] =
      _$YustAuthenticationMethodEnumMap[instance.authenticationMethod];
  val['domain'] = instance.domain;
  val['authId'] = instance.authId;
  val['profilePicture'] = instance.profilePicture?.toJson();
  val['locale'] = instance.locale;
  val['userAttributes'] = instance.userAttributes;
  return val;
}

const _$YustGenderEnumMap = {
  YustGender.male: 'male',
  YustGender.female: 'female',
};

const _$YustAuthenticationMethodEnumMap = {
  YustAuthenticationMethod.mail: 'mail',
  YustAuthenticationMethod.microsoft: 'microsoft',
  YustAuthenticationMethod.google: 'google',
  YustAuthenticationMethod.apple: 'apple',
  YustAuthenticationMethod.openId: 'openId',
};
