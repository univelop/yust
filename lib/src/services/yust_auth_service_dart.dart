import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:googleapis/iamcredentials/v1.dart';
import 'package:googleapis/identitytoolkit/v1.dart';
import 'package:http/http.dart';
import 'package:uuid/uuid.dart';

import '../models/yust_filter.dart';
import '../models/yust_user.dart';
import '../util/yust_exception.dart';
import '../yust.dart';
import 'yust_auth_service_shared.dart';

/// Handles auth request for Firebase Auth.
class YustAuthService {
  final IdentityToolkitApi _api;
  final Yust _yust;
  final String? _pathToServiceAccountJson;

  YustAuthService(
    Yust yust, {
    String? emulatorAddress,
    String? pathToServiceAccountJson,
  })  : _yust = yust,
        _pathToServiceAccountJson = pathToServiceAccountJson,
        _api = emulatorAddress != null
            ? IdentityToolkitApi(Yust.authClient!,
                rootUrl: 'http://$emulatorAddress:9099/',
                servicePath: 'identitytoolkit.googleapis.com/')
            : IdentityToolkitApi(Yust.authClient!);

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

  /// Sign in with a token.
  Future<void> signInWithToken(String token) async {
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
    GoogleCloudIdentitytoolkitV1SignUpResponse? response;
    final uuid = Uuid().v4();

    if (useOAuth != true) {
      final newUserRequest = GoogleCloudIdentitytoolkitV1SignUpRequest(
        displayName:
            // ignore: avoid_dynamic_calls
            ('$firstName $lastName').trim(),
        email: email,
        emailVerified: true,
        password: password,
      );
      response = await _api.accounts.signUp(newUserRequest);

      if (response.localId == null) {
        throw YustException('Error creating user: ${response.toJson()}');
      }

      final successfullyLinked = await YustAuthServiceShared.tryLinkYustUser(
        _yust,
        email,
        response.localId ?? uuid,
        YustAuthenticationMethod.mail,
      );
      if (successfullyLinked) return null;
    }

    return await YustAuthServiceShared.createYustUser(
      yust: _yust,
      firstName: firstName,
      email: email,
      lastName: lastName,
      id: response?.localId ?? uuid,
      authId: response?.localId ?? uuid,
      gender: gender,
      authenticationMethod: useOAuth == true
          ? YustAuthenticationMethod.openId
          : YustAuthenticationMethod.mail,
    );
  }

  Future<YustUser> addUserNamePasswordToAccount(String email, String password,
      {List<String> allowedProviderIds = const []}) async {
    final user = await _yust.dbService.getFirst<YustUser>(
      Yust.userSetup,
      filters: [
        YustFilter(
          field: 'email',
          comparator: YustFilterComparator.equal,
          value: email,
        ),
      ],
    );

    if (user == null) {
      throw YustException('User not found');
    }

    if (user.authenticationMethod == YustAuthenticationMethod.mail) {
      throw YustException('User already has a password');
    }

    if (user.authId == null) {
      throw YustException('User has no authId');
    }

    if (user.email.toLowerCase() != email.toLowerCase()) {
      throw YustException('YustUser email does not match');
    }

    final lookupRequest = GoogleCloudIdentitytoolkitV1GetAccountInfoRequest(
      localId: [user.authId!],
    );
    final lookupResult =
        await _api.projects.accounts_1.lookup(lookupRequest, Yust.projectId);

    if (lookupResult.users == null || lookupResult.users!.isEmpty) {
      throw YustException(
          'User for authId ${user.authId} not found in Firebase Auth');
    }

    if (lookupResult.users!.length > 1) {
      throw YustException(
          'Multiple users found for authId ${user.authId} in Firebase Auth');
    }

    final firebaseUser = lookupResult.users!.first;

    if (firebaseUser.email?.toLowerCase() != email.toLowerCase()) {
      throw YustException('Firebase User email does not match');
    }

    if (firebaseUser.providerUserInfo?.isEmpty ?? true) {
      throw YustException('Firebase User has no configured auth providers');
    }

    if (firebaseUser.providerUserInfo!
        .any((info) => info.providerId == 'password')) {
      throw YustUserAlreadyHasPasswordException('User already has a password');
    }

    if (allowedProviderIds.isNotEmpty &&
        firebaseUser.providerUserInfo!
            .any((info) => !allowedProviderIds.contains(info.providerId))) {
      throw YustProviderNotAllowed(
        'User has an unsupported auth provider',
        providerIds: firebaseUser.providerUserInfo!
            .map((info) => info.providerId)
            .whereType<String>()
            .toList(),
      );
    }

    final info = GoogleCloudIdentitytoolkitV1SetAccountInfoRequest(
      localId: firebaseUser.localId,
      password: password,
    );
    await _api.projects.accounts_1.update(info, Yust.projectId);
    return user;
  }

  JWT _createUnsignedJWTForAuthId(String authId, serviceAccountEmail) {
    return JWT(
      {'uid': authId},
      subject: serviceAccountEmail,
      issuer: serviceAccountEmail,
      header: {'alg': 'RS256', 'typ': 'JWT'},
      audience: Audience([
        'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
      ]),
    );
  }

  Future<String> _getServiceAccountEmailFromMetadata() async {
    final uri = Uri.parse(
        'http://metadata/computeMetadata/v1/instance/service-accounts/default/email');
    final result = await get(uri, headers: {'Metadata-Flavor': 'Google'});
    return result.body;
  }

  Future<String> getAuthTokenForAuthId(String authId) async {
    final String serviceAccountEmail;
    Map? serviceAccountKey;
    if (_pathToServiceAccountJson != null) {
      final rawFileText = await File(_pathToServiceAccountJson).readAsString();
      final decodedKey = jsonDecode(rawFileText);

      if (decodedKey == null || decodedKey is! Map) {
        throw YustException('Could not read service account key');
      }
      serviceAccountKey = decodedKey;
      serviceAccountEmail = serviceAccountKey['client_email'];
    } else {
      try {
        serviceAccountEmail = await _getServiceAccountEmailFromMetadata();
      } catch (e) {
        throw YustException(
            'Could not get service account email from metadata: $e');
      }
    }

    final jwt = _createUnsignedJWTForAuthId(authId, serviceAccountEmail);

    if (serviceAccountKey != null) {
      final jwtToken = jwt.sign(
        RSAPrivateKey(serviceAccountKey['private_key']),
        algorithm: JWTAlgorithm.RS256,
        expiresIn: const Duration(seconds: 3600),
      );
      return jwtToken;
    } else {
      final iamClient = IAMCredentialsApi(Yust.authClient!);
      final delegate = 'projects/-/serviceAccounts/$serviceAccountEmail';
      final signRequest = SignJwtRequest(payload: jsonEncode(jwt.payload));
      final SignJwtResponse signingResponse;
      try {
        signingResponse = await iamClient.projects.serviceAccounts
            .signJwt(signRequest, delegate);
      } catch (e) {
        throw YustException('Could not sign JWT: $e');
      }
      final signedJwt = signingResponse.signedJwt;
      if (signedJwt == null) {
        throw YustException('Could not sign JWT');
      }
      return signedJwt;
    }
  }

  Future<void> deleteAccount([String? password]) async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  Future<String?> getJWTToken() async {
    throw UnsupportedError('Not supported. No UI available.');
  }
}
