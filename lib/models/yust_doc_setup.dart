import 'package:flutter/material.dart';

import 'yust_doc.dart';

class YustDocSetup {

  String collectionName;
  YustDoc Function(Map<String, dynamic> json) fromJson;
  YustDoc Function() newDoc;
  bool forUser;
  bool forEnvironment;
  bool isEnvironment;
  void Function(dynamic doc) onInit;
  void Function(dynamic doc) onMigrate;
  void Function(dynamic doc) onDelete;

  YustDocSetup({@required this.collectionName, this.fromJson, this.newDoc, this.forUser = false, this.forEnvironment = false, this.isEnvironment = false, this.onInit, this.onMigrate, this.onDelete});

}