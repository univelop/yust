import 'package:timezone/data/latest.dart';

import 'models/yust_doc_setup.dart';
import 'models/yust_user.dart';
import 'services/yust_auth_service.dart';
import 'services/yust_database_service.dart';
import 'services/yust_database_service_mocked.dart';
import 'services/yust_file_service.dart';
import 'util/firebase_helpers.dart';
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
  delete('DELETE'),
  get('READ'),
  saveNew('CREATE'),
  save('UPDATE'),
  transform('UPDATE');

  const DatabaseLogAction(this.logText);
  final String logText;
}

typedef DatabaseLogCallback = void Function(
    DatabaseLogAction action, YustDocSetup setup, int count,
    {String? id, List<String>? updateMask});

/// Yust is the easiest way to connect full stack Dart app to Firebase.
///
/// It is supporting Firebase Auth, Cloud Firestore and Cloud Storage.
/// You can use Yust in a flutter and for a server app.
class Yust {
  static late YustAuthService authService;
  static late YustDatabaseService databaseService;
  static late YustFileService fileService;
  static late YustDocSetup<YustUser> userSetup;
  static YustHelpers helpers = YustHelpers();

  /// If [useSubcollections] is set to true (default), Yust is creating subcollections for each tannant automatically.
  static bool useSubcollections = true;

  /// Represents the collection name for the tannants.
  static String envCollectionName = 'envs';

  /// Initializes [Yust] with mocked services for testing.
  ///
  /// This method should be called before any usage of the yust package.
  static Future<void> initializeMocked() async {
    initializeTimeZones();
    Yust.authService = YustAuthService.mocked();
    Yust.databaseService = YustDatabaseServiceMocked();
  }

  /// Initializes [Yust].
  ///
  /// This method should be called before any usage of the yust package.
  /// Use [firebaseOptions] to connect to Firebase if your are using Flutter. Use [pathToServiceAccountJson] if you are connecting directly with Dart.
  /// Set the [emulatorAddress], if you want to emulate Firebase. [buildRelease] must be set to true if you want to create an iOS release. [userSetup] let you overwrite the default [UserSetup].
  /// If [useSubcollections] is set to true (default), Yust is creating subcollections for each tannant automatically.
  /// [envCollectionName] represents the collection name for the tannants.
  /// Use [projectId] to override / set the project id otherwise gathered from the execution environment.
  /// Use [dbLogCallback] to provide a function that will get called on each DatabaseCall
  static Future<void> initialize({
    Map<String, String>? firebaseOptions,
    String? pathToServiceAccountJson,
    String? projectId,
    String? emulatorAddress,
    bool buildRelease = false,
    YustDocSetup<YustUser>? userSetup,
    bool useSubcollections = false,
    String envCollectionName = 'envs',
    DatabaseLogCallback? dbLogCallback,
  }) async {
    // Init timezones
    initializeTimeZones();

    await FirebaseHelpers.initializeFirebase(
      firebaseOptions: firebaseOptions,
      pathToServiceAccountJson: pathToServiceAccountJson,
      projectId: projectId,
      emulatorAddress: emulatorAddress,
      buildRelease: buildRelease,
    );

    Yust.userSetup = userSetup ?? YustUser.setup();
    Yust.useSubcollections = useSubcollections;
    Yust.envCollectionName = envCollectionName;
    Yust.authService = YustAuthService(emulatorAddress: emulatorAddress);
    // Note that the data connection for the emulator is handled in [initializeFirebase]
    Yust.databaseService = YustDatabaseService(dbLogCallback: dbLogCallback);
    Yust.fileService = YustFileService(emulatorAddress: emulatorAddress);
  }
}
