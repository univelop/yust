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
        Yust.databaseService
            .getFromDB<YustUser>(Yust.userSetup, user.uid)
            .then((yustUser) => yustUser?.setLoginFields());
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
        _getEmail(userCredential), _getId(userCredential), method);
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
        email, userCredential.user!.uid, YustAuthenticationMethod.mail);
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
}
