import 'dart:convert';
import 'dart:io';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis/storage/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import 'yust_exception.dart';
import 'yust_firestore_api.dart';
import 'yust_storage_api.dart';

/// Google Cloud (incl. Firebase) specific helpers used in other modules.
class GoogleCloudHelpers {
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
    final scopes = [
      FirestoreApi.datastoreScope,
      StorageApi.devstorageFullControlScope,
    ];

    final authClient = await createAuthClient(
      scopes: scopes,
      pathToServiceAccountJson: pathToServiceAccountJson,
    );
    final projectId = await getProjectId(
      pathToServiceAccountJson: pathToServiceAccountJson,
    );

    print('Current GCP project id: $projectId');

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

  /// Creates an auth client for the google cloud environment.
  ///
  /// If [pathToServiceAccountJson] is provided, the client is created with the service account credentials.
  /// Else the client is created with the application default credentials (e.g. from environment variables)
  ///
  /// The [scopes] need to be set, to the services you want to use. E.g. `FirestoreApi.datastoreScope`.
  static Future<AutoRefreshingAuthClient> createAuthClient(
      {required List<String> scopes, String? pathToServiceAccountJson}) async {
    final AutoRefreshingAuthClient authClient;
    if (pathToServiceAccountJson == null) {
      authClient = await clientViaApplicationDefaultCredentials(scopes: scopes);
    } else {
      final serviceAccountJson =
          jsonDecode(await File(pathToServiceAccountJson).readAsString());

      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccountJson);

      authClient = await clientViaServiceAccount(
        accountCredentials,
        scopes,
      );
    }
    return authClient;
  }

  /// Gets the google project id from the execution environment.
  ///
  /// If [pathToServiceAccountJson] is provided, the project id is read from the json file.
  /// If [pathToServiceAccountJson] and [useMetadataServer] are both not provided,
  /// the project id is read from typical google cloud environment variables.
  static Future<String> getProjectId({
    String? pathToServiceAccountJson,
  }) async {
    String? projectId;
    if (pathToServiceAccountJson == null) {
      projectId = Platform.environment['GCP_PROJECT'] ??
          Platform.environment['GCLOUD_PROJECT'];
      projectId ??= await _getProjectIdWithMetadataServer();
    } else {
      final serviceAccountJson =
          jsonDecode(await File(pathToServiceAccountJson).readAsString());

      projectId = serviceAccountJson['project_id'];
    }
    if ((projectId ?? '') == '') {
      throw YustException('No project id found!');
    }
    return projectId!;
  }

  /// Converts a timestamp to a DateTime.
  ///
  /// If the value is not a timestamp the origianal value is returned.
  static dynamic convertTimestamp(dynamic value) {
    return value;
  }

  /// Gets the project id from the google cloud metadata server.
  /// This is only available in the google cloud environment.
  static Future<String> _getProjectIdWithMetadataServer() async {
    final metadataServer = Uri.parse(
        'http://metadata.google.internal/computeMetadata/v1/project/project-id');

    final projectId =
        (await http.get(metadataServer, headers: {'Metadata-Flavor': 'Google'}))
            .body;

    return projectId;
  }
}
