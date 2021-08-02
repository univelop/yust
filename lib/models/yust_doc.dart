import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yust/util/yust_serializable.dart';

import '../yust.dart';

abstract class YustDoc with YustSerializable {
  @JsonKey()
  String id;

  @JsonKey(fromJson: YustDoc.dateTimeFromJson, toJson: YustDoc.dateTimeToJson)
  DateTime? createdAt;

  @JsonKey()
  String? createdBy;

  @JsonKey(fromJson: YustDoc.dateTimeFromJson, toJson: YustDoc.dateTimeToJson)
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

  static List<dynamic> docListToJson(List<dynamic> list) {
    return list.map((item) => item.toJson()).toList();
  }

  static Map<String, T?> mapFromJson<T>(Map<String, dynamic>? map) {
    if (map == null) {
      return {};
    }
    return map.map<String, T?>((key, value) {
      if (value is FieldValue) {
        return MapEntry(key, null);
      } else if (value is Timestamp) {
        return MapEntry(key, YustDoc.dateTimeFromJson(value) as T?);
      } else if (value is Map && value['_seconds'] != null) {
        return MapEntry(key, YustDoc.dateTimeFromJson(value) as T?);
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
        return MapEntry(key, YustDoc.dateTimeToJson(value));
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, YustDoc.mapToJson(value));
      } else if (value is List) {
        return MapEntry(key, List.from(value));
      } else if (value is YustSerializable) {
        return MapEntry(key, (value as dynamic).toJson());
      } else {
        return MapEntry(key, value);
      }
      // } else {
      //   try {
      //     // If toJson is defined for the type, use it.
      //     return MapEntry(key, (value as dynamic).toJson());
      //   } on NoSuchMethodError {
      //     // Else: Just return the value
      //     return MapEntry(key, value);
      //   }
      // }
    });
  }

  // TODO: delete, use convertTimestamp instead
  static DateTime? dateTimeFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String &&
        RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(timestamp)) {
      return DateTime.parse(timestamp);
    } else if (timestamp is Map && timestamp['_seconds'] != null) {
      return Timestamp(timestamp['_seconds'], timestamp['_nanoseconds'])
          .toDate();
    } else {
      return null;
    }
  }

  // TODO; delete
  static dynamic dateTimeToJson(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    } else if (Yust.useTimestamps) {
      return Timestamp.fromDate(dateTime);
    } else {
      return dateTime.toIso8601String();
    }
  }

  static dynamic convertTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else {
      return value;
    }
  }
}
