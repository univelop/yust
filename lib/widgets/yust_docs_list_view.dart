import 'package:flutter/material.dart';
import 'package:paginate_firestore/widgets/empty_display.dart';
import 'package:yust/widgets/yust_docs_builder.dart';
import 'package:yust/widgets/yust_paginated_list_view.dart';
import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';

///builds a standard listView with pagination if no filters are set
///uses the yustdocsbuilder otherwise

class YustDocsListView<T extends YustDoc> extends StatefulWidget {
  final YustDocSetup<T> modelSetup;
  final List<List<dynamic>>? filter;
  final List<String>? orderBy;
  final bool _doNotWait;
  final ScrollController? scrollController;
  final Widget Function(BuildContext, T?, int) listItemBuilder;
  final Widget? header;
  final Widget? footer;
  final Widget emptyInfo;

  YustDocsListView({
    Key? key,
    required this.modelSetup,
    this.filter,
    this.orderBy,
    this.header,
    this.emptyInfo = const EmptyDisplay(),
    this.footer,
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
        header: widget.header,
        footer: widget.footer,
        emptyInfo: widget.emptyInfo,
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
