import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';

Future<List<String>> prepareSaveDoc<T extends YustDoc>(
  YustDocSetup<T> docSetup,
  T doc, {
  bool trackModification = true,
  bool skipOnSave = false,
}) async {
  final updateMask = <String>[];

  if (docSetup.hasAuthor) {
    updateMask.add('createdBy');
    doc.createdBy ??= doc.modifiedBy;

    if (doc.userId == null && docSetup.forUser) {
      updateMask.add('userId');
      doc.userId = docSetup.userId;
    }

    if (trackModification) {
      updateMask.add('modifiedBy');
      doc.modifiedBy = docSetup.userId;
    }
  }

  if (trackModification) {
    updateMask.add('modifiedAt');
    doc.modifiedAt = DateTime.now();
  }

  updateMask.add('createdAt');
  doc.createdAt ??= doc.modifiedAt;

  if (doc.envId == null && docSetup.forEnvironment) {
    updateMask.add('envId');
    doc.envId = docSetup.envId;
  }

  if (!skipOnSave) await docSetup.onSave?.call(doc);

  return updateMask;
}

T doInitDoc<T extends YustDoc>(YustDocSetup<T> docSetup, String id, [T? doc]) {
  doc ??= docSetup.newDoc();

  doc.id = id;
  doc.createdAt = DateTime.now();

  if (docSetup.hasAuthor) {
    doc.createdBy = docSetup.userId;
    if (docSetup.forUser) doc.userId = docSetup.userId;
  }

  if (docSetup.forEnvironment) {
    doc.envId = docSetup.envId;
  }

  docSetup.onInit?.call(doc);

  return doc;
}
