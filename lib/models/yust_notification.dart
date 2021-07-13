import 'package:json_annotation/json_annotation.dart';
import 'package:yust/models/yust_doc.dart';
import 'package:yust/models/yust_doc_setup.dart';

part 'yust_notification.g.dart';

@JsonSerializable(anyMap: true)
class YustNotification extends YustDoc {
  static final setup = YustDocSetup<YustNotification>(
    collectionName: 'notifications',
    newDoc: () => YustNotification(),
    fromJson: (json) => YustNotification.fromJson(json),
  );

  String? forCollection;
  String? forDocId;
  String? title;
  String? body;
  Map<String, dynamic> data = {};

  YustNotification({
    this.forCollection,
    this.forDocId,
    this.title,
    this.body,
  }) : super();

  factory YustNotification.fromJson(Map<String, dynamic> json) =>
      _$YustNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$YustNotificationToJson(this);
}
