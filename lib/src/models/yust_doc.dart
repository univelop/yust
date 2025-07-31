import 'package:json_annotation/json_annotation.dart';

import '../util/google_cloud_helpers.dart';
import '../yust.dart';

/// A document, what can be saved to the Firestore database.
abstract class YustDoc {
  String _id;

  /// The ID of the document.
  String get id => _id;
  set id(String s) {
    if (s != _id) updateMask.add('id');
    _id = s;
  }

  DateTime? _createdAt;

  /// The creation timestamp of the document.
  DateTime? get createdAt => _createdAt;
  set createdAt(DateTime? s) {
    if (s != _createdAt) updateMask.add('createdAt');
    _createdAt = s;
  }

  String? _createdBy;

  /// The user ID of the document creator.
  String? get createdBy => _createdBy;
  set createdBy(String? s) {
    if (s != _createdBy) updateMask.add('createdBy');
    _createdBy = s;
  }

  DateTime? _modifiedAt;

  /// The latest modification timestamp of the document.
  DateTime? get modifiedAt => _modifiedAt;
  set modifiedAt(DateTime? s) {
    if (s != _modifiedAt) updateMask.add('modifiedAt');
    _modifiedAt = s;
  }

  String? _modifiedBy;

  /// The latest modification user ID.
  String? get modifiedBy => _modifiedBy;
  set modifiedBy(String? s) {
    if (s != _modifiedBy) updateMask.add('modifiedBy');
    _modifiedBy = s;
  }

  String? _userId;

  /// The user ID of the document owner.
  String? get userId => _userId;
  set userId(String? s) {
    if (s != _userId) updateMask.add('userId');
    _userId = s;
  }

  String? _envId;

  /// The tenant ID where the document belongs to.
  String? get envId => _envId;
  set envId(String? s) {
    if (s != _envId) updateMask.add('envId');
    _envId = s;
  }

  DateTime? _expiresAt;

  /// The expiration timestamp (TTL) of the document.
  DateTime? get expiresAt => _expiresAt;
  set expiresAt(DateTime? s) {
    if (s != _expiresAt) updateMask.add('expiresAt');
    _expiresAt = s;
  }

  final Set<String> _updateMask = {};

  /// The fields that should be updated.
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
    DateTime? expiresAt,
  })  : _id = id,
        _createdAt = createdAt,
        _createdBy = createdBy,
        _modifiedAt = modifiedAt,
        _modifiedBy = modifiedBy,
        _userId = userId,
        _envId = envId,
        _expiresAt = expiresAt;

  YustDoc.fromJson(Map<String, dynamic> json) : _id = '';

  Map<String, dynamic> toJson();

  Map<String, dynamic> toExportJson() {
    final filteredJson = toJson();
    Yust.helpers.removeKeysFromMap(filteredJson,
        ['createdBy', 'modifiedBy', 'userId', 'envId', 'expiresAt']);
    return filteredJson;
  }

  /// Converts a firebase timestamp to a [DateTime].
  static dynamic convertTimestamp(dynamic value) {
    return GoogleCloudHelpers.convertTimestamp(value);
  }

  /// clear the update mask
  void clearUpdateMask() => updateMask.clear();
}
