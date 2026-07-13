import 'package:cloud_firestore/cloud_firestore.dart';

class YustFieldTransform {
  String fieldPath;
  double? increment;
  List<dynamic>? appendMissingElements;
  List<dynamic>? removeFromArray;
  bool? setToServerTimestamp;
  bool? delete;

  YustFieldTransform({
    required String fieldPath,
    this.increment,
    this.appendMissingElements,
    this.removeFromArray,
    this.setToServerTimestamp,
    this.delete,
  }) : fieldPath = fieldPath.splitMapJoin(
         r'[\w\d\-\_]+',
         onMatch: (m) => '`${m[0]}`',
       );

  /// Converts this YustFieldTransform to it's platforms native implementation
  /// For Flutter (cloud_firestore) this it's a [FieldValue]...
  /// ... and for dart (googleapis/firestore) its a [FieldTransform]
  dynamic toNativeTransform() {
    if (increment != null) return FieldValue.increment(increment!);
    if (appendMissingElements != null) {
      return FieldValue.arrayUnion(appendMissingElements!);
    }
    if (removeFromArray != null) {
      return FieldValue.arrayRemove(removeFromArray!);
    }
    if (setToServerTimestamp != null) return FieldValue.serverTimestamp();
    if (delete != null) return FieldValue.delete();
    return null;
  }
}
