import 'package:json_annotation/json_annotation.dart';

import 'yust_doc.dart';
import 'yust_doc_setup.dart';

part 'yust_notification.g.dart';

Map<String, dynamic> dataFromJson(data) => Map<String, dynamic>.from(data);

/// A representation of a push notification.
@JsonSerializable()
class YustNotification extends YustDoc {
  static YustDocSetup<YustNotification> setup(String userId) =>
      YustDocSetup<YustNotification>(
        userId: userId,
        collectionName: 'notifications',
        newDoc: YustNotification.new,
        fromJson: YustNotification.fromJson,
        hasOwner: true,
      );

  String? forCollection;
  String? forDocId;
  String? deepLink;
  String? title;
  String? body;
  DateTime? dispatchAt;
  bool delivered;
  Map<String, dynamic> data;

  YustNotification({
    this.forCollection,
    this.forDocId,
    this.deepLink,
    this.title,
    this.body,
    this.dispatchAt,
    this.delivered = false,
    this.data = const {},
  }) : super();

  factory YustNotification.fromJson(Map<String, dynamic> json) =>
      _$YustNotificationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$YustNotificationToJson(this);
}
