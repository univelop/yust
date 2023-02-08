import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

Future<void> prepareSaveDoc<T extends YustDoc>(
  YustDocSetup<T> docSetup,
  T doc, {
  bool? trackModification,
  bool skipOnSave = false,
}) async {
  if (trackModification ?? docSetup.trackModification) {
    if (docSetup.hasAuthor) {
      doc.createdBy ??= doc.modifiedBy;

      doc.modifiedBy = docSetup.userId;
    }

    if (docSetup.hasOwner && doc.userId == null) {
      doc.userId = docSetup.userId;
    }

    doc.modifiedAt = Yust.helpers.utcNow();
  }

  doc.createdAt ??= doc.modifiedAt;

  if (doc.envId == null && docSetup.forEnvironment) doc.envId = docSetup.envId;

  if (!skipOnSave) await docSetup.onSave?.call(doc);
}

T doInitDoc<T extends YustDoc>(YustDocSetup<T> docSetup, String id, [T? doc]) {
  doc ??= docSetup.newDoc();

  doc.id = id;
  doc.createdAt = Yust.helpers.utcNow();

  if (docSetup.hasAuthor) doc.createdBy = docSetup.userId;
  if (docSetup.hasOwner) doc.userId = docSetup.userId;
  if (docSetup.forEnvironment) doc.envId = docSetup.envId;

  docSetup.onInit?.call(doc);

  return doc;
}
