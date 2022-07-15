import 'dart:async';
import '../models/yust_user.dart';
import '../yust.dart';

class YustAuthService {
  YustAuthService();

  YustAuthService.mocked();

  Stream<AuthState> get authStateStream {
    throw UnsupportedError('Not supported. No UI available.');
  }

  String? get currUserId => null;

  Future<void> signIn(
    String email,
    String password,
  ) async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  Future<void> signUp(
    String firstName,
    String lastName,
    String email,
    String password,
    String passwordConfirmation, {
    YustGender? gender,
  }) async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  Future<void> signOut() async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  Future<void> sendPasswordResetEmail(String email) async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  Future<void> changeEmail(String email, String password) async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  Future<void> changePassword(String newPassword, String oldPassword) async {
    throw UnsupportedError('Not supported. No UI available.');
  }
}
