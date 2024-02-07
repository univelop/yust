import 'package:collection/collection.dart';
import 'package:googleapis_auth/auth_io.dart';
// ignore: implementation_imports
import 'package:googleapis_auth/src/auth_http_utils.dart';
import 'package:http/http.dart';
import 'package:timezone/data/latest.dart';

import 'models/yust_doc_setup.dart';
import 'models/yust_user.dart';
import 'services/yust_auth_service.dart';
import 'services/yust_database_service.dart';
import 'services/yust_database_service_mocked.dart';
import 'services/yust_file_service.dart';
import 'util/google_cloud_helpers.dart';
import 'util/yust_helpers.dart';

/// Represents the state of the user authentication.
///
/// The states are [waiting] if asking for authentication, [signedIn] if the user is signed in and [signedOut] if the user is signed out.
enum AuthState {
  waiting,
  signedIn,
  signedOut,
}

enum DatabaseLogAction {
  delete,
  get,
  saveNew,
  save,
  transform,
  aggregate;

  const DatabaseLogAction();

  String toJson() => toString().split('.').last;

  static DatabaseLogAction fromJson(String json) =>
      DatabaseLogAction.values.firstWhereOrNull((e) => e.toJson() == json) ??
      DatabaseLogAction.get;
}

typedef DatabaseLogCallback = void Function(
    DatabaseLogAction action, YustDocSetup setup, int count,
    {String? id, List<String>? updateMask, num? aggregationResult});

typedef OnChangeCallback = Future<void> Function(
  String docPath,
  Map<String, dynamic>? oldDocument,
  Map<String, dynamic>? newDocument,
);

/// Yust is the easiest way to connect full stack Dart app to Firebase.
///
/// It is supporting Firebase Auth, Cloud Firestore and Cloud Storage.
/// You can use Yust in a flutter and for a server app.
class Yust {
  static Yust? instance;

  static late YustAuthService authService;
  static late YustFileService fileService;
  static late YustDocSetup<YustUser> userSetup;
  static YustHelpers helpers = YustHelpers();
  static late String projectId;

  late YustDatabaseService databaseService;

  bool mocked = false;

  bool forUI;

  Client? authClient;

  /// Initializes [Yust].
  /// If you will use yust in combination with e.g. YustUI in a flutter app set [forUI] to true.
  Yust({
    required this.forUI,
    this.dbLogCallback,
    this.useSubcollections = false,
    this.envCollectionName = 'envs',
    this.onChange,
  }) {
    initializeTimeZones();
  }

  final DatabaseLogCallback? dbLogCallback;
  final OnChangeCallback? onChange;
  final bool useSubcollections;
  final String envCollectionName;

  /// Initializes [Yust] in a mocked way => use in memory db instead of a real connection to firebase.
  /// If you will use yust in combination with e.g. YustUI in a flutter app set [forUI] to true.
  Yust.mocked(
      {required this.forUI,
      this.useSubcollections = false,
      this.envCollectionName = 'envs',
      this.dbLogCallback,
      this.onChange})
      : mocked = true {
    initializeTimeZones();
  }

  /// Initializes [Yust] with mocked services for testing.
  ///
  /// This method should be called before any usage of the yust package.
  void _initializeMocked() {
    initializeTimeZones();
    Yust.authService = YustAuthService.mocked();
  }

  /// Initializes [Yust].
  //
  /// This method should be called before any usage of the yust package.
  /// Use [firebaseOptions] to connect to Firebase if your are using Flutter. Use [pathToServiceAccountJson] if you are connecting directly with Dart.
  /// Set the [emulatorAddress], if you want to emulate Firebase. [userSetup] let you overwrite the default [UserSetup].
  /// If [useSubcollections] is set to true (default), Yust is creating subcollections for each tannant automatically.
  /// [envCollectionName] represents the collection name for the tannants.
  /// Use [projectId] to override / set the project id otherwise gathered from the execution environment.
  /// Use [dbLogCallback] to provide a function that will get called on each DatabaseCall
  Future<void> initialize({
    Map<String, String>? firebaseOptions,
    String? pathToServiceAccountJson,
    required String projectId,
    String? emulatorAddress,
    YustDocSetup<YustUser>? userSetup,
    DatabaseLogCallback? dbLogCallback,
    AccessCredentials? credentials,
  }) async {
    if (forUI) instance = this;

    Yust.projectId = projectId;
    Yust.userSetup = userSetup ?? YustUser.setup();

    if (mocked) {
      databaseService = YustDatabaseServiceMocked.mocked(
          onChange: onChange,
          useSubcollections: useSubcollections,
          envCollectionName: envCollectionName);
      return _initializeMocked();
    }

    authClient = await GoogleCloudHelpers.initializeFirebase(
      firebaseOptions: firebaseOptions,
      pathToServiceAccountJson: pathToServiceAccountJson,
      emulatorAddress: emulatorAddress,
      credentials: credentials,
    );

    databaseService = YustDatabaseService(
      client: authClient,
      databaseLogCallback: dbLogCallback,
      useSubcollections: useSubcollections,
      envCollectionName: envCollectionName,
      emulatorAddress: emulatorAddress,
    );

    Yust.authService = YustAuthService(emulatorAddress: emulatorAddress);
    Yust.fileService = YustFileService(
      authClient: authClient,
      emulatorAddress: emulatorAddress,
      projectId: projectId,
    );
  }

  closeClient() {
    authClient?.close();
  }

  AccessCredentials? get credentials =>
      (authClient as AuthClient?)?.credentials;
}
