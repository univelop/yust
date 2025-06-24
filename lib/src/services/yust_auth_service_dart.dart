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

  /// Add a username and password to an existing account.
  ///
  /// The user account is identified by the email address provided.
  /// This is only allowed if the user account does not already have a password.
  /// If [allowedProviderIds] is provided, the user mustn't
  /// have one of the specified providers.
  /// This can be used to restrict the use of password login to users that
  /// have only been created with a 3rd party provider.
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
      throw YustUserAlreadyHasPasswordException('User already has a password');
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
    // Simply updating the user with the password is enough to enable password login
    await _api.projects.accounts_1.update(info, Yust.projectId);
    return user;
  }

  /// Create an unsigned JWT for a given authId.
  JWT _createUnsignedJWTForAuthId(
      String authId, String subjectAccountMail, String issuerAccountMail) {
    return JWT(
      {'uid': authId},
      subject: subjectAccountMail,
      issuer: issuerAccountMail,
      header: {'alg': 'RS256', 'typ': 'JWT'},
      audience: Audience([
        'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
      ]),
    );
  }

  /// Get the service account email from the metadata server.
  /// This is only available in Google Cloud environments.
  Future<String> _getServiceAccountEmailFromMetadata() async {
    final uri = Uri.parse(
        'http://metadata/computeMetadata/v1/instance/service-accounts/default/email');
    final result = await get(uri, headers: {'Metadata-Flavor': 'Google'});
    return result.body;
  }

  /// Get a valid sign in token for a given auth Id
  ///
  ///  If a Service Account File exists (e.g. in tools & emulator),
  /// we private key & email from the file to create the JWT.
  /// Else we use credentials from the cloud run environment
  Future<String> getAuthTokenForAuthId(String authId,
      {String? overrideEmail}) async {
    String issuerAccountMail;
    String? subjectServiceAccountMail = overrideEmail;
    Map? serviceAccountKey;

    if (_pathToServiceAccountJson != null) {
      final rawFileText = await File(_pathToServiceAccountJson).readAsString();
      final decodedKey = jsonDecode(rawFileText);

      if (decodedKey == null || decodedKey is! Map) {
        throw YustException('Could not read service account key');
      }
      serviceAccountKey = decodedKey;
      subjectServiceAccountMail ??= serviceAccountKey['client_email'];
      issuerAccountMail = serviceAccountKey['client_email'];
      // If we got a service account key file, we can just use the private key provided
      // for signing.
      final jwt = _createUnsignedJWTForAuthId(authId,
          subjectServiceAccountMail ?? issuerAccountMail, issuerAccountMail);
      final signedJwt = jwt.sign(
        RSAPrivateKey(serviceAccountKey['private_key']),
        algorithm: JWTAlgorithm.RS256,
        expiresIn: const Duration(seconds: 3600),
      );
      return signedJwt;
    } else {
      try {
        final metadataEmail = await _getServiceAccountEmailFromMetadata();
        subjectServiceAccountMail ??= metadataEmail;
        issuerAccountMail = metadataEmail;

        final iamClient = IAMCredentialsApi(Yust.authClient!);
        final delegate =
            'projects/-/serviceAccounts/$subjectServiceAccountMail';
        final signRequest = SignJwtRequest(
            payload: jsonEncode({
          'uid': authId,
          'iss': issuerAccountMail,
          'sub': subjectServiceAccountMail,
          'aud':
              'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
          'iat': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
          'exp': (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000) + 3600
        }));
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
      } catch (e) {
        throw YustException(
            'Could not get service account email from metadata: $e');
      }
    }
  }

  Future<void> deleteAccount([String? password]) async {
    throw UnsupportedError('Not supported. No UI available.');
  }

  Future<String?> getJWTToken() async {
    throw UnsupportedError('Not supported. No UI available.');
  }
}
