import 'package:collection/collection.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';

import 'models/yust_doc_setup.dart';
import 'models/yust_user.dart';
import 'services/yust_auth_service.dart';
import 'services/yust_auth_service_mocked.dart';
import 'services/yust_database_service.dart';
import 'services/yust_database_service_mocked.dart';
import 'services/yust_file_service.dart';
import 'services/yust_file_service_mocked.dart';
import 'services/yust_push_service.dart';
import 'services/yust_push_service_mocked.dart';
import 'util/google_cloud_helpers.dart';
import 'util/yust_helpers.dart';
import 'util/yust_location_helper.dart';

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
  getFromCache,
  saveNew,
  save,
  transform,
  aggregate,
  emptyReadOrAggregate;

  const DatabaseLogAction();

  String toJson() => toString().split('.').last;

  static DatabaseLogAction fromJson(String json) =>
      DatabaseLogAction.values.firstWhereOrNull((e) => e.toJson() == json) ??
      DatabaseLogAction.get;
}

typedef DatabaseLogCallback = void Function(
    DatabaseLogAction action, String documentPath, int count,
    {String? id, List<String>? updateMask, num? aggregationResult});

typedef OnChangeCallback = Future<void> Function(
  String docPath,
  Map<String, dynamic>? oldDocument,
  Map<String, dynamic>? newDocument,
);

/// Yust is the easiest way to connect a full stack Dart app to Firebase.
///
/// It is supporting Firebase Auth, Cloud Firestore and Cloud Storage.
/// You can use Yust in a flutter and for a server app.
class Yust {
  /// When using Yust with Flutter, you can access the instance of Yust with
  /// this getter.
  static Yust get instance => _instance!;
  static Yust? _instance;

  /// When using Yust with Flutter, you can access the databaseService of the
  /// only instance of Yust with this getter._
  static YustDatabaseService get databaseService => instance.dbService;
  static Client? authClient;

  static late YustAuthService authService;
  static late YustFileService fileService;
  static late YustDocSetup<YustUser> userSetup;
  static YustHelpers helpers = YustHelpers();
  static YustLocationHelper locationHelper = YustLocationHelper();
  static late String projectId;

  late YustDatabaseService dbService;
  late YustPushService pushService;

  bool mocked = false;

  bool forUI;

  set readTime(DateTime? time) => dbService.readTime = time;

  /// Initializes [Yust].
  /// If you will use yust in combination with e.g. YustUI in a flutter app set [forUI] to true.
  Yust({
    required this.forUI,
    this.dbLogCallback,
    this.useSubcollections = false,
    this.envCollectionName = 'envs',
    this.onChange,
  });

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
      : mocked = true;

  /// Initializes [Yust].
  //
  /// This method should be called before any usage of the yust package.
  /// Use [firebaseOptions] to connect to Firebase if your are using Flutter. Use [pathToServiceAccountJson] if you are connecting directly with Dart.
  /// Set the [emulatorAddress], if you want to emulate Firebase. [userSetup] let you overwrite the default [UserSetup].
  /// If [useSubcollections] is set to true (default), Yust is creating subcollections for each tenant automatically.
  /// [envCollectionName] represents the collection name for the tenants.
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
    if (forUI) _instance = this;

    Yust.projectId = projectId;
    Yust.userSetup = userSetup ?? YustUser.setup();

    if (mocked) {
      dbService = YustDatabaseServiceMocked.mocked(yust: this);
      pushService = YustPushServiceMocked();
      Yust.authService = YustAuthServiceMocked(this);
      Yust.fileService = YustFileServiceMocked();
      return;
    }

    Yust.authClient = await GoogleCloudHelpers.initializeFirebase(
      firebaseOptions: firebaseOptions,
      pathToServiceAccountJson: pathToServiceAccountJson,
      emulatorAddress: emulatorAddress,
      authClient: Yust.authClient,
    );

    dbService = YustDatabaseService(
      yust: this,
      emulatorAddress: emulatorAddress,
    );

    Yust.authService = YustAuthService(
      this,
      emulatorAddress: emulatorAddress,
      pathToServiceAccountJson: pathToServiceAccountJson,
    );
    Yust.fileService = YustFileService(
      authClient: Yust.authClient,
      emulatorAddress: emulatorAddress,
      projectId: projectId,
    );
    pushService = YustPushService();
  }

  closeClient() {
    authClient?.close();
  }
}
