import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

Future<List<String>> preapareSaveDoc<T extends YustDoc>(
  YustDocSetup<T> docSetup,
  T doc, {
  bool trackModification = true,
  bool skipOnSave = false,
}) async {
  final updateMask = <String>[];
  if (trackModification) {
    updateMask.add('modifiedAt');
    doc.modifiedAt = DateTime.now();
    updateMask.add('modifiedBy');
    doc.modifiedBy = Yust.authService.currUserId;
  }
  updateMask.add('createdAt');
  doc.createdAt ??= doc.modifiedAt;
  updateMask.add('createdBy');
  doc.createdBy ??= doc.modifiedBy;
  if (doc.userId == null && docSetup.forUser) {
    updateMask.add('userId');
    doc.userId = Yust.authService.currUserId;
  }
  if (doc.envId == null && docSetup.forEnvironment) {
    updateMask.add('envId');
    doc.envId = Yust.currEnvId;
  }
  if (docSetup.onSave != null && !skipOnSave) {
    await docSetup.onSave!(doc);
  }
  return updateMask;
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
