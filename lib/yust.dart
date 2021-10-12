library yust;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'models/yust_doc_setup.dart';
import 'models/yust_user.dart';
import 'yust_service.dart';
import 'yust_store.dart';

enum YustInputStyle {
  normal,
  outlineBorder,
}

class Yust {
  static late YustStore store;
  static late YustService service;
  static late YustDocSetup<YustUser> userSetup;
  @Deprecated('`useTimestamps` will allways be set to true.')
  static bool useTimestamps = true;
  static bool useSubcollections = false;
  static bool firebaseInitalized = false;
  static String envCollectionName = 'envs';
  static String? storageUrl;
  static String? imagePlaceholderPath;

  /// Connnect to the firebase emulator for Firestore and Authentication
  static Future _connectToFirebaseEmulator(String address) async {
    FirebaseFirestore.instance.settings = Settings(
      host: '$address:8080',
      sslEnabled: false,
      persistenceEnabled: false,
    );

    await FirebaseAuth.instance.useEmulator('http://$address:9099');
  }

  static Future<void> initialize({
    YustStore? store,
    YustService? service,
    YustDocSetup? userSetup,
    bool useTimestamps = false,
    bool useSubcollections = false,
    String envCollectionName = 'envs',
    String? storageUrl,
    String? imagePlaceholderPath,
    String? emulatorAddress,
  }) async {
    await Firebase.initializeApp();

    // Only use emulator when emulatorAddress is provided
    if (emulatorAddress != null) {
      await Yust._connectToFirebaseEmulator(emulatorAddress);
    }

    Yust.store = store ?? YustStore();
    Yust.service = service ?? YustService();
    Yust.userSetup = userSetup as YustDocSetup<YustUser>? ?? YustUser.setup;
    Yust.useTimestamps = useTimestamps;
    Yust.useSubcollections = useSubcollections;
    Yust.envCollectionName = envCollectionName;
    Yust.storageUrl = storageUrl;
    Yust.imagePlaceholderPath = imagePlaceholderPath;

    // Only enable Persitence if Firebase is not allready initalized.
    // This is especialy important for Tests
    if (emulatorAddress == null && kIsWeb && !firebaseInitalized) {
      await FirebaseFirestore.instance.enablePersistence();
      firebaseInitalized = true;
    }

    FirebaseStorage.instance.setMaxUploadRetryTime(Duration(seconds: 20));

    final packageInfo = await PackageInfo.fromPlatform();

    Yust.store.setState(() {
      Yust.store.authState = AuthState.waiting;
      Yust.store.packageInfo = packageInfo;
    });

    StreamSubscription<YustUser?>? userSubscription;

    ///Calls [Yust.store.setState] on each auth state change event.
    FirebaseAuth.instance.authStateChanges().listen((fireUser) async {
      if (userSubscription != null) userSubscription!.cancel();
      if (fireUser != null) {
        userSubscription = Yust.service
            .getDoc<YustUser>(Yust.userSetup, fireUser.uid)
            .listen((user) async {
          if (user == null) {
            user = Yust.userSetup.newDoc()
              ..id = fireUser.uid
              ..email = fireUser.email!;
            await Yust.service.saveDoc<YustUser>(Yust.userSetup, user);
          }

          Yust.store.setState(() {
            Yust.store.authState = AuthState.signedIn;
            Yust.store.currUser = user;
          });
        });
      } else {
        Yust.store.setState(() {
          Yust.store.authState = AuthState.signedOut;
          Yust.store.currUser = null;
        });
      }
    });
  }
}
