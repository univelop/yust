import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:yust/util/yust_serializable.dart';

const NULL_PLACEHOLDER = 'NULL_VALUE';

abstract class YustDoc with YustSerializable {
  @JsonKey()
  String id;

  @JsonKey(
      fromJson: YustDoc.convertTimestamp, toJson: YustDoc.convertToTimestamp)
  DateTime? createdAt;

  @JsonKey()
  String? createdBy;

  @JsonKey(
      fromJson: YustDoc.convertTimestamp, toJson: YustDoc.convertToTimestamp)
  DateTime? modifiedAt;

  @JsonKey()
  String? modifiedBy;

  @JsonKey()
  String? userId;

  @JsonKey()
  String? envId;

  YustDoc({
    this.id = '',
    this.createdAt,
    this.createdBy,
    this.modifiedAt,
    this.modifiedBy,
    this.userId,
    this.envId,
  });

  YustDoc.fromJson(Map<String, dynamic> json) : this.id = '';

  Map<String, dynamic> toJson();

  static String? stringFromJson(String? str) {
    if (str == NULL_PLACEHOLDER) {
      return null;
    }
    return str;
  }

  static Map<String, T?> mapFromJson<T>(Map<String, dynamic>? map) {
    if (map == null) {
      return {};
    }
    return map.map<String, T?>((key, value) {
      if (value == NULL_PLACEHOLDER) {
        return MapEntry(key, null);
      } else if (value is FieldValue) {
        return MapEntry(key, null);
      } else if (value is Timestamp) {
        return MapEntry(key, YustDoc.convertTimestamp(value) as T?);
      } else if (value is Map && value['_seconds'] != null) {
        return MapEntry(key, YustDoc.convertTimestamp(value) as T?);
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, YustDoc.mapFromJson(value) as T);
      } else {
        return MapEntry(key, value as T);
      }
    });
  }

  static Map<String, dynamic>? mapToJson(Map<String, dynamic>? map,
      {bool removeNullValues = true}) {
    if (map == null) return null;
    return map.map((key, value) {
      if (value == null && removeNullValues) {
        return MapEntry(key, FieldValue.delete());
      } else if (value is DateTime) {
        return MapEntry(key, YustDoc.convertToTimestamp(value));
      } else if (value is YustSerializable) {
        return MapEntry(key, (value as dynamic).toJson());
      } else if (value is Map<String, dynamic>) {
        return MapEntry(
            key, YustDoc.mapToJson(value, removeNullValues: removeNullValues));
      } else if (value is List) {
        return MapEntry(key, YustDoc.listToJson(value));
      } else {
        return MapEntry(key, value);
      }
    });
  }

  static Map<String, dynamic>? mapToPureJson(Map<String, dynamic>? map) {
    return YustDoc.mapToJson(map, removeNullValues: false);
  }

  static List<dynamic>? listToJson(List<dynamic>? list) {
    if (list == null) return null;
    return list.map((value) {
      if (value is DateTime) {
        return YustDoc.convertToTimestamp(value);
      } else if (value is YustSerializable) {
        return (value as dynamic).toJson();
      } else if (value is Map<String, dynamic>) {
        return YustDoc.mapToJson(value, removeNullValues: false);
      } else if (value is List) {
        return YustDoc.listToJson(value);
      } else {
        return value;
      }
    }).toList();
  }

  static dynamic convertTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toLocal();
    } else if (value is Map && value['_seconds'] != null) {
      return Timestamp(value['_seconds'], value['_nanoseconds'])
          .toDate()
          .toLocal();
    } else {
      return value;
    }
  }

  static dynamic convertToTimestamp(dynamic value) {
    if (value is DateTime) {
      return Timestamp.fromDate(value);
    } else {
      return value;
    }
  }
}
