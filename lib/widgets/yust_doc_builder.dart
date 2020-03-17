import 'package:flutter/material.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

class YustBuilderInsights {
  bool waiting;

  YustBuilderInsights({this.waiting});
}

class YustDocBuilder<T extends YustDoc> extends StatelessWidget {
  final YustDocSetup modelSetup;
  final String id;
  final List<List<dynamic>> filter;
  final List<String> orderBy;
  final bool doNotWait;
  final bool createIfNull;
  final Widget Function(T, YustBuilderInsights) builder;

  YustDocBuilder({
    Key key,
    @required this.modelSetup,
    this.id,
    this.filter,
    this.orderBy,
    this.doNotWait = false,
    this.createIfNull = false,
    @required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final docStream = (id != null)
        ? Yust.service().getDoc<T>(modelSetup, id)
        : Yust.service()
            .getFirstDoc<T>(modelSetup, filter, orderByList: orderBy);
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
          doc = Yust.service().initDoc<T>(modelSetup);
        }
        final opts = YustBuilderInsights(
          waiting: snapshot.connectionState == ConnectionState.waiting,
        );
        return builder(doc, opts);
      },
    );
  }
}
