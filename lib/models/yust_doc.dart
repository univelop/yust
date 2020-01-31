import 'yust_doc_setup.dart';

abstract class YustDoc {
  static final setup = YustDocSetup(collectionName: 'myCollection');

  String id;
  String createdAt;
  String userId;
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
