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
  String userId;
  @JsonKey()
  String envId;

  YustDoc({
    this.id,
    this.createdAt,
    this.userId,
    this.envId,
  });

  YustDoc.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson();

  static List<dynamic> docListToJson(List<dynamic> list) {
    return list.map((item) => item.toJson()).toList();
  }

  static Map<String, dynamic> mapToJson(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value == null) {
        return MapEntry(key, FieldValue.delete());
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
