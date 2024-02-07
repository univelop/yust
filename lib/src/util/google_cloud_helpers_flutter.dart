import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart';

import 'google_cloud_helpers_shared.dart';
import 'yust_exception.dart';

class GoogleCloudHelpers {
  static Future<Client?> initializeFirebase({
    Map<String, String>? firebaseOptions,
    String? pathToServiceAccountJson,
    String? projectId,
    String? emulatorAddress,
    bool buildRelease = false,
  }) async {
    // For the moment don't initialize iOS via config for release
    if (!kIsWeb && buildRelease && Platform.isIOS) {
      await Firebase.initializeApp();
    } else {
      if (firebaseOptions == null) {
        throw (YustException('firebaseOptions must be provided.'));
      }
      final options = fromMap(firebaseOptions);
      await Firebase.initializeApp(options: options);
    }

    // Only use emulator when emulatorAddress is provided
    if (emulatorAddress != null) {
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorAddress, 8080);
    }

    // Set Cache Options
    if (kIsWeb) {
      // Disable persistence for web cause of performance issues
      // await FirebaseFirestore.instance
      //     // Have one Cache over all univelop tabs (IndexDB)
      //     .enablePersistence(const PersistenceSettings(synchronizeTabs: true));
    } else {
      FirebaseFirestore.instance.settings =
          const Settings(persistenceEnabled: true);
    }
    return null;
  }

  static FirebaseOptions? fromMap(Map<String, String>? map) {
    if (map == null) return null;
    return FirebaseOptions(
      apiKey: map['apiKey']!,
      appId: map['appId'] ?? map['googleAppID']!,
      messagingSenderId: map['messagingSenderId'] ?? map['gcmSenderID']!,
      projectId: map['projectId'] ?? map['projectID']!,
      authDomain: map['authDomain'],
      databaseURL: map['databaseURL'],
      storageBucket: map['storageBucket'],
      measurementId: map['measurementId'],
      trackingId: map['trackingId'],
      deepLinkURLScheme: map['deepLinkURLScheme'],
      androidClientId: map['androidClientId'],
      iosClientId: map['iosClientId'],
      iosBundleId: map['iosBundleId'],
      appGroupId: map['appGroupId'],
    );
  }

  static dynamic convertTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toLocal();
    } else if (value is Map && value['_seconds'] != null) {
      return Timestamp(value['_seconds'], value['_nanoseconds'])
          .toDate()
          .toLocal();
    } else {
      return value;
    }
  }

  /// Just a stub for now. See google_cloud_helpers_dart.dart for documentation.
  static Future<String> getProjectId({String? pathToServiceAccountJson}) async {
    throw UnimplementedError();
  }

  /// Just a stub for now. See google_cloud_helpers_dart.dart for documentation.
  static Future<AutoRefreshingAuthClient> createAuthClient(
      {required List<String> scopes, String? pathToServiceAccountJson}) async {
    throw UnimplementedError();
  }

  /// Gets the google cloud platform the code is running on.
  static GoogleCloudPlatform getPlatform() {
    return GoogleCloudPlatform.local;
  }
}
