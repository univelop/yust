import 'package:json_annotation/json_annotation.dart';

import '../yust.dart';
import 'yust_doc.dart';
import 'yust_doc_setup.dart';

part 'yust_notification.g.dart';

/// A representation of a push notification.
@JsonSerializable()
class YustNotification extends YustDoc {
  static YustDocSetup<YustNotification> setup(String userId) =>
      YustDocSetup<YustNotification>(
        userId: userId,
        collectionName: 'notifications',
        newDoc: () => YustNotification(),
        fromJson: (json) => YustNotification.fromJson(json),
        hasOwner: true,
      );

  /// Optional collection the notification is for.
  String? forCollection;

  /// Optional document id the notification is for.
  String? forDocId;

  /// Optional deep link to open when the notification is clicked.
  String? deepLink;

  /// Title of the notification.
  String? title;

  /// Body of the notification.
  String? body;

  /// Date and time the notification should be dispatched.
  ///
  /// If not set, the notification will be dispatched immediately.
  DateTime? dispatchAt;

  /// Whether the notification has been delivered successfully.
  bool delivered;

  /// Additional data
  Map<String, dynamic> data;

  /// Date and time the notification was read by the user.
  ///
  /// Use [markRead] and [markUnread] to change this value.
  DateTime? readAt;

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

  /// Mark the notification as read.
  ///
  /// NOTE: This will automatically delete the notification after 30 days.
  void markRead() {
    // Auto-Delete after 30 days
    expiresAt = Yust.helpers.utcNow().add(const Duration(days: 30));
    readAt = Yust.helpers.utcNow();
  }

  /// Mark the notification as unread.
  ///
  /// This will also remove the auto-delete.
  void markUnread() {
    expiresAt = null;
    readAt = null;
  }

  /// Whether the notification has been read by the user.
  bool get isRead => readAt != null;

  /// Whether the notification has not been read by the user.
  ///
  /// (Or marked unread again afterwards)
  bool get isUnread => readAt == null;

  @override
  Map<String, dynamic> toJson() => _$YustNotificationToJson(this);
}
