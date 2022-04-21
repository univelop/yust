import 'package:collection/src/iterable_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

part 'yust_filter.g.dart';

/// All types a filter can compare a brick value with a constant
enum YustFilterComparator {
  Equal,
  NotEqual,
  LessThan,
  LessThanEqual,
  GreaterThan,
  GreaterThanEqual,
  ArrayContains,
  ArrayContainsAny,
  In,
  NotIn,
  IsNull,
}

/// The Filter class represents a document filter
///
/// The [field] may be a [String] consisting of a single field name
/// (referring to a top level field in the document),
/// or a series of field names separated by dots '.'
@JsonSerializable()
class YustFilter {
  YustFilter({
    required this.field,
    required this.comparator,
    this.value,
  });

  YustFilter.empty()
      : field = '',
        comparator = YustFilterComparator.Equal;

  /// The ID of the brick this filter refeeres to
  String field;

  /// The comparator to compare the value of the brick with the [brickId] [value]
  @JsonKey(
      fromJson: YustFilter.comparatorFromString,
      toJson: YustFilter.comparatorToString)
  YustFilterComparator comparator;

  /// The Value to compare the value of the brick with [brickId] to
  dynamic value;

  /// Checks if a value is matching or not.
  ///
  /// Returns true if [fieldValue] is matching or filter is incomplete. Otherwise false.
  bool isFieldMatching(dynamic fieldValue) {
    if (value == null) {
      return true;
    }
    fieldValue = _handleBoolValue(fieldValue);
    value = _handleBoolValue(value);

    switch (comparator) {
      case YustFilterComparator.Equal:
        return fieldValue == value;
      case YustFilterComparator.NotEqual:
        return fieldValue != value;
      case YustFilterComparator.LessThan:
        return fieldValue.compareTo(value) == -1;
      case YustFilterComparator.LessThanEqual:
        return fieldValue.compareTo(value) <= 0;
      case YustFilterComparator.GreaterThan:
        return fieldValue.compareTo(value) == 1;
      case YustFilterComparator.GreaterThanEqual:
        return fieldValue.compareTo(value) >= 0;
      case YustFilterComparator.ArrayContains:
        return (fieldValue as List).contains(value);
      case YustFilterComparator.ArrayContainsAny:
        return (value as List).any((v) => (fieldValue as List).contains(v));
      case YustFilterComparator.In:
        return (value as List).contains(fieldValue);
      case YustFilterComparator.NotIn:
        return !(value as List).contains(fieldValue);
      case YustFilterComparator.IsNull:
        return fieldValue == null;
      default:
        return false;
    }
  }

  dynamic _handleBoolValue(dynamic value) {
    if (value is List) {
      return value.map((v) => _handleBoolValue(v)).toList();
    } else if (value == true) {
      return 1;
    } else if (value == false) {
      return 0;
    } else {
      return value;
    }
  }

  static Map<YustFilterComparator, String> comparatorStrings = {
    YustFilterComparator.Equal: '=',
    YustFilterComparator.NotEqual: '!=',
    YustFilterComparator.LessThan: '<',
    YustFilterComparator.LessThanEqual: '<=',
    YustFilterComparator.GreaterThan: '>',
    YustFilterComparator.GreaterThanEqual: '>=',
    YustFilterComparator.ArrayContains: 'arrayContains',
    YustFilterComparator.ArrayContainsAny: 'arrayContainsAny',
    YustFilterComparator.In: 'in',
    YustFilterComparator.NotIn: 'notIn',
    YustFilterComparator.IsNull: 'isNull',
  };

  /// Return the String representation for a comparator (e.g. [YustFilterComparator.Equal] => '=')
  /// or an '?' if the comparator is not found
  ///
  static String? comparatorToString(YustFilterComparator? comparator,
      {bool useDoubleEqual = false}) {
    var comperatorString = YustFilter.comparatorStrings[comparator];
    if (useDoubleEqual && comperatorString == '=') {
      comperatorString = '==';
    }
    return comperatorString;
  }

  /// Get the FilterComparator from a string (e.g. '=' => [YustFilterComparator.Equal])
  static YustFilterComparator comparatorFromString(String comparatorString) {
    if (comparatorString == '==') {
      comparatorString = '=';
    }
    return comparatorStrings.entries
            .firstWhereOrNull((cs) => cs.value == comparatorString)
            ?.key ??
        YustFilterComparator.Equal;
  }

  /// Create a new filter based on an exiting one
  static YustFilter from(YustFilter f) {
    return YustFilter.fromJson(f.toJson());
  }

  factory YustFilter.fromJson(Map<String, dynamic> json) =>
      _$YustFilterFromJson(json);

  Map<String, dynamic> toJson() => _$YustFilterToJson(this);
}
