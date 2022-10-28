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

  static Map<String, dynamic> toFieldValueMap(
      List<YustFieldTransform> transforms) {
    final map = <String, dynamic>{};
    for (final transform in transforms) {
      final fieldValue = transform.getFieldValue();
      if (fieldValue == null) continue;
      map[transform.fieldPath] = fieldValue;
    }
    return map;
  }

  dynamic getFieldValue() {
    if (increment != null) return FieldValue.increment(increment!);
    if (removeFromArray != null) {
      return FieldValue.arrayRemove(removeFromArray!);
    }
    if (setToServerTimestamp != null) return FieldValue.serverTimestamp();
    if (delete != null) return FieldValue.delete();
    return null;
  }

  dynamic toFieldTransform() => throw UnsupportedError('Not supported.');
}
