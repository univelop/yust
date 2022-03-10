import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';
import 'yust_doc_builder.dart';

class YustDocsBuilder<T extends YustDoc> extends StatefulWidget {
  final YustDocSetup<T> modelSetup;
  final List<List<dynamic>>? filter;
  final List<String>? orderBy;
  final bool showLoadingSpinner;
  final Widget? loadingIndicator;

  /// There will never be a null for the list given.
  final Widget Function(List<T>, YustBuilderInsights, BuildContext) builder;

  YustDocsBuilder({
    Key? key,
    required this.modelSetup,
    this.filter,
    this.orderBy,
    bool? doNotWait,
    this.showLoadingSpinner = false,
    this.loadingIndicator,
    required this.builder,
  }) : super(key: key);

  @override
  YustDocsBuilderState<T> createState() => YustDocsBuilderState<T>();
}

class YustDocsBuilderState<T extends YustDoc>
    extends State<YustDocsBuilder<T>> {
  late Stream<List<T>> _docStream;

  void initStream() {
    _docStream = Yust.databaseService.getDocs<T>(
      widget.modelSetup,
      filterList: widget.filter,
      orderByList: widget.orderBy,
    );
  }

  void updateStreamConditionally(YustDocsBuilder oldWidget) {
    if (widget.modelSetup != oldWidget.modelSetup ||
        !ListEquality(ListEquality<dynamic>())
            .equals(widget.filter, oldWidget.filter) ||
        !ListEquality<dynamic>().equals(widget.orderBy, oldWidget.orderBy)) {
      initStream();
    }
  }

  @override
  void initState() {
    super.initState();

    initStream();
  }

  @override
  void didUpdateWidget(YustDocsBuilder oldWidget) {
    super.didUpdateWidget(oldWidget as YustDocsBuilder<T>);

    updateStreamConditionally(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: _docStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error!;
        }
        final opts = YustBuilderInsights(
          waiting: snapshot.connectionState == ConnectionState.waiting,
        );
        if (opts.waiting! && widget.showLoadingSpinner) {
          return widget.loadingIndicator != null
              ? widget.loadingIndicator!
              : Center(child: CircularProgressIndicator());
        }
        return widget.builder(snapshot.data ?? [], opts, context);
      },
    );
  }
}
