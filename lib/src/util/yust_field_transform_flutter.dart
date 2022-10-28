import 'package:cloud_firestore/cloud_firestore.dart';

class YustFieldTransform {
  String fieldPath;
  double? increment;
  List<dynamic>? removeFromArray;
  bool? setToServerTimestamp;
  bool? delete;

  YustFieldTransform({
    required this.fieldPath,
    this.increment,
    this.removeFromArray,
    this.setToServerTimestamp,
    this.delete,
  });

  /// Converts this YustFieldTransform to it's platforms native implementation
  /// For Flutter (cloud_firestore) this it's a [FieldValue]...
  /// ... and for dart (googleapis/firestore) its a [FieldTransform]
  dynamic toNativeTransform() {
    if (increment != null) return FieldValue.increment(increment!);
    if (removeFromArray != null) {
      return FieldValue.arrayRemove(removeFromArray!);
    }
    if (setToServerTimestamp != null) return FieldValue.serverTimestamp();
    if (delete != null) return FieldValue.delete();
    return null;
  }
}
