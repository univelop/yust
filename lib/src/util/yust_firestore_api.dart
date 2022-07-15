import 'package:googleapis/firestore/v1.dart';

class YustFirestoreApi {
  static FirestoreApi? instance;
  static String? projectId;

  static void initialize(FirestoreApi firestoreApi, {String? projectId}) {
    instance = firestoreApi;
    YustFirestoreApi.projectId = projectId;
  }
}
