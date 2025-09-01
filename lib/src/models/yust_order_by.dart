import 'package:json_annotation/json_annotation.dart';

part 'yust_order_by.g.dart';

/// The OrderBy class holds a field name and whether the sorting should be decreasing
///
/// The [field] may be a [String] consisting of a single field name
/// (referring to a top level field in the document),
/// or a series of field names separated by dots '.'
@JsonSerializable()
class YustOrderBy {
  YustOrderBy({required this.field, this.descending = false});

  /// The ID of the brick this filter referes to
  String field;

  /// Whether the sorting should be decreasing
  bool descending;

  factory YustOrderBy.fromJson(Map<String, dynamic> json) =>
      _$YustOrderByFromJson(json);

  Map<String, dynamic> toJson() => _$YustOrderByToJson(this);

  // Define that two filters are equal if the field, comparator and value is equal
  @override
  bool operator ==(Object other) =>
      other is YustOrderBy &&
      field == other.field &&
      descending == other.descending;

  @override
  int get hashCode => Object.hash(field, descending);
}
