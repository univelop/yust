import 'package:flutter/material.dart';

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

  void Function(dynamic doc) onInit;
  void Function(dynamic doc) onMigrate;
  void Function(dynamic doc) onSave;
  void Function(dynamic doc) onDelete;

  YustDocSetup({
    @required this.collectionName,
    this.fromJson,
    this.newDoc,
    this.forUser = false,
    this.forEnvironment = false,
    this.isEnvironment = false,
    this.onInit,
    this.onMigrate,
    this.onSave,
    this.onDelete,
  });
}
