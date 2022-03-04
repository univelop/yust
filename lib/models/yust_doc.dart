import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yust/util/object_helper.dart';

const NULL_PLACEHOLDER = 'NULL_VALUE';

abstract class YustDoc {
  String id;

  DateTime? createdAt;

  String? createdBy;

  DateTime? modifiedAt;

  String? modifiedBy;

  String? userId;

  String? envId;

  YustDoc({
    this.id = '',
    this.createdAt,
    this.createdBy,
    this.modifiedAt,
    this.modifiedBy,
    this.userId,
    this.envId,
  });

  YustDoc.fromJson(Map<String, dynamic> json) : id = '';

  Map<String, dynamic> toJson();

  Map<String, dynamic> toExportJson() {
    final filteredJson = toJson();
    FlatObject.removeKeys(
        filteredJson, ['createdBy', 'modifiedBy', 'userId', 'envId']);
    return filteredJson;
  }

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
