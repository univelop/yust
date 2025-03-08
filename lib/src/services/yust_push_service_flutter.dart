import 'dart:async';

import '../models/yust_user.dart';

/// Handles auth request for Firebase Auth.
class YustPushService {
  YustPushService();

  Future<void> sendToDevice({
    required String token,
    required String title,
    required String body,
    String? image,
  }) async {
    throw UnimplementedError();
  }

  Future<void> sendToUser({
    required YustUser user,
    required String title,
    required String body,
    String? image,
    FutureOr<void> Function(String deviceId, Object error)? onErrorForDevice,
  }) async {
    throw UnimplementedError();
  }
}
