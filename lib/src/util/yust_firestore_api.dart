import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

class YustFirestoreApi {
  static FirestoreApi? instance;
  static String? projectId;
  static String rootUrl = 'https://firestore.googleapis.com/';
  static AutoRefreshingAuthClient? httpClient;

  static void initialize(AutoRefreshingAuthClient httpClient, String rootUrl,
      {String? projectId}) {
    YustFirestoreApi.httpClient = httpClient;
    YustFirestoreApi.rootUrl = rootUrl;
    YustFirestoreApi.instance = FirestoreApi(httpClient, rootUrl: rootUrl);
    YustFirestoreApi.projectId = projectId;
  }
}
