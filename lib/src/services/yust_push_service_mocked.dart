import 'dart:async';

import 'yust_push_service.dart';

/// Handles auth request for Firebase Auth.
class YustPushServiceMocked extends YustPushService {
  YustPushServiceMocked() : super.mocked();

  @override
  Future<void> sendToDevice({
    required String token,
    required String title,
    required String body,
    String? image,
  }) async {}
}
