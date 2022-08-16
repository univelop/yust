import 'dart:io';

import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'google_api_helpers.dart';
import 'yust_exception.dart';
import 'yust_firestore_api.dart';

/// Firebase specific helpers used in other modules.
class FirebaseHelpers {
  /// Initializes firebase
  ///
  /// Use [firebaseOptions] to connect to Firebase if your are using Flutter.
  /// Use [pathToServiceAccountJson] if you are connecting directly with Dart.
  /// Set the [emulatorAddress], if you want to emulate Firebase.
  /// [buildRelease] must be set to true if you want to create an iOS release.
  static Future<void> initializeFirebase({
    Map<String, String>? firebaseOptions,
    String? pathToServiceAccountJson,
    String? emulatorAddress,
    bool buildRelease = false,
  }) async {
    if (pathToServiceAccountJson == null) {
      throw (YustException('pathToServiceAccountJson must be provided.'));
    }

    final projectId = await GoogleApiHelpers.currentProjectId();
    print('Current GCP project id: $projectId');

    final accountCredentials = ServiceAccountCredentials.fromJson(
        await File(pathToServiceAccountJson).readAsString());
    final scopes = [FirestoreApi.datastoreScope];

    final authClient = await clientViaServiceAccount(
      accountCredentials,
      scopes,
    );

    YustFirestoreApi.initialize(FirestoreApi(authClient), projectId: projectId);
  }

  /// Converts a timestamp to a DateTime.
  ///
  /// If the value is not a timestamp the origianal value is returned.
  static dynamic convertTimestamp(dynamic value) {
    return value;
  }
}
