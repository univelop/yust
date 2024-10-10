import 'dart:async';

import 'package:googleapis/identitytoolkit/v3.dart';
import 'package:uuid/uuid.dart';

import '../models/yust_filter.dart';
import '../models/yust_user.dart';
import '../util/google_cloud_helpers.dart';
import '../util/yust_exception.dart';
import '../yust.dart';

/// Handles auth request for Firebase Auth.
class YustAuthService {
  YustAuthService({String? emulatorAddress});

  YustAuthService.mocked();

  /// Returns the current [AuthState] in a Stream.
  Stream<AuthState> getAuthStateStream() {
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

  /// Sign in with Microsoft. If a new user was created, return the user.
  /// A Microsoft app must be registered in the Firebase console.
  Future<YustUser?> signInWithMicrosoft() async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  /// Sign in with GitHub. If a new user was created, return the user.
  /// A GitHub app must be registered in the Firebase console.
  Future<YustUser?> signInWithGithub() async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  /// Sign in with Google. If a new user was created, return the user.
  /// The Google Authentication method must be activated in the Firebase console.
  Future<YustUser?> signInWithGoogle() async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  /// Sign in with Apple. If a new user was created, return the user.
  /// The Apple Authentication method must be activated in the Firebase console.
  Future<YustUser?> signInWithApple() async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  /// Sign in with a configured OpenID. If a new user was created, return the user.
  /// The Authentication method must be configured in the Firebase console.
  Future<YustUser?> signInWithOpenId(String providerId) async {
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

  /// Checks if the password is valid.
  /// Throws an error if the password is invalid or the user does not exist / has no email.
  Future<void> checkPassword(String password) async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  Future<YustUser?> createAccount(
    String firstName,
    String lastName,
    String email,
    String password, {
    YustGender? gender,
    bool useOAuth = false,
  }) async {
    final response = null;
    final uuid = Uuid().v4();

    if (useOAuth == true) {
      final scopes = [
        IdentityToolkitApi.cloudPlatformScope,
        IdentityToolkitApi.firebaseScope,
      ];
      final client = await GoogleCloudHelpers.createAuthClient(scopes: scopes);
      final api = IdentityToolkitApi(client);

      final newUserRequest = IdentitytoolkitRelyingpartySignupNewUserRequest(
        localId: uuid,
        displayName:
            // ignore: avoid_dynamic_calls
            ('$firstName $lastName').trim(),
        email: email,
        emailVerified: true,
        password: password,
      );
      final response = await api.relyingparty.signupNewUser(newUserRequest);

      if (response.localId == null) {
        throw YustException('Error creating user: ${response.toJson()}');
      }

      final successfullyLinked =
          await _tryLinkYustUser(response, YustAuthenticationMethod.mail);
      if (successfullyLinked) return null;
    }

    return await _createUser(
      firstName: firstName,
      email: email,
      lastName: lastName,
      id: response.localId! ?? uuid,
      authId: response.localId! ?? uuid,
      gender: gender,
      authenticationMethod: useOAuth == true
          ? YustAuthenticationMethod.openId
          : YustAuthenticationMethod.mail,
    );
  }

  // If modified also modify in yust_auth_service_flutter.dart
  Future<YustUser> _createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String id,
    required String authId,
    YustAuthenticationMethod? authenticationMethod,
    String? domain,
    YustGender? gender,
  }) async {
    final user = Yust.userSetup.newDoc()
      ..email = email
      ..firstName = firstName
      ..lastName = lastName
      ..id = id
      ..authId = authId
      ..authenticationMethod = authenticationMethod
      ..domain = domain ?? email.split('@').last
      ..gender = gender
      ..lastLogin = DateTime.now()
      ..lastLoginDomain =
          Uri.base.scheme.contains('http') ? Uri.base.host : null;
    await Yust.databaseService.saveDoc<YustUser>(Yust.userSetup, user);
    return user;
  }

  // If modified also modify in yust_auth_service_flutter.dart
  Future<bool> _tryLinkYustUser(
    SignupNewUserResponse userCredential,
    YustAuthenticationMethod? method,
  ) async {
    if (userCredential.email == null ||
        userCredential.email!.isEmpty ||
        userCredential.localId == null ||
        userCredential.localId!.isEmpty) {
      return false;
    }
    final user = await Yust.databaseService.getFirst<YustUser>(
      Yust.userSetup,
      filters: [
        YustFilter(
          field: 'email',
          comparator: YustFilterComparator.equal,
          value: userCredential.email,
        ),
      ],
    );
    if (user == null) return false;
    await user.linkAuth(userCredential.localId as String, method);
    return true;
  }

  Future<void> deleteAccount([String? password]) async {
    throw UnsupportedError('Not supported. No UI available.');
  }
}
