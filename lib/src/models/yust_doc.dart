import 'package:json_annotation/json_annotation.dart';

import '../util/firebase_helpers.dart';
import '../yust.dart';

/// A document, what can be saved to the Firestore database.
abstract class YustDoc {
  /// The ID of the document.
  String _id;
  String get id => _id;
  set id(String s) {
    if (s != _id) updateMask.add('id');
    _id = s;
  }

  /// The creation timestamp of the document.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  set createdAt(DateTime? s) {
    if (s != _createdAt) updateMask.add('createdAt');
    _createdAt = s;
  }

  /// The user ID of the document creator.
  String? _createdBy;
  String? get createdBy => _createdBy;
  set createdBy(String? s) {
    if (s != _createdBy) updateMask.add('createdBy');
    _createdBy = s;
  }

  /// The latest modification timestamp of the document.
  DateTime? _modifiedAt;
  DateTime? get modifiedAt => _modifiedAt;
  set modifiedAt(DateTime? s) {
    if (s != _modifiedAt) updateMask.add('modifiedAt');
    _modifiedAt = s;
  }

  /// The latest modification user ID.
  String? _modifiedBy;
  String? get modifiedBy => _modifiedBy;
  set modifiedBy(String? s) {
    if (s != _modifiedBy) updateMask.add('modifiedBy');
    _modifiedBy = s;
  }

  /// The user ID of the document owner.
  String? _userId;
  String? get userId => _userId;
  set userId(String? s) {
    if (s != _userId) updateMask.add('userId');
    _userId = s;
  }

  /// The tennant ID where the document belongs to.
  String? _envId;
  String? get envId => _envId;
  set envId(String? s) {
    if (s != _envId) updateMask.add('envId');
    _envId = s;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  final Set<String> _updateMask;

  /// The fields that should be updated.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Set<String> get updateMask => _updateMask;

  /// are there changes to be saved?
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasChanges => _updateMask.isNotEmpty;

  YustDoc({
    String id = '',
    DateTime? createdAt,
    String? createdBy,
    DateTime? modifiedAt,
    String? modifiedBy,
    String? userId,
    String? envId,
    Set<String>? updateMask,
  })  : _id = id,
        _createdAt = createdAt,
        _createdBy = createdBy,
        _modifiedAt = modifiedAt,
        _modifiedBy = modifiedBy,
        _userId = userId,
        _envId = envId,
        _updateMask = updateMask ??
            <String>{
              'id',
              'createdAt',
              'createdBy',
              'modifiedAt',
              'modifiedBy',
              'userId',
              'envId'
            };

  YustDoc.fromJson(Map<String, dynamic> json)
      : _id = '',
        _updateMask = <String>{};

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

  /// clear the update mask
  void clearUpdateMask() => _updateMask.clear();
}
