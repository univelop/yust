import 'package:uuid/uuid.dart';

import '../../yust.dart';

import 'yust_auth_service.dart';

class YustAuthServiceMocked implements YustAuthService {
  final Yust _yust;

  YustAuthServiceMocked(Yust yust) : _yust = yust;

  @override
  Future<YustUser?> createAccount(
      String firstName, String lastName, String email, String password,
      {YustGender? gender, bool useOAuth = false}) {
    final id = Uuid().v4();

    return YustAuthServiceShared.createYustUser(
      yust: _yust,
      firstName: firstName,
      lastName: lastName,
      email: email,
      id: id,
      authId: id,
    );
  }

  @override
  Future<void> changeEmail(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<void> changePassword(String newPassword, String oldPassword) =>
      throw UnimplementedError();

  @override
  Future<void> checkPassword(String password) => throw UnimplementedError();

  @override
  Future<void> deleteAccount([String? password]) => throw UnimplementedError();

  @override
  Stream<AuthState> getAuthStateStream() => throw UnimplementedError();

  @override
  String? getCurrentUserId() => throw UnimplementedError();

  @override
  Future<String?> getJWTToken() => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<void> signIn(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<YustUser?> signInWithApple() => throw UnimplementedError();

  @override
  Future<YustUser?> signInWithGithub() => throw UnimplementedError();

  @override
  Future<YustUser?> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<YustUser?> signInWithMicrosoft() => throw UnimplementedError();

  @override
  Future<YustUser?> signInWithOpenId(String providerId) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}
