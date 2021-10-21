import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:paginate_firestore/bloc/pagination_listeners.dart';
import 'package:paginate_firestore/paginate_firestore.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

class YustPaginatedListView<T extends YustDoc> extends StatefulWidget {
  final YustDocSetup<T> modelSetup;
  final List<List<dynamic>>? filter;
  final List<String>? orderBy;
  final ScrollController? scrollController;

  /// There will never be a null for the list given.
  // final Widget Function(List<T>, YustBuilderInsights) builder;
  final Widget Function(BuildContext, T?, int) listItemBuilder;

  YustPaginatedListView({
    Key? key,
    required this.modelSetup,
    this.filter,
    this.orderBy,
    required this.listItemBuilder,
    this.scrollController,
  }) : super(key: key);

  @override
  YustPaginatedListViewState<T> createState() =>
      YustPaginatedListViewState<T>();
}

class YustPaginatedListViewState<T extends YustDoc>
    extends State<YustPaginatedListView<T>> {
  PaginateRefreshedChangeListener _refreshListener =
      PaginateRefreshedChangeListener();

  String key = Yust.service.randomString();

  void updateStreamConditionally(YustPaginatedListView oldWidget) {
    if (widget.modelSetup != oldWidget.modelSetup ||
        !ListEquality(ListEquality()).equals(widget.filter, oldWidget.filter) ||
        !ListEquality().equals(widget.orderBy, oldWidget.orderBy)) {
      _refreshListener.refreshed = true;
      setState(() {
        key = Yust.service.randomString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(YustPaginatedListView oldWidget) {
    super.didUpdateWidget(oldWidget as YustPaginatedListView<T>);
    updateStreamConditionally(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final filters =
        widget.filter!.where((filter) => filter[0] != null).toList();
    final query =
        Yust.service.getQuery(widget.modelSetup, filters, widget.orderBy);
    return RefreshIndicator(
      child: PaginateFirestore(
        key: ValueKey(key),
        scrollController: widget.scrollController,
        itemBuilderType: PaginateBuilderType.listView,
        itemBuilder: (index, context, documentSnapshot) =>
            _itemBuilder(index, context, documentSnapshot),
        // orderBy is compulsary to enable pagination
        query: query,
        listeners: [
          _refreshListener,
        ],
        itemsPerPage: 10,
      ),
      onRefresh: () async {
        _refreshListener.refreshed = true;
      },
    );
  }

  Widget _itemBuilder(
      int index, BuildContext context, DocumentSnapshot documentSnapshot) {
    final item = Yust.service.transformDoc(widget.modelSetup, documentSnapshot);
    if (item == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 100.0),
        child: Center(
          child: Text(
            'Keine Daten vorhanden.\n',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return widget.listItemBuilder(context, item, index);
    }
  }
}
