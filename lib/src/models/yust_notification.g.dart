// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustNotification _$YustNotificationFromJson(Map json) =>
    YustNotification(
        forCollection: json['forCollection'] as String?,
        forDocId: json['forDocId'] as String?,
        deepLink: json['deepLink'] as String?,
        title: json['title'] as String?,
        body: json['body'] as String?,
        dispatchAt: json['dispatchAt'] == null
            ? null
            : DateTime.parse(json['dispatchAt'] as String),
        delivered: json['delivered'] as bool? ?? false,
        data:
            (json['data'] as Map?)?.map((k, e) => MapEntry(k as String, e)) ??
            const {},
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
      ..readAt = json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String);

Map<String, dynamic> _$YustNotificationToJson(YustNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt?.toIso8601String(),
      'createdBy': instance.createdBy,
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'modifiedBy': instance.modifiedBy,
      'userId': instance.userId,
      'envId': instance.envId,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'forCollection': instance.forCollection,
      'forDocId': instance.forDocId,
      'deepLink': instance.deepLink,
      'title': instance.title,
      'body': instance.body,
      'dispatchAt': instance.dispatchAt?.toIso8601String(),
      'delivered': instance.delivered,
      'data': instance.data,
      'readAt': instance.readAt?.toIso8601String(),
    };
