import 'dart:async';

import 'package:googleapis/fcm/v1.dart';
import 'package:http/http.dart';

import '../models/yust_user.dart';
import '../yust.dart';

/// Handles push notifications via Firebase Cloud Messaging.
class YustPushService {
  late final FirebaseCloudMessagingApi _api;
  final Client _authClient;
  final String _projectId;

  YustPushService()
      : _authClient = Yust.authClient!,
        _projectId = Yust.projectId {
    _api = FirebaseCloudMessagingApi(_authClient);
  }

  Future<void> sendToDevice({
    required String token,
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
      token: token,
    );
    final request = SendMessageRequest(message: message);
    await _api.projects.messages.send(request, 'projects/$_projectId');
  }

  Future<void> sendToUser({
    required YustUser user,
    required String title,
    required String body,
    String? image,
    FutureOr<void> Function(String deviceId, Object error)? onErrorForDevice,
  }) async {
    for (final deviceId in user.deviceIds!) {
      try {
        await sendToDevice(
          token: deviceId,
          title: title,
          body: body,
          image: image,
        );
      } catch (e) {
        await onErrorForDevice?.call(deviceId, e);
      }
    }
  }
}
