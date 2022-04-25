import 'package:collection/src/iterable_extensions.dart';
import 'package:json_annotation/json_annotation.dart';

part 'yust_filter.g.dart';

/// All types a filter can compare a brick value with a constant
enum YustFilterComparator {
  equal,
  notEqual,
  lessThan,
  lessThanEqual,
  greaterThan,
  greaterThanEqual,
  arrayContains,
  arrayContainsAny,
  inList,
  notInList,
  isNull,
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
        comparator = YustFilterComparator.equal;

  /// The ID of the brick this filter refeeres to
  String field;

  /// The comparator to compare the value of the brick with the [brickId] [value]
  @JsonKey(
      fromJson: YustFilter.comparatorFromString,
      toJson: YustFilter.comparatorToString)
  YustFilterComparator comparator;

  /// The Value to compare the value of the brick with [brickId] to
  dynamic value;

  // Define that two filters are equal if the field, comparator and value is equal
  @override
  bool operator ==(Object other) =>
      other is YustFilter &&
      field == other.field &&
      comparator == other.comparator &&
      value == other.value;

  @override
  int get hashCode => field.hashCode + comparator.hashCode + value.hashCode;

  /// Checks if a value is matching or not.
  ///
  /// Returns true if [fieldValue] is matching or filter is incomplete. Otherwise false.
  bool isFieldMatching(dynamic fieldValue) {
    if (fieldValue == null && comparator != YustFilterComparator.isNull) {
      return false;
    }
    if (value == null) {
      return true;
    }
    fieldValue = _handleBoolValue(fieldValue);
    value = _handleBoolValue(value);

    switch (comparator) {
      case YustFilterComparator.equal:
        return fieldValue == value;
      case YustFilterComparator.notEqual:
        return fieldValue != value;
      case YustFilterComparator.lessThan:
        return fieldValue.compareTo(value) == -1;
      case YustFilterComparator.lessThanEqual:
        return fieldValue.compareTo(value) <= 0;
      case YustFilterComparator.greaterThan:
        return fieldValue.compareTo(value) == 1;
      case YustFilterComparator.greaterThanEqual:
        return fieldValue.compareTo(value) >= 0;
      case YustFilterComparator.arrayContains:
        return (fieldValue as List).contains(value);
      case YustFilterComparator.arrayContainsAny:
        return (value as List).any((v) => (fieldValue as List).contains(v));
      case YustFilterComparator.inList:
        return (value as List).contains(fieldValue);
      case YustFilterComparator.notInList:
        return !(value as List).contains(fieldValue);
      case YustFilterComparator.isNull:
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
    YustFilterComparator.equal: '=',
    YustFilterComparator.notEqual: '!=',
    YustFilterComparator.lessThan: '<',
    YustFilterComparator.lessThanEqual: '<=',
    YustFilterComparator.greaterThan: '>',
    YustFilterComparator.greaterThanEqual: '>=',
    YustFilterComparator.arrayContains: 'arrayContains',
    YustFilterComparator.arrayContainsAny: 'arrayContainsAny',
    YustFilterComparator.inList: 'in',
    YustFilterComparator.notInList: 'notIn',
    YustFilterComparator.isNull: 'isNull',
  };

  /// Return the String representation for a comparator (e.g. [YustFilterComparator.equal] => '=')
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

  /// Get the FilterComparator from a string (e.g. '=' => [YustFilterComparator.equal])
  static YustFilterComparator comparatorFromString(String comparatorString) {
    if (comparatorString == '==') {
      comparatorString = '=';
    }
    return comparatorStrings.entries
            .firstWhereOrNull((cs) => cs.value == comparatorString)
            ?.key ??
        YustFilterComparator.equal;
  }

  /// Create a new filter based on an exiting one
  static YustFilter from(YustFilter f) {
    return YustFilter.fromJson(f.toJson());
  }

  factory YustFilter.fromJson(Map<String, dynamic> json) =>
      _$YustFilterFromJson(json);

  Map<String, dynamic> toJson() => _$YustFilterToJson(this);
}