import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_paginated_listView.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';
import 'yust_doc_builder.dart';

///builds a standard listView with pagination if no filters are set
///uses the yustdocsbuilder otherwise

class YustDocsListView<T extends YustDoc> extends StatefulWidget {
  final YustDocSetup<T> modelSetup;
  final List<List<dynamic>>? filter;
  final List<String>? orderBy;
  final bool _doNotWait;
  final ScrollController? scrollController;
  final Widget Function(BuildContext, T?, int) listItemBuilder;

  YustDocsListView({
    Key? key,
    required this.modelSetup,
    this.filter,
    this.orderBy,
    bool? doNotWait,
    this.scrollController,
    required this.listItemBuilder,
  })  : _doNotWait = doNotWait ?? false,
        super(key: key);

  @override
  YustDocsListViewState<T> createState() => YustDocsListViewState<T>();
}

class YustDocsListViewState<T extends YustDoc>
    extends State<YustDocsListView<T>> {
  late Stream<List<T>> _docStream;

  @override
  void initState() {
    super.initState();
    if (widget.filter != null) {
      initStream();
    }
  }

  @override
  void didUpdateWidget(YustDocsListView oldWidget) {
    super.didUpdateWidget(oldWidget as YustDocsListView<T>);

    updateStreamConditionally(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filter == null) {
      return YustPaginatedListView(
        modelSetup: widget.modelSetup,
        listItemBuilder: widget.listItemBuilder,
        scrollController: widget.scrollController,
      );
    }

    return StreamBuilder<List<T>>(
      stream: _docStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error!;
        }
        final opts = YustBuilderInsights(
          waiting: snapshot.connectionState == ConnectionState.waiting,
        );
        if (opts.waiting! && !widget._doNotWait) {
          return Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
            controller: widget.scrollController,
            itemBuilder: (context, index) {
              return widget.listItemBuilder(
                  context, snapshot.data?[index], index);
            });
      },
    );
  }

  void initStream() {
    _docStream = Yust.service.getDocs<T>(
      widget.modelSetup,
      filterList: widget.filter,
      orderByList: widget.orderBy,
    );
  }

  bool updateStreamConditionally(YustDocsListView oldWidget) {
    bool updated = false;

    if (widget.modelSetup != oldWidget.modelSetup ||
        !ListEquality(ListEquality()).equals(widget.filter, oldWidget.filter) ||
        !ListEquality().equals(widget.orderBy, oldWidget.orderBy)) {
      updated = true;
      initStream();
    }

    return updated;
  }
}
