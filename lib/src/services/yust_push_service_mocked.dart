import 'dart:async';

import 'yust_push_service.dart';

/// Sends out Push notifications via Firebase Cloud Messaging
class YustPushServiceMocked extends YustPushService {
  static YustPushServiceMocked? instance;

  YustPushServiceMocked._() : super.mocked();

  factory YustPushServiceMocked() {
    return instance ?? YustPushServiceMocked._();
  }

  @override
  Future<void> sendToDevice({
    required String deviceId,
    required String title,
    required String body,
    String? image,
  }) async {}
}
