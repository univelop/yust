import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../yust.dart';
import 'yust_doc_setup.dart';

abstract class YustDoc {
  static final setup = YustDocSetup(collectionName: 'myCollection');

  @JsonKey()
  String id;
  @JsonKey(fromJson: YustDoc.dateTimeFromJson, toJson: YustDoc.dateTimeToJson)
  DateTime createdAt;
  @JsonKey()
  String createdBy;
  @JsonKey(fromJson: YustDoc.dateTimeFromJson, toJson: YustDoc.dateTimeToJson)
  DateTime modifiedAt;
  @JsonKey()
  String modifiedBy;
  @JsonKey()
  String userId;
  @JsonKey()
  String envId;

  YustDoc({
    this.id,
    this.createdAt,
    this.createdBy,
    this.modifiedAt,
    this.modifiedBy,
    this.userId,
    this.envId,
  });

  YustDoc.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson();

  static List<dynamic> docListToJson(List<dynamic> list) {
    return list.map((item) => item.toJson()).toList();
  }

  static Map<String, T> mapFromJson<T>(Map<String, dynamic> map) {
    if (map == null) return {};
    return map.map((key, value) {
      if (value is FieldValue) {
        return MapEntry(key, null);
      } else {
        return MapEntry(key, value as T);
      }
    });
  }

  static Map<String, dynamic> mapToJson(Map<String, dynamic> map) {
    if (map == null) return null;
    return map.map((key, value) {
      if (value == null) {
        return MapEntry(key, FieldValue.delete());
      } else if (value is Map) {
        return MapEntry(key, Map.from(value));
      } else if (value is List) {
        return MapEntry(key, List.from(value));
      } else {
        return MapEntry(key, value);
      }
    });
  }

  static DateTime dateTimeFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is Map && timestamp['_seconds'] != null) {
      return Timestamp(timestamp['_seconds'], timestamp['_nanoseconds'])
          .toDate();
    } else {
      return null;
    }
  }

  static dynamic dateTimeToJson(DateTime dateTime) {
    if (dateTime == null) {
      return null;
    } else if (Yust.useTimestamps) {
      return Timestamp.fromDate(dateTime);
    } else {
      return dateTime.toIso8601String();
    }
  }
}
