import 'dart:async';

import 'package:googleapis/fcm/v1.dart';
import 'package:http/http.dart';

import '../models/yust_user.dart';
import '../yust.dart';

/// Sends out Push notifications via Firebase Cloud Messaging
class YustPushService {
  late final FirebaseCloudMessagingApi _api;
  late final Client _authClient;
  late final String _projectId;

  YustPushService()
      : _authClient = Yust.authClient!,
        _projectId = Yust.projectId {
    _api = FirebaseCloudMessagingApi(_authClient);
  }

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
    final message = Message(
      notification: Notification(
        title: title,
        body: body,
        image: image,
      ),
      token: deviceId,
    );
    final request = SendMessageRequest(message: message);
    await _api.projects.messages.send(request, 'projects/$_projectId');
  }

  /// Sends Push Notifications to all devices of a user.
  Future<void> sendToUser({
    required YustUser user,
    required String title,
    required String body,
    String? image,
    FutureOr<void> Function(
            String deviceId, Object error, StackTrace stackTrace)?
        onErrorForDevice,
  }) async {
    for (final deviceId in user.deviceIds ?? []) {
      try {
        await sendToDevice(
          deviceId: deviceId,
          title: title,
          body: body,
          image: image,
        );
      } catch (e, s) {
        await onErrorForDevice?.call(deviceId, e, s);
      }
    }
  }
}
