import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_docs_builder.dart';
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
  @override
  Widget build(BuildContext context) {
    if (widget.filter == null || widget.filter!.isEmpty) {
      return YustPaginatedListView(
        orderBy: widget.orderBy ?? [],
        modelSetup: widget.modelSetup,
        listItemBuilder: widget.listItemBuilder,
        scrollController: widget.scrollController,
      );
    }

    return YustDocsBuilder(
        modelSetup: widget.modelSetup,
        filter: widget.filter,
        doNotWait: widget._doNotWait,
        builder: (objects, insights) {
          return ListView.builder(
              controller: widget.scrollController,
              itemCount: objects.length,
              itemBuilder: (context, index) {
                return widget.listItemBuilder(
                    context, objects[index] as T?, index);
              });
        });
  }
}
