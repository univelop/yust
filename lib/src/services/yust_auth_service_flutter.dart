import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/foundation.dart';

import '../models/yust_filter.dart';
import '../models/yust_user.dart';
import '../util/yust_exception.dart';
import '../yust.dart';

class YustAuthService {
  FirebaseAuth fireAuth;

  YustAuthService({String? emulatorAddress})
      : fireAuth = FirebaseAuth.instance {
    if (emulatorAddress != null) {
      fireAuth.useAuthEmulator(emulatorAddress, 9099);
    }
  }

  YustAuthService.mocked() : fireAuth = MockFirebaseAuth();

  Stream<AuthState> getAuthStateStream() {
    return fireAuth.authStateChanges().map<AuthState>((user) {
      if (user != null) {
        Yust.databaseService
            .getFromDB<YustUser>(Yust.userSetup, user.uid)
            .then((yustUser) => yustUser?.setLoginFields());
      }
      return user == null ? AuthState.signedOut : AuthState.signedIn;
    });
  }

  String? getCurrentUserId() => fireAuth.currentUser?.uid;

  Future<void> signIn(
    String email,
    String password,
  ) async {
    await fireAuth.signInWithEmailAndPassword(
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
    final successfullyLinked = await _tryLinkYustUser(userCredential, method);
    if (successfullyLinked) return null;

    final nameParts = _extractNameParts(userCredential);
    final lastName = _getLastName(nameParts);
    final firstName = _getFirstName(nameParts);

    return await _createUser(
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
              ? await fireAuth
                  .signInWithRedirect(provider)
                  .then((value) => fireAuth.getRedirectResult())
              : await fireAuth.signInWithPopup(provider)
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

  Future<bool> _tryLinkYustUser(
    UserCredential userCredential,
    YustAuthenticationMethod? method,
  ) async {
    if (userCredential.user?.email == null ||
        userCredential.user?.email == '') {
      return false;
    }
    final user = await Yust.databaseService.getFirst<YustUser>(
      Yust.userSetup,
      filters: [
        YustFilter(
          field: 'email',
          comparator: YustFilterComparator.equal,
          value: userCredential.user!.email,
        ),
      ],
    );
    if (user == null) return false;
    await user.linkAuth(userCredential.user!.uid, method);
    return true;
  }

  Future<YustUser?> signUp(
    String firstName,
    String lastName,
    String email,
    String password, {
    YustGender? gender,
  }) async {
    final userCredential = await fireAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    final successfullyLinked =
        await _tryLinkYustUser(userCredential, YustAuthenticationMethod.mail);
    if (successfullyLinked) return null;

    return await _createUser(
      firstName: firstName,
      email: email,
      lastName: lastName,
      id: userCredential.user!.uid,
      authId: userCredential.user!.uid,
      gender: gender,
      authenticationMethod: YustAuthenticationMethod.mail,
    );
  }

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

  Future<void> signOut() async {
    await fireAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    // ignore: deprecated_member_use
    final loginMethods = await fireAuth.fetchSignInMethodsForEmail(email);
    if (loginMethods.contains('password')) {
      await fireAuth.sendPasswordResetEmail(email: email);
    } else {
      throw YustException('Reset password not possible.');
    }
  }

  Future<void> changeEmail(String email, String password) async {
    final user = await Yust.databaseService
        .getFromDB<YustUser>(Yust.userSetup, fireAuth.currentUser!.uid);
    if (user?.authenticationMethod == null ||
        user?.authenticationMethod == YustAuthenticationMethod.mail) {
      final userCredential = await fireAuth.signInWithEmailAndPassword(
        email: fireAuth.currentUser!.email!,
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
    final userCredential = await fireAuth.signInWithEmailAndPassword(
      email: fireAuth.currentUser!.email!,
      password: oldPassword,
    );
    await userCredential.user!.updatePassword(newPassword);
  }

  Future<void> checkPassword(String password) async {
    await fireAuth.currentUser!
        .reauthenticateWithCredential(EmailAuthProvider.credential(
      email: fireAuth.currentUser!.email!,
      password: password,
    ));
  }

  Future<void> deleteAccount([String? password]) async {
    try {
      final user = fireAuth.currentUser;
      await user?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && password != null) {
        final user = (await fireAuth.signInWithEmailAndPassword(
          email: fireAuth.currentUser!.email!,
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
    final jwtObject = await fireAuth.currentUser?.getIdTokenResult();
    return jwtObject?.token;
  }
}
