import 'dart:async';

import 'yust_push_service.dart';

/// Sends out Push notifications via Firebase Cloud Messaging
class YustPushServiceMocked extends YustPushService {
  YustPushServiceMocked() : super.mocked();

  @override
  Future<void> sendToDevice({
    required String deviceId,
    required String title,
    required String body,
    String? image,
  }) async {}
}
