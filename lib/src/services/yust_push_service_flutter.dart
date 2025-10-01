import 'dart:async';

import '../models/yust_user.dart';

/// Sends out Push notifications via Firebase Cloud Messaging
class YustPushService {
  YustPushService();

  YustPushService.mocked();

  /// Sends a Push Notification to the device with token [deviceId]
  /// You can specify a title and body.
  /// Additionally you can specify a image that is shown in the Notification
  /// by specifying a Url to the [image].
  Future<void> sendToDevice({
    required String deviceId,
    required String title,
    required String body,
    String? image,
  }) async {
    throw UnimplementedError();
  }

  /// Sends Push Notifications to all devices of a user.
  Future<void> sendToUser({
    required YustUser user,
    required String title,
    required String body,
    String? image,
    FutureOr<void> Function(
      String deviceId,
      Object error,
      StackTrace stackTrace,
    )?
    onErrorForDevice,
  }) async {
    throw UnimplementedError();
  }
}
