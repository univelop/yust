import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

const NULL_PLACEHOLDER = 'NULL_VALUE';

abstract class YustDoc {
  String id;

  DateTime? createdAt;

  String? createdBy;

  DateTime? modifiedAt;

  String? modifiedBy;

  String? userId;

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

  static dynamic convertTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is Map && value['_seconds'] != null) {
      return Timestamp(value['_seconds'], value['_nanoseconds']).toDate();
    } else {
      return value;
    }
  }
}
