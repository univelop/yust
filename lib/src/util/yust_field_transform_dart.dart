import 'package:googleapis/firestore/v1.dart';

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
          List<YustFieldTransform> transforms) =>
      throw UnsupportedError('Not supported. No UI available.');

  dynamic getFieldValue() =>
      throw UnsupportedError('Not supported. No UI available.');

  dynamic toFieldTransform() {
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
