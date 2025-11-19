// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustFilter _$YustFilterFromJson(Map json) => YustFilter(
      field: json['field'] as String,
      comparator: YustFilter.comparatorFromString(json['comparator'] as String),
      value: json['value'],
    );

Map<String, dynamic> _$YustFilterToJson(YustFilter instance) =>
    <String, dynamic>{
      'field': instance.field,
      'comparator': YustFilter.comparatorToString(instance.comparator),
      'value': instance.value,
    };
