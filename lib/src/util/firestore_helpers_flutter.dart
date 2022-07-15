import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelpers {
  static dynamic convertTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toLocal();
    } else if (value is Map && value['_seconds'] != null) {
      return Timestamp(value['_seconds'], value['_nanoseconds'])
          .toDate()
          .toLocal();
    } else {
      return value;
    }
  }
}
