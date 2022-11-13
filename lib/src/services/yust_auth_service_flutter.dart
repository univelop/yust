import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

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
            .getDocOnce<YustUser>(Yust.userSetup, user.uid)
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

  Future<void> signUp(
    String firstName,
    String lastName,
    String email,
    String password,
    String passwordConfirmation, {
    YustGender? gender,
  }) async {
    final userCredential = await fireAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = Yust.userSetup.newDoc()
      ..email = email
      ..firstName = firstName
      ..lastName = lastName
      ..gender = gender
      ..id = userCredential.user!.uid;
    await Yust.databaseService.saveDoc<YustUser>(Yust.userSetup, user);
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
        .getDocOnce<YustUser>(Yust.userSetup, fireAuth.currentUser!.uid);
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
}
