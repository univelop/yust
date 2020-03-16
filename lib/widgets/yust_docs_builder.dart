import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';
import 'yust_doc_builder.dart';

class YustDocsBuilder<T extends YustDoc> extends StatefulWidget {
  final YustDocSetup modelSetup;
  final List<List<dynamic>> filter;
  final List<String> orderBy;
  final bool _doNotWait;

  /// There will never be a null for the list given.
  final Widget Function(List<T>, YustBuilderInsights) builder;

  YustDocsBuilder({
    Key key,
    @required this.modelSetup,
    this.filter,
    this.orderBy,
    bool doNotWait,
    @required this.builder,
  })  : assert(modelSetup != null),
        assert(builder != null),
        _doNotWait = doNotWait ?? false,
        super(key: key);

  @override
  YustDocsBuilderState<T> createState() => YustDocsBuilderState<T>();
}

class YustDocsBuilderState<T extends YustDoc>
    extends State<YustDocsBuilder<T>> {
  /// May not be null.
  Stream<List<T>> _docStream;

  void initStream() {
    _docStream = Yust.service.getDocs<T>(
      widget.modelSetup,
      filterList: widget.filter,
      orderByList: widget.orderBy,
    );
  }

  bool updateStreamConditionally(YustDocsBuilder oldWidget) {
    bool updated = false;

    if (widget.modelSetup != oldWidget.modelSetup ||
        !ListEquality(ListEquality()).equals(widget.filter, oldWidget.filter) ||
        !ListEquality().equals(widget.orderBy, oldWidget.orderBy)) {
      updated = true;
      initStream();
    }

    return updated;
  }

  @override
  void initState() {
    super.initState();

    initStream();
  }

  @override
  void didUpdateWidget(YustDocsBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    updateStreamConditionally(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: _docStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }
        final opts = YustBuilderInsights(
          waiting: snapshot.connectionState == ConnectionState.waiting,
        );
        if (opts.waiting && !widget._doNotWait) {
          return Center(child: CircularProgressIndicator());
        }
        return widget.builder(snapshot.data ?? [], opts);
      },
    );
  }
}
