import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

class YustBuilderInsights {
  bool? waiting;

  YustBuilderInsights({this.waiting});
}

class YustDocBuilder<T extends YustDoc> extends StatefulWidget {
  final YustDocSetup<T> modelSetup;
  final String? id;
  final List<List<dynamic>>? filter;
  final List<String>? orderBy;
  final bool _doNotWait;
  final bool _createIfNull;
  final Widget Function(T?, YustBuilderInsights) builder;

  YustDocBuilder({
    Key? key,
    required this.modelSetup,
    this.id,
    this.filter,
    this.orderBy,
    bool? doNotWait,
    bool? createIfNull,
    required this.builder,
  })  : _doNotWait = doNotWait ?? false,
        _createIfNull = createIfNull ?? false,
        super(key: key);

  @override
  YustDocBuilderState<T> createState() => YustDocBuilderState<T>();
}

class YustDocBuilderState<T extends YustDoc> extends State<YustDocBuilder<T>> {
  /// May not be null.
  Stream<T?>? _docStream;

  void initStream() {
    if (widget.id != null) {
      _docStream = Yust.service.getDoc<T>(
        widget.modelSetup,
        widget.id!,
      );
    } else {
      _docStream = Yust.service.getFirstDoc<T>(
        widget.modelSetup,
        widget.filter,
        orderByList: widget.orderBy,
      );
    }
  }

  bool updateStreamConditionally(YustDocBuilder oldWidget) {
    bool updated = false;

    if (widget.modelSetup != oldWidget.modelSetup ||
        widget.id != oldWidget.id ||
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
  void didUpdateWidget(YustDocBuilder oldWidget) {
    super.didUpdateWidget(oldWidget as YustDocBuilder<T>);

    updateStreamConditionally(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T?>(
      stream: _docStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error!;
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !widget._doNotWait) {
          return Center(child: CircularProgressIndicator());
        }
        var doc = snapshot.data;
        if (doc == null && widget._createIfNull) {
          doc = Yust.service.initDoc<T>(widget.modelSetup);
        }
        final opts = YustBuilderInsights(
          waiting: snapshot.connectionState == ConnectionState.waiting,
        );
        return widget.builder(doc, opts);
      },
    );
  }
}
