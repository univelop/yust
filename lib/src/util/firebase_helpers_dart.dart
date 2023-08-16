import 'dart:convert';
import 'dart:io';

import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis/storage/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

import 'yust_firestore_api.dart';
import 'yust_storage_api.dart';

/// Firebase specific helpers used in other modules.
class FirebaseHelpers {
  /// Initializes firebase
  ///
  /// Use [firebaseOptions] to connect to Firebase if your are using Flutter.
  /// Use [pathToServiceAccountJson] if you are connecting directly with Dart.
  /// If you don't provide a path, the client looks for credentials in common places,
  /// like environment variables, etc.
  /// Set the [emulatorAddress], if you want to emulate Firebase.
  /// [buildRelease] must be set to true if you want to create an iOS release.
  static Future<void> initializeFirebase({
    Map<String, String>? firebaseOptions,
    String? pathToServiceAccountJson,
    String? projectId,
    String? emulatorAddress,
    bool buildRelease = false,
  }) async {
    late AutoRefreshingAuthClient authClient;
    final scopes = [
      FirestoreApi.datastoreScope,
      StorageApi.devstorageFullControlScope,
    ];

    if (pathToServiceAccountJson == null) {
      authClient = await clientViaApplicationDefaultCredentials(scopes: scopes);
      // Default to Dev Environment
      projectId = projectId ??
          Platform.environment['GCP_PROJECT'] ??
          Platform.environment['GCLOUD_PROJECT'];
      if (projectId == null) {
        throw Exception('No ProjectId given or found in env variables');
      }
    } else {
      final serviceAccountJson =
          jsonDecode(await File(pathToServiceAccountJson).readAsString());

      projectId ??= serviceAccountJson['project_id'];

      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccountJson);

      authClient = await clientViaServiceAccount(
        accountCredentials,
        scopes,
      );
      print('Current GCP project id: $projectId');
    }

    YustFirestoreApi.initialize(
      authClient,
      emulatorAddress != null
          ? 'http://$emulatorAddress:8080/'
          : 'https://firestore.googleapis.com/',
      projectId: projectId,
    );

    YustStorageApi.initialize(
      authClient,
      emulatorAddress != null
          ? 'http://$emulatorAddress:9199/'
          : 'https://storage.googleapis.com/',
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
