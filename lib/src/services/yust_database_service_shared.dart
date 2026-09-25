import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../util/yust_exception.dart';
import '../yust.dart';

enum AggregationType { count, sum, avg }

typedef AggregationResult = ({double? result, int count});

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
