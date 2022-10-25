import 'dart:convert';
import 'dart:io';

import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

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
    late AutoRefreshingAuthClient authClient;
    String? projectId;
    final scopes = [FirestoreApi.datastoreScope];

    if (pathToServiceAccountJson == null) {
      authClient = await clientViaApplicationDefaultCredentials(scopes: scopes);
      // TODO Set project Id dynamically
      projectId = "univelop-dev";
    } else {
      final serviceAccountJson =
          jsonDecode(await File(pathToServiceAccountJson).readAsString());

      projectId = serviceAccountJson['project_id'];

      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccountJson);

      authClient = await clientViaServiceAccount(
        accountCredentials,
        scopes,
      );
      print('Current GCP project id: $projectId');
    }

    final api = FirestoreApi(authClient,
        rootUrl: emulatorAddress != null
            ? "http://$emulatorAddress:8080/"
            : 'https://firestore.googleapis.com/');

    YustFirestoreApi.initialize(
      api,
      projectId: projectId,
    );
  }

  /// Converts a timestamp to a DateTime.
  ///
  /// If the value is not a timestamp the origianal value is returned.
  static dynamic convertTimestamp(dynamic value) {
    return value;
  }
}
