import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import '../models/yust_user.dart';
import '../yust.dart';

class YustAuthService {
  FirebaseAuth fireAuth;

  YustAuthService() : fireAuth = FirebaseAuth.instance;
  YustAuthService.mocked() : fireAuth = new MockFirebaseAuth();

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
    final UserCredential userCredential = await fireAuth
        .createUserWithEmailAndPassword(email: email, password: password);
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

    final completer = Completer<void>();
    void complete() => completer.complete();

    Yust.store.addListener(complete);

    ///Awaits that the listener registered in the [Yust.initialize] method completed its work.
    ///This also assumes that [fireAuth.signOut] was successfull, of which I do not know how to be certain.
    await completer.future;
    Yust.store.removeListener(complete);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await fireAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> changeEmail(String email, String password) async {
    final UserCredential userCredential =
        await fireAuth.signInWithEmailAndPassword(
      email: Yust.store.currUser!.email,
      password: password,
    );
    await userCredential.user!.updateEmail(email);
    Yust.store.setState(() {
      Yust.store.currUser!.email = email;
    });
    Yust.databaseService
        .saveDoc<YustUser>(Yust.userSetup, Yust.store.currUser!);
  }

  Future<void> changePassword(String newPassword, String oldPassword) async {
    final UserCredential userCredential =
        await fireAuth.signInWithEmailAndPassword(
      email: Yust.store.currUser!.email,
      password: oldPassword,
    );
    await userCredential.user!.updatePassword(newPassword);
  }
}
