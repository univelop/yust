import 'dart:io';

import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

import '../services/yust_auth_service.dart';
import '../services/yust_database_service.dart';
import '../yust.dart';
import 'google_api_helpers.dart';
import 'yust_exception.dart';
import 'yust_firestore_api.dart';

class FirebaseInitializer {
  static Future<void> initialize({
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

    Yust.authService = YustAuthService();
    Yust.databaseService = YustDatabaseService();
  }
}
