import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/yust_filter.dart';
import '../models/yust_user.dart';
import '../util/yust_exception.dart';
import '../yust.dart';
import 'yust_auth_service_shared.dart';

class YustAuthService {
  late final FirebaseAuth _fireAuth;
  late final Yust _yust;

  YustAuthService(Yust yust,
      {String? emulatorAddress, String? pathToServiceAccountJson})
      : _fireAuth = FirebaseAuth.instance,
        _yust = yust {
    if (emulatorAddress != null) {
      _fireAuth.useAuthEmulator(emulatorAddress, 9099);
    }
  }

  YustAuthService.mocked(Yust yust) {
    throw UnsupportedError('Not supported in Flutter Environment');
  }

  Stream<AuthState> getAuthStateStream() {
    return _fireAuth.authStateChanges().map<AuthState>((user) {
      if (user != null) {
        Yust.databaseService.getFirstFromDB<YustUser>(
          Yust.userSetup,
          filters: [
            YustFilter(
              comparator: YustFilterComparator.equal,
              field: 'authId',
              value: user.uid,
            ),
          ],
        ).then((yustUser) => yustUser?.setLoginFields());
      }
      return user == null ? AuthState.signedOut : AuthState.signedIn;
    });
  }

  String? getCurrentUserId() => _fireAuth.currentUser?.uid;

  Future<void> signIn(
    String email,
    String password,
  ) async {
    await _fireAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signInWithToken(String token) async {
    await _fireAuth.signInWithCustomToken(token);
  }

  Future<YustUser?> signInWithMicrosoft() async {
    final microsoftProvider = MicrosoftAuthProvider();
    return _signInWithProvider(
        microsoftProvider, YustAuthenticationMethod.microsoft);
  }

  // Future<YustUser?> signInWithGithub() async {
  //   final githubProvider = GithubAuthProvider();
  //   return _signInWithProvider(githubProvider, YustAuthenticationMethod.github);
  // }

  Future<YustUser?> signInWithGoogle() async {
    final googleProvider = GoogleAuthProvider();
    return _signInWithProvider(googleProvider, YustAuthenticationMethod.google);
  }

  Future<YustUser?> signInWithApple() async {
    final appleProvider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    return _signInWithProvider(appleProvider, YustAuthenticationMethod.apple);
  }

  Future<YustUser?> signInWithOpenId(String providerId) async {
    final provider = OAuthProvider(providerId);
    return _signInWithProvider(provider, YustAuthenticationMethod.openId);
  }

  Future<YustUser?> _signInWithProvider(
    AuthProvider provider,
    YustAuthenticationMethod? method, {
    bool redirect = false,
  }) async {
    final userCredential =
        await _signInAndGetUserCredential(provider, redirect: redirect);
    if (_signInFailed(userCredential)) return null;
    final connectedYustUser = await _maybeGetConnectedYustUser(userCredential);
    if (_yustUserWasLinked(connectedYustUser)) return null;

    final successfullyLinked = await YustAuthServiceShared.tryLinkYustUser(
      _yust,
      _getEmail(userCredential),
      _getId(userCredential),
      method,
    );
    if (successfullyLinked) return null;

    final nameParts = _extractNameParts(userCredential);
    final lastName = _getLastName(nameParts);
    final firstName = _getFirstName(nameParts);

    return await YustAuthServiceShared.createYustUser(
      yust: _yust,
      firstName: firstName,
      lastName: lastName,
      email: _getEmail(userCredential),
      id: _getId(userCredential),
      authId: _getId(userCredential),
      authenticationMethod: method,
    );
  }

  String _getId(UserCredential userCredential) => userCredential.user!.uid;

  String _getEmail(UserCredential userCredential) =>
      userCredential.user!.email ?? '';

  String _getFirstName(List<String> nameParts) =>
      nameParts.join(' ').replaceAll(r'+', ' ');

  String _getLastName(List<String> nameParts) => nameParts.removeLast();

  List<String> _extractNameParts(UserCredential userCredential) {
    if (userCredential.user!.displayName == null) {
      throw Exception('No name returned by provider!');
    }
    return userCredential.user!.displayName?.split(' ') ?? [];
  }

  bool _yustUserWasLinked(YustUser? connectedYustUser) =>
      connectedYustUser != null;

  bool _signInFailed(UserCredential userCredential) =>
      userCredential.user == null;

  Future<UserCredential> _signInAndGetUserCredential(AuthProvider provider,
          {bool redirect = false}) async =>
      kIsWeb
          ? redirect
              ? await _fireAuth
                  .signInWithRedirect(provider)
                  .then((value) => _fireAuth.getRedirectResult())
              : await _fireAuth.signInWithPopup(provider)
          : await FirebaseAuth.instance.signInWithProvider(provider);

  Future<YustUser?> _maybeGetConnectedYustUser(
    UserCredential userCredential,
  ) async =>
      (await Yust.databaseService
          .getFirstFromDB<YustUser>(Yust.userSetup, filters: [
        YustFilter(
            field: 'authId',
            comparator: YustFilterComparator.equal,
            value: userCredential.user!.uid)
      ]));

  Future<YustUser?> createAccount(
    String firstName,
    String lastName,
    String email,
    String password, {
    YustGender? gender,
    bool useOAuth = false,
  }) async {
    if (useOAuth == true) {
      throw YustException('OAuth not supported for createAccount.');
    }
    final userCredential = await _fireAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    final successfullyLinked = await YustAuthServiceShared.tryLinkYustUser(
      _yust,
      email,
      userCredential.user!.uid,
      YustAuthenticationMethod.mail,
    );
    if (successfullyLinked) return null;

    return await YustAuthServiceShared.createYustUser(
      yust: _yust,
      firstName: firstName,
      email: email,
      lastName: lastName,
      id: userCredential.user!.uid,
      authId: userCredential.user!.uid,
      gender: gender,
      authenticationMethod: YustAuthenticationMethod.mail,
    );
  }

  Future<void> signOut() async {
    await _fireAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    // ignore: deprecated_member_use
    final loginMethods = await _fireAuth.fetchSignInMethodsForEmail(email);
    if (loginMethods.contains('password')) {
      await _fireAuth.sendPasswordResetEmail(email: email);
    } else {
      throw YustException('Reset password not possible.');
    }
  }

  Future<void> changeEmail(String email, String password) async {
    final user = await Yust.databaseService
        .getFromDB<YustUser>(Yust.userSetup, _fireAuth.currentUser!.uid);
    if (user?.authenticationMethod == null ||
        user?.authenticationMethod == YustAuthenticationMethod.mail) {
      final userCredential = await _fireAuth.signInWithEmailAndPassword(
        email: _fireAuth.currentUser!.email!,
        password: password,
      );
      await userCredential.user!.verifyBeforeUpdateEmail(email);
    }

    if (user != null) {
      user.email = email;
      await Yust.databaseService.saveDoc<YustUser>(Yust.userSetup, user);
    }
  }

  Future<void> changePassword(String newPassword, String oldPassword) async {
    final userCredential = await _fireAuth.signInWithEmailAndPassword(
      email: _fireAuth.currentUser!.email!,
      password: oldPassword,
    );
    await userCredential.user!.updatePassword(newPassword);
  }

  Future<void> checkPassword(String password) async {
    await _fireAuth.currentUser!
        .reauthenticateWithCredential(EmailAuthProvider.credential(
      email: _fireAuth.currentUser!.email!,
      password: password,
    ));
  }

  Future<void> deleteAccount([String? password]) async {
    try {
      final user = _fireAuth.currentUser;
      await user?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && password != null) {
        final user = (await _fireAuth.signInWithEmailAndPassword(
          email: _fireAuth.currentUser!.email!,
          password: password,
        ))
            .user;
        await user?.delete();
      } else {
        rethrow;
      }
    }
  }

  Future<String?> getJWTToken() async {
    final jwtObject = await _fireAuth.currentUser?.getIdTokenResult();
    return jwtObject?.token;
  }

  Future<void> addUserNamePasswordToAccount(String email, String password,
      {List<String> allowedProviderIds = const []}) async {
    throw UnimplementedError();
  }

  Future<String> getAuthTokenForAuthId(String authId,
      {String? overrideEmail}) async {
    throw UnimplementedError();
  }

  /// Checks if the email of the current user is verified.
  /// Returns null if the user is not authenticated or if the authentication method is not email.
  Future<bool?> isEmailVerified() async {
    final firebaseUser = _fireAuth.currentUser;
    if (firebaseUser == null) return null;

    final user = await Yust.databaseService
        .getFromDB<YustUser>(Yust.userSetup, firebaseUser.uid);
    if (user == null) return null;

    // Only relevant for email authentication
    if (user.authenticationMethod != YustAuthenticationMethod.mail) return null;

    // Reload to get the latest user information from Firebase.
    // Note: If the user's email was changed and is now verified, this reload may invalidate the session.
    // In that case, `authStateStream` can emit null, resulting in `AuthState.signedOut`.
    await reloadCurrentUser();
    final refreshedUser = _fireAuth.currentUser;

    // If the emails match, return the verified status.
    // Note: We do not rely solely on emailVerified because, during a pending email change,
    // Firebase still shows the old (already verified) email, which would always return true.
    if (refreshedUser?.email == user.email) {
      return refreshedUser?.emailVerified;
    }

    // If emails differ, the new email is pending verification
    return false;
  }

  /// Sends a verification email to the current user.
  /// Throws an exception if no user is currently signed in.
  /// This method is only applicable for users authenticated via email.
  Future<void> sendEmailVerification() async {
    final firebaseUser = _fireAuth.currentUser;
    final user = await Yust.databaseService
        .getFromDB<YustUser>(Yust.userSetup, _fireAuth.currentUser!.uid);
    if (firebaseUser != null &&
        user != null &&
        user.authenticationMethod == YustAuthenticationMethod.mail) {
      await firebaseUser.verifyBeforeUpdateEmail(user.email);
    }
  }
  
  /// Reloads the current user to ensure the latest information is fetched from Firebase.
  Future<void> reloadCurrentUser() async => await _fireAuth.currentUser?.reload();
}
