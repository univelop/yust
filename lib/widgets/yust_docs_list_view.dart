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
  final Widget header;
  final Widget footer;
  final Widget emptyInfo;
  final int Function(T a, T b)? sort;

  YustDocsListView({
    Key? key,
    required this.modelSetup,
    this.filter,
    this.orderBy,
    Widget? header,
    this.emptyInfo = const EmptyDisplay(),
    Widget? footer,
    bool? doNotWait,
    this.scrollController,
    required this.sort,
    required this.listItemBuilder,
  })  : _doNotWait = doNotWait ?? false,
        header = SliverToBoxAdapter(child: header),
        footer = SliverToBoxAdapter(child: footer),
        super(key: key);

  @override
  YustDocsListViewState<T> createState() => YustDocsListViewState<T>();
}

class YustDocsListViewState<T extends YustDoc>
    extends State<YustDocsListView<T>> {
  @override
  Widget build(BuildContext context) {
    if (widget.filter == null || widget.filter!.isEmpty) {
      return YustPaginatedListView<T>(
        header: widget.header,
        footer: widget.footer,
        emptyInfo: widget.emptyInfo,
        orderBy: widget.orderBy ?? [],
        modelSetup: widget.modelSetup,
        listItemBuilder: widget.listItemBuilder,
        scrollController: widget.scrollController,
      );
    }

    return Container(
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          widget.header,
          YustDocsBuilder<T>(
              modelSetup: widget.modelSetup,
              filter: widget.filter,
              doNotWait: widget._doNotWait,
              loadingIndicator: SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator())),
              builder: (objects, insights) {
                objects.sort(widget.sort);
                if (objects.isNotEmpty) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return widget.listItemBuilder(
                            context, objects[index], index);
                      },
                      childCount: objects.length,
                    ),
                  );
                } else {
                  return SliverToBoxAdapter(child: widget.emptyInfo);
                }
              }),
          widget.footer
        ],
      ),
    );
  }
}
