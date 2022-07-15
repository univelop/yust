import '../util/firestore_helpers.dart';
import '../yust.dart';

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
    Yust.helpers.removeKeysFromMap(
        filteredJson, ['createdBy', 'modifiedBy', 'userId', 'envId']);
    return filteredJson;
  }

  static dynamic convertTimestamp(dynamic value) {
    return FirestoreHelpers.convertTimestamp(value);
  }
}
