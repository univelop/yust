import 'dart:async';

import '../models/yust_user.dart';
import '../yust.dart';

/// Handels auth request for Firebase Auth.
class YustAuthService {
  // ignore: avoid_unused_constructor_parameters
  YustAuthService({String? emulatorAddress});

  YustAuthService.mocked();

  /// Returns the current [AuthState] in a Steam.
  Stream<AuthState> get authStateStream {
    throw UnsupportedError('Not supported. No UI available.');
  }

  String? getCurrentUserId() => null;

  /// Sign in by email and password.
  Future<void> signIn(
    String email,
    String password,
  ) async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  /// Sign up a new user.
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

  /// Sign out the current user.
  Future<void> signOut() async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  /// Send an email to reset the user password.
  Future<void> sendPasswordResetEmail(String email) async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  /// Change the user email.
  Future<void> changeEmail(String email, String password) async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  /// Change the user password.
  Future<void> changePassword(String newPassword, String oldPassword) async {
    throw UnsupportedError('Not supported. No UI available.');
  }
}
