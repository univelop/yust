import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

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
  doc ??= docSetup.newDoc();

  doc.id = id;
  doc.createdAt = Yust.helpers.utcNow();

  if (docSetup.hasAuthor) doc.createdBy = docSetup.userId;
  if (docSetup.hasOwner) doc.userId = docSetup.userId;
  if (docSetup.forEnvironment) doc.envId = docSetup.envId;

  docSetup.onInit?.call(doc);

  return doc;
}
