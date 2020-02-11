import 'package:json_annotation/json_annotation.dart';

import 'yust_doc_setup.dart';

@JsonSerializable()
abstract class YustDoc {
  static final setup = YustDocSetup(collectionName: 'myCollection');

  @JsonKey()
  String id;
  @JsonKey()
  String createdAt;
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
}
