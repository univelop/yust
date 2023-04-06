import 'package:googleapis/firestore/v1.dart';

class YustFieldTransform {
  String fieldPath;
  double? increment;
  List<dynamic>? removeFromArray;
  bool? setToServerTimestamp;
  bool? delete;

  YustFieldTransform({
    required String fieldPath,
    this.increment,
    this.removeFromArray,
    this.setToServerTimestamp,
    this.delete,
  }) : fieldPath =
            fieldPath.splitMapJoin(r'[\w\d\-\_]+', onMatch: (m) => '`${m[0]}`');

  /// Converts this YustFieldTransform to it's platforms native implementation
  /// For Flutter (cloud_firestore) this it's a [FieldValue]...
  /// ... and for dart (googleapis/firestore) its a [FieldTransform]
  dynamic toNativeTransform() {
    return FieldTransform(
      fieldPath: fieldPath,
      increment: increment != null ? Value(doubleValue: increment) : null,
      removeAllFromArray: removeFromArray != null
          ? ArrayValue.fromJson(<dynamic, dynamic>{'values': removeFromArray})
          : null,
      setToServerValue: (setToServerTimestamp ?? false) ? 'REQUEST_TIME' : null,
    );
  }
}
