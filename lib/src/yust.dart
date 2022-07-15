import 'package:yust/src/util/yust_helpers.dart';

import 'models/yust_doc_setup.dart';
import 'models/yust_user.dart';
import 'services/yust_auth_service.dart';
import 'services/yust_database_service.dart';
import 'util/firebase_initializer.dart';

enum AuthState {
  waiting,
  signedIn,
  signedOut,
}

class Yust {
  static late YustAuthService authService;
  static late YustDatabaseService databaseService;
  static late YustDocSetup<YustUser> userSetup;
  static YustHelpers helpers = YustHelpers();
  static bool useSubcollections = false;
  static String envCollectionName = 'envs';

  static String? currEnvId;

  static Future<void> initializeMocked() async {
    Yust.authService = YustAuthService.mocked();
    Yust.databaseService = YustDatabaseService.mocked();
  }

  static Future<void> initialize({
    Map<String, String>? firebaseOptions,
    String? pathToServiceAccountJson,
    String? emulatorAddress,
    bool buildRelease = false,
    YustDocSetup<YustUser>? userSetup,
    bool useSubcollections = false,
    String envCollectionName = 'envs',
  }) async {
    await FirebaseInitializer.initialize(
      firebaseOptions: firebaseOptions,
      pathToServiceAccountJson: pathToServiceAccountJson,
      emulatorAddress: emulatorAddress,
      buildRelease: buildRelease,
    );

    Yust.userSetup = userSetup ?? YustUser.setup;
    Yust.useSubcollections = useSubcollections;
    Yust.envCollectionName = envCollectionName;
  }
}
