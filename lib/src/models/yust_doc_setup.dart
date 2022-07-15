import 'yust_doc.dart';

class YustDocSetup<T extends YustDoc> {
  String collectionName;

  T Function(Map<String, dynamic> json) fromJson;

  T Function() newDoc;

  ///If true the [userId] of the [YustDoc] will be automatically set when saving.
  bool forUser;

  ///If true the [envId] of the [YustDoc] will be automatically set when saving.
  bool forEnvironment;

  ///Should be set to true if this setup is used for an environment.
  bool isEnvironment;

  /// Should null values be removed, before writing the doc to the database
  bool removeNullValues;

  void Function(T doc)? onInit;

  Future<void> Function(T doc)? onSave;

  YustDocSetup({
    required this.collectionName,
    required this.fromJson,
    required this.newDoc,
    this.forUser = false,
    this.forEnvironment = false,
    this.isEnvironment = false,
    this.onInit,
    this.onSave,
    this.removeNullValues = true,
  });
}
