import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';

import '../models/yust_user.dart';
import '../yust.dart';

enum AuthState {
  waiting,
  signedIn,
  signedOut,
}

class YustAuthService {
  FirebaseAuth fireAuth;

  YustAuthService() : fireAuth = FirebaseAuth.instance;

  YustAuthService.mocked() : fireAuth = MockFirebaseAuth();

  Stream<AuthState> get authStateStream {
    return fireAuth.authStateChanges().map<AuthState>(
        (user) => user == null ? AuthState.signedOut : AuthState.signedIn);
  }

  String? get currUserId => fireAuth.currentUser?.uid;

  Future<void> signIn(
    BuildContext context,
    String email,
    String password,
  ) async {
    await fireAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp(
    BuildContext context,
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

  Future<void> signOut(BuildContext context) async {
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
        .getDocOnce<YustUser>(Yust.userSetup, currUserId!);
    user.email = email;
    await Yust.databaseService.saveDoc<YustUser>(Yust.userSetup, user);
  }

  Future<void> changePassword(String newPassword, String oldPassword) async {
    final userCredential = await fireAuth.signInWithEmailAndPassword(
      email: fireAuth.currentUser!.email!,
      password: oldPassword,
    );
    await userCredential.user!.updatePassword(newPassword);
  }
}
