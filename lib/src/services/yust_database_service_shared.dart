import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../util/yust_date_time.dart';

Future<List<String>> prepareSaveDoc<T extends YustDoc>(
  YustDocSetup<T> docSetup,
  T doc, {
  bool? trackModification,
  bool skipOnSave = false,
}) async {
  final updateMask = <String>[];

  if (trackModification ?? docSetup.trackModification) {
    if (docSetup.hasAuthor) {
      updateMask.add('createdBy');
      doc.createdBy ??= doc.modifiedBy;

      updateMask.add('modifiedBy');
      doc.modifiedBy = docSetup.userId;
    }

    if (docSetup.hasOwner && doc.userId == null) {
      updateMask.add('userId');
      doc.userId = docSetup.userId;
    }

    updateMask.add('modifiedAt');
    doc.modifiedAt = YustDateTime.now();
  }

  if (doc.createdAt == null) {
    updateMask.add('createdAt');
    doc.createdAt ??= doc.modifiedAt;
  }

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
  doc.createdAt = YustDateTime.now();

  if (docSetup.hasAuthor) doc.createdBy = docSetup.userId;
  if (docSetup.hasOwner) doc.userId = docSetup.userId;
  if (docSetup.forEnvironment) doc.envId = docSetup.envId;

  docSetup.onInit?.call(doc);

  return doc;
}
