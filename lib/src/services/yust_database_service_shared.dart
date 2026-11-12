import 'dart:convert';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../util/yust_exception.dart';
import '../yust.dart';

enum AggregationType { count, sum, avg }

typedef AggregationResult = ({double? result, int count});

/// Maximum size of a Firestore document id in bytes.
const _maxPathSegmentBytes = 1500;

final _reservedPathSegment = RegExp(r'^__.*__$');
final _controlCharacter = RegExp(r'[\x00-\x1F\x7F]');

/// Throws a [YustInvalidPathSegmentException] if [segment] is not a valid
/// single Firestore path segment (document id or collection id).
///
/// Follows the Firestore DocumentID naming rules:
/// Must be valid UTF-8 characters
/// Must be no longer than 1,500 bytes
/// Cannot contain a forward slash (/)
/// Cannot solely consist of a single period (.) or double periods (..)
/// Cannot match the regular expression __.*__
void assertValidPathSegment(String? segment, {String kind = 'document id'}) {
  String? reason;
  if (segment == null || segment.isEmpty) {
    reason = 'must not be empty';
  } else if (segment.contains('/') || segment.contains(r'\')) {
    reason = 'must not contain "/" or "\\"';
  } else if (segment == '.' || segment == '..') {
    reason = 'must not be "." or ".."';
  } else if (_reservedPathSegment.hasMatch(segment)) {
    reason = 'must not match "__.*__"';
  } else if (_controlCharacter.hasMatch(segment)) {
    reason = 'must not contain control characters';
  } else if (utf8.encode(segment).length > _maxPathSegmentBytes) {
    reason = 'must not exceed $_maxPathSegmentBytes bytes';
  }

  if (reason != null) {
    throw YustInvalidPathSegmentException('Invalid $kind: $reason.', segment);
  }
}

/// Validates every segment of a (possibly nested) collection name like
/// `recordSpecs/<specId>/records`.
void assertValidCollectionName(String collectionName) {
  for (final segment in collectionName.split('/')) {
    assertValidPathSegment(segment, kind: 'collection path segment');
  }
}

/// Validates the parts of [docSetup] that end up in a document path:
/// the environment id (if [withEnvironment]) and the collection name.
///
/// A `null` environment id is tolerated to keep the previous behavior
/// (it resolves to a non-existing `null` environment and cannot traverse).
void assertValidDocSetupPath(
  YustDocSetup docSetup, {
  required bool withEnvironment,
}) {
  final envId = docSetup.envId;
  if (withEnvironment && envId != null) {
    assertValidPathSegment(envId, kind: 'environment id');
  }
  assertValidCollectionName(docSetup.collectionName);
}

Future<void> prepareSaveDoc<T extends YustDoc>(
  YustDocSetup<T> docSetup,
  T doc, {
  bool? trackModification,
  bool skipOnSave = false,
}) async {
  doc.createdAt ??= Yust.helpers.utcNow();
  doc.modifiedAt ??= doc.createdAt;
  if (docSetup.forEnvironment) {
    doc.envId ??= docSetup.envId;
  }
  if (docSetup.hasAuthor) {
    doc.createdBy ??= docSetup.userId;
    doc.modifiedBy ??= docSetup.userId;
  }
  if (docSetup.hasOwner) {
    doc.userId ??= docSetup.userId;
  }

  if (trackModification ?? docSetup.trackModification) {
    doc.modifiedAt = Yust.helpers.utcNow();
    if (docSetup.hasAuthor) {
      doc.modifiedBy = docSetup.userId;
    }
  }

  if (!skipOnSave) await docSetup.onSave?.call(doc);
}

/// Cleans a Firestore update field [mask] so it never references a path that is
/// missing from [data].
List<String> cleanUpdateMask(Map<String, dynamic> data, Iterable<String> mask) {
  final resolved = <String>{};
  for (final path in mask) {
    final existing = _nearestExistingPath(data, path);
    if (existing != null) resolved.add(existing);
  }

  // Drop any path that has a strict ancestor also present in the mask.
  return resolved
      .where(
        (path) => !resolved.any(
          (other) => other != path && path.startsWith('$other.'),
        ),
      )
      .toList();
}

/// Returns the longest prefix of [path] that resolves to an existing key in
/// [data] (the resolved value may itself be `null`), or `null` if not even the
/// first segment exists. Backtick-quoting of segments is tolerated.
String? _nearestExistingPath(Map<String, dynamic> data, String path) {
  final segments = path.split('.');
  final kept = <String>[];
  dynamic current = data;
  for (final segment in segments) {
    final key = segment.replaceAll('`', '');
    if (current is Map<String, dynamic> && current.containsKey(key)) {
      kept.add(segment);
      current = current[key];
    } else {
      break;
    }
  }
  return kept.isEmpty ? null : kept.join('.');
}

T doInitDoc<T extends YustDoc>(YustDocSetup<T> docSetup, String id, [T? doc]) {
  if (docSetup.newDoc == null) {
    throw YustException(
      'No newDoc function provided for ${docSetup.collectionName}, cannot initialize doc.',
    );
  }
  doc ??= docSetup.newDoc!();

  doc.id = id;
  doc.createdAt = Yust.helpers.utcNow();

  if (docSetup.hasAuthor) doc.createdBy = docSetup.userId;
  if (docSetup.hasOwner) doc.userId = docSetup.userId;
  if (docSetup.forEnvironment) doc.envId = docSetup.envId;
  if (docSetup.expiresAfter != null) {
    doc.expiresAt = Yust.helpers.utcNow().add(docSetup.expiresAfter!);
  }

  docSetup.onInit?.call(doc);

  return doc;
}
