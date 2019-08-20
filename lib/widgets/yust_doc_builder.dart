import 'package:flutter/material.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

class YustDocBuilder<T extends YustDoc> extends StatelessWidget {
  final YustDocSetup modelSetup;
  final String id;
  final List<List<dynamic>> filter;
  final bool doNotWait;
  final bool createIfNull;
  final Widget Function(T) builder;

  YustDocBuilder({
    @required this.modelSetup,
    this.id,
    this.filter,
    this.doNotWait = false,
    this.createIfNull = false,
    @required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final docStream = (id != null)
        ? Yust.service.getDoc<T>(modelSetup, id)
        : Yust.service.getFirstDoc<T>(modelSetup, filter);
    return StreamBuilder<T>(
      stream: docStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }
        if (snapshot.connectionState == ConnectionState.waiting && !doNotWait) {
          return Center(child: CircularProgressIndicator());
        }
        var doc = snapshot.data;
        if (doc == null && createIfNull) {
          doc = Yust.service.initDoc<T>(modelSetup);
        }
        return builder(doc);
      },
    );
  }
}
