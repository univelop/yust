import 'dart:convert';
import 'dart:io';

import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis/identitytoolkit/v1.dart';
import 'package:googleapis/storage/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
// ignore: implementation_imports

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import 'google_cloud_helpers_shared.dart';
import 'yust_exception.dart';

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
  ///
  /// Returns an [Client] (if in dart-only env) which can be used to authenticate with other google cloud services.
  static Future<Client?> initializeFirebase({
    Map<String, String>? firebaseOptions,
    String? pathToServiceAccountJson,
    String? emulatorAddress,
    bool buildRelease = false,
    Client? authClient,
  }) async {
    if (authClient != null) return authClient;

    final scopes = [
      FirestoreApi.datastoreScope,
      StorageApi.devstorageFullControlScope,
      IdentityToolkitApi.cloudPlatformScope,
      IdentityToolkitApi.firebaseScope,
      // IAM Scope is not exported by IAMCredentialsApi
      'https://www.googleapis.com/auth/iam',
    ];

    authClient = await createAuthClient(
      scopes: scopes,
      pathToServiceAccountJson: pathToServiceAccountJson,
    );

    return authClient;
  }

  /// Creates an auth client for the google cloud environment.
  ///
  /// If [pathToServiceAccountJson] is provided, the client is created with the service account credentials.
  /// Else the client is created with the application default credentials (e.g. from environment variables)
  ///
  /// The [scopes] need to be set, to the services you want to use. E.g. `FirestoreApi.datastoreScope`.
  static Future<AuthClient> createAuthClient({
    required List<String> scopes,
    String? pathToServiceAccountJson,
  }) async {
    if (pathToServiceAccountJson == null) {
      return await clientViaApplicationDefaultCredentials(scopes: scopes);
    } else {
      final serviceAccountJson = jsonDecode(
        await File(pathToServiceAccountJson).readAsString(),
      );

      final accountCredentials = ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );

      return await clientViaServiceAccount(accountCredentials, scopes);
    }
  }

  /// Gets the google project id from the execution environment.
  ///
  /// If [pathToServiceAccountJson] is provided, the project id is read from the json file.
  /// If [pathToServiceAccountJson] and [useMetadataServer] are both not provided,
  /// the project id is read from typical google cloud environment variables.
  static Future<String> getProjectId({String? pathToServiceAccountJson}) async {
    String? projectId;
    if (pathToServiceAccountJson == null) {
      projectId =
          Platform.environment['GCP_PROJECT'] ??
          Platform.environment['GCLOUD_PROJECT'];
      projectId ??= await _getProjectIdWithMetadataServer();
    } else {
      final serviceAccountJson = jsonDecode(
        await File(pathToServiceAccountJson).readAsString(),
      );

      projectId = serviceAccountJson['project_id'];
    }
    if ((projectId ?? '') == '') {
      throw YustException('No project id found!');
    }
    return projectId!;
  }

  /// Converts a timestamp to a DateTime.
  ///
  /// If the value is not a timestamp the original value is returned.
  static dynamic convertTimestamp(dynamic value) {
    return value;
  }

  /// Gets the google cloud platform the code is running on.
  static GoogleCloudPlatform getPlatform() {
    final platformOverride = Platform.environment['YUST_PLATFORM'];
    if (platformOverride != null) {
      switch (platformOverride) {
        case 'SERVICE':
          return GoogleCloudPlatform.cloudRunService;
        case 'JOB':
          return GoogleCloudPlatform.cloudRunJob;
        default:
          return GoogleCloudPlatform.local;
      }
    } else if (Platform.environment.containsKey('K_SERVICE')) {
      return GoogleCloudPlatform.cloudRunService;
    } else if (Platform.environment.containsKey('CLOUD_RUN_JOB')) {
      return GoogleCloudPlatform.cloudRunJob;
    } else {
      return GoogleCloudPlatform.local;
    }
  }

  /// Gets the project id from the google cloud metadata server.
  /// This is only available in the google cloud environment.
  static Future<String> _getProjectIdWithMetadataServer() async {
    final metadataServer = Uri.parse(
      'http://metadata.google.internal/computeMetadata/v1/project/project-id',
    );

    final projectId = (await http.get(
      metadataServer,
      headers: {'Metadata-Flavor': 'Google'},
    )).body;

    return projectId;
  }

  static Future<String> getInstanceId() async {
    final instanceId = (await http.get(
      Uri.parse(
        'http://metadata.google.internal/computeMetadata/v1/instance/id',
      ),
      headers: {'Metadata-Flavor': 'Google'},
    )).body;
    return instanceId;
  }
}
