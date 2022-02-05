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
import 'services/yust_alert_service.dart';
import 'services/yust_auth_service.dart';
import 'services/yust_database_service.dart';
import 'services/yust_file_service.dart';
import 'services/yust_helper_service.dart';
import 'yust_store.dart';

enum YustInputStyle {
  normal,
  outlineBorder,
}

class Yust {
  static late YustStore store;
  static late FirebaseOptions firebaseOptions;
  static late YustAuthService authService;
  static late final YustDatabaseService databaseService;
  static late final YustFileService fileService;
  static final YustAlertService alertService = YustAlertService();
  static final YustHelperService helperService = YustHelperService();
  static late YustDocSetup<YustUser> userSetup;
  static bool useSubcollections = false;
  static String envCollectionName = 'envs';
  static String? storageUrl;
  static String? imagePlaceholderPath;

  /// Connnect to the firebase emulator for Firestore and Authentication
  static Future _connectToFirebaseEmulator(String address) async {
    FirebaseFirestore.instance.useFirestoreEmulator(address, 8080);

    await FirebaseAuth.instance.useEmulator('http://$address:9099');

    await FirebaseStorage.instance.useEmulator(host: address, port: 9199);
  }

  static Future<void> initializeMocked({YustStore? store}) async {
    Yust.store = store ?? YustStore();
    Yust.authService = YustAuthService.mocked();
    Yust.databaseService = YustDatabaseService.mocked();
    Yust.fileService = YustFileService.mocked();
  }

  static Future<void> initialize({
    YustStore? store,
    FirebaseOptions? firebaseConfig,
    YustDocSetup? userSetup,
    bool useTimestamps = false,
    bool useSubcollections = false,
    String envCollectionName = 'envs',
    String? storageUrl,
    String? imagePlaceholderPath,
    String? emulatorAddress,
    String? appName,
  }) async {
    await Firebase.initializeApp(
        name: kIsWeb ? null : appName, options: firebaseConfig);

    // Only use emulator when emulatorAddress is provided
    if (emulatorAddress != null) {
      await Yust._connectToFirebaseEmulator(emulatorAddress);
    }

    Yust.store = store ?? YustStore();
    Yust.authService = YustAuthService();
    Yust.databaseService = YustDatabaseService();
    Yust.fileService = YustFileService();
    Yust.userSetup = userSetup as YustDocSetup<YustUser>? ?? YustUser.setup;
    Yust.useSubcollections = useSubcollections;
    Yust.envCollectionName = envCollectionName;
    Yust.storageUrl = storageUrl;
    Yust.imagePlaceholderPath = imagePlaceholderPath;

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
        userSubscription = Yust.databaseService
            .getDoc<YustUser>(Yust.userSetup, fireUser.uid)
            .listen((user) async {
          if (user == null) {
            user = Yust.userSetup.newDoc()
              ..id = fireUser.uid
              ..email = fireUser.email!;
            await Yust.databaseService.saveDoc<YustUser>(Yust.userSetup, user);
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
