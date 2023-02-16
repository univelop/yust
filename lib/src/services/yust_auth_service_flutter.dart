import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart';

import '../models/yust_user.dart';
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

  Stream<AuthState> get authStateStream {
    return fireAuth.authStateChanges().map<AuthState>((user) {
      if (user != null) {
        Yust.databaseService
            .getFromDB<YustUser>(Yust.userSetup, user.uid)
            .then((yustUser) => yustUser?.setLoginTime());
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

  Future<YustUser?> _signInWithProvider(
    AuthProvider provider,
    YustAuthenticationMethod? method,
  ) async {
    final userCredential = kIsWeb
        ? await fireAuth.signInWithPopup(provider)
        : await FirebaseAuth.instance.signInWithProvider(provider);
    if (userCredential.user == null) {
      return null;
    }
    if (await Yust.databaseService
            .get<YustUser>(Yust.userSetup, userCredential.user!.uid) ==
        null) {
      final nameParts = userCredential.user!.displayName?.split(' ') ?? [];
      final lastName = nameParts.removeLast();
      final firstName = nameParts.join(' ');
      return await _createUser(
        firstName: firstName,
        email: userCredential.user!.email ?? '',
        lastName: lastName,
        id: userCredential.user!.uid,
        authenticationMethod: YustAuthenticationMethod.microsoft,
      );
    }
    return null;
  }

  Future<YustUser> signUp(
    String firstName,
    String lastName,
    String email,
    String password, {
    YustGender? gender,
  }) async {
    final userCredential = await fireAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    return await _createUser(
      firstName: firstName,
      email: email,
      lastName: lastName,
      id: userCredential.user!.uid,
      gender: gender,
      authenticationMethod: YustAuthenticationMethod.mail,
    );
  }

  Future<YustUser> _createUser({
    required String firstName,
    required String email,
    required String lastName,
    required String id,
    YustAuthenticationMethod? authenticationMethod,
    String? domain,
    YustGender? gender,
  }) async {
    final user = Yust.userSetup.newDoc()
      ..email = email
      ..firstName = firstName
      ..lastName = lastName
      ..id = id
      ..authenticationMethod = authenticationMethod
      ..domain = domain ?? email.split('@').last
      ..gender = gender;
    await Yust.databaseService.saveDoc<YustUser>(Yust.userSetup, user);
    return user;
  }

  Future<void> signOut() async {
    await fireAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await fireAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> changeEmail(String email, String password) async {
    final userCredential = await fireAuth.signInWithEmailAndPassword(
      email: fireAuth.currentUser!.email!,
      password: password,
    );
    await userCredential.user!.updateEmail(email);
    final user = await Yust.databaseService
        .getFromDB<YustUser>(Yust.userSetup, fireAuth.currentUser!.uid);
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
}
