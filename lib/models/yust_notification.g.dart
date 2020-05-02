// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustNotification _$YustNotificationFromJson(Map json) {
  return YustNotification(
    forCollection: json['forCollection'] as String,
    forDocId: json['forDocId'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
  )
    ..id = json['id'] as String
    ..createdAt = YustDoc.dateTimeFromJson(json['createdAt'])
    ..userId = json['userId'] as String
    ..envId = json['envId'] as String
    ..data = (json['data'] as Map)?.map(
      (k, e) => MapEntry(k as String, e),
    );
}

Map<String, dynamic> _$YustNotificationToJson(YustNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': YustDoc.dateTimeToJson(instance.createdAt),
      'userId': instance.userId,
      'envId': instance.envId,
      'forCollection': instance.forCollection,
      'forDocId': instance.forDocId,
      'title': instance.title,
      'body': instance.body,
      'data': instance.data,
    };
