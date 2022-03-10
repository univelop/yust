library yust;

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'models/yust_doc_setup.dart';
import 'models/yust_user.dart';
import 'services/yust_alert_service.dart';
import 'services/yust_auth_service.dart';
import 'services/yust_database_service.dart';
import 'services/yust_file_service.dart';
import 'services/yust_helper_service.dart';

enum YustInputStyle {
  normal,
  outlineBorder,
}

class Yust {
  static late FirebaseOptions firebaseOptions;
  static late YustAuthService authService;
  static late YustDatabaseService databaseService;
  static late YustFileService fileService;
  static final YustAlertService alertService = YustAlertService();
  static final YustHelperService helperService = YustHelperService();
  static late YustDocSetup<YustUser> userSetup;
  static bool useSubcollections = false;
  static String envCollectionName = 'envs';
  static String? storageUrl;
  static String? imagePlaceholderPath;

  static String? currEnvId;

  /// Connnect to the firebase emulator for Firestore and Authentication
  static Future<void> _connectToFirebaseEmulator(String address) async {
    FirebaseFirestore.instance.useFirestoreEmulator(address, 8080);

    await FirebaseAuth.instance.useAuthEmulator('http://$address', 9099);

    await FirebaseStorage.instance.useStorageEmulator(address, 9199);
  }

  static Future<void> initializeMocked() async {
    Yust.authService = YustAuthService.mocked();
    Yust.databaseService = YustDatabaseService.mocked();
    Yust.fileService = YustFileService.mocked();
  }

  static Future<void> initialize({
    FirebaseOptions? firebaseConfig,
    YustDocSetup? userSetup,
    bool useTimestamps = false,
    bool useSubcollections = false,
    String envCollectionName = 'envs',
    String? storageUrl,
    String? imagePlaceholderPath,
    String? emulatorAddress,
    bool buildRelease = false,
  }) async {
    // For the moment don't initialize iOS via config for release
    if (!kIsWeb && buildRelease && Platform.isIOS) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(options: firebaseConfig);
    }

    // Only use emulator when emulatorAddress is provided
    if (emulatorAddress != null) {
      await Yust._connectToFirebaseEmulator(emulatorAddress);
    }

    Yust.authService = YustAuthService();
    Yust.databaseService = YustDatabaseService();
    Yust.fileService = YustFileService();
    Yust.userSetup = userSetup as YustDocSetup<YustUser>? ?? YustUser.setup;
    Yust.useSubcollections = useSubcollections;
    Yust.envCollectionName = envCollectionName;
    Yust.storageUrl = storageUrl;
    Yust.imagePlaceholderPath = imagePlaceholderPath;

    FirebaseStorage.instance.setMaxUploadRetryTime(Duration(seconds: 20));
  }
}
