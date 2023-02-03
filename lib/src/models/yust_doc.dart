import '../util/firebase_helpers.dart';
import '../yust.dart';

/// A document, what can be saved to the Firestore database.
abstract class YustDoc {
  /// The ID of the document.
  String id;

  /// The creation timestamp of the document.
  DateTime? createdAt;

  /// The user ID of the document creator.
  String? createdBy;

  /// The latest modification timestamp of the document.
  DateTime? modifiedAt;

  /// The latest modification user ID.
  String? modifiedBy;

  /// The user ID of the document owner.
  String? userId;

  /// The tennant ID where the document belongs to.
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

  /// Converts a firebase timestamp to a [DateTime].
  static dynamic convertTimestamp(dynamic value) {
    return FirebaseHelpers.convertTimestamp(value);
  }

  /// is triggerd when the document is saved
  Future<void> onSave() async {}

  /// is triggerd when the document is removed
  Future<void> onDelete() async {}
}
