import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../util/yust_exception.dart';
import '../yust.dart';

enum AggregationType {
  count,
  sum,
  avg;
}

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
