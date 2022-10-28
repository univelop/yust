import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'yust_exception.dart';

class FirebaseHelpers {
  static Future<void> initializeFirebase({
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
}
