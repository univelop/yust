// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'yust_order_by.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

YustOrderBy _$YustOrderByFromJson(Map json) => YustOrderBy(
  field: json['field'] as String,
  descending: json['descending'] as bool? ?? false,
);

Map<String, dynamic> _$YustOrderByToJson(YustOrderBy instance) =>
    <String, dynamic>{
      'field': instance.field,
      'descending': instance.descending,
    };
