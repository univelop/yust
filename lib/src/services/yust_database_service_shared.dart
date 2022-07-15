import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

Future<void> preapareSaveDoc<T extends YustDoc>(
  YustDocSetup<T> docSetup,
  T doc, {
  bool trackModification = true,
  bool skipOnSave = false,
}) async {
  if (trackModification) {
    doc.modifiedAt = DateTime.now();
    doc.modifiedBy = Yust.authService.currUserId;
  }
  doc.createdAt ??= doc.modifiedAt;
  doc.createdBy ??= doc.modifiedBy;
  if (doc.userId == null && docSetup.forUser) {
    doc.userId = Yust.authService.currUserId;
  }
  if (doc.envId == null && docSetup.forEnvironment) {
    doc.envId = Yust.currEnvId;
  }
  if (docSetup.onSave != null && !skipOnSave) {
    await docSetup.onSave!(doc);
  }
}

T doInitDoc<T extends YustDoc>(YustDocSetup<T> docSetup, String id, [T? doc]) {
  doc ??= docSetup.newDoc();

  doc.id = id;
  doc.createdAt = DateTime.now();
  doc.createdBy = Yust.authService.currUserId;
  if (docSetup.forEnvironment) {
    doc.envId = Yust.currEnvId;
  }
  if (docSetup.forUser) {
    doc.userId = Yust.authService.currUserId;
  }
  if (docSetup.onInit != null) {
    docSetup.onInit!(doc);
  }
  return doc;
}
