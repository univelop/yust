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
  final ScrollController scrollController;

  /// There will never be a null for the list given.
  // final Widget Function(List<T>, YustBuilderInsights) builder;
  final Widget Function(BuildContext, T?, int) listItemBuilder;

  YustPaginatedListView({
    Key? key,
    required this.modelSetup,
    this.filter,
    this.orderBy,
    required this.listItemBuilder,
    required this.scrollController,
  }) : super(key: key);

  @override
  YustPaginatedListViewState<T> createState() =>
      YustPaginatedListViewState<T>();
}

class YustPaginatedListViewState<T extends YustDoc>
    extends State<YustPaginatedListView<T>> {
  // DocumentSnapshot? _lastVisible = null;
  // List<List<T>> _allPagedResults = <List<T>>[];
  // final _pagingController = PagingController<int, T>(firstPageKey: 0);
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
    // _pagingController.dispose();
  }

  @override
  void didUpdateWidget(YustPaginatedListView oldWidget) {
    super.didUpdateWidget(oldWidget as YustPaginatedListView<T>);
    updateStreamConditionally(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // return List<T>>(
    //   stream: _docStream,
    //   builder: (context, snapshot) {
    //     if (snapshot.hasError) {
    //       throw snapshot.error!;
    //     }
    //     final opts = YustBuilderInsights(
    //       waiting: snapshot.connectionState == ConnectionState.waiting,
    //     );
    //     if (opts.waiting! && !widget._doNotWait) {
    //       return Center(child: CircularProgressIndicator());
    //     }
    //     return widget.builder(snapshot.data ?? [], opts);
    //   },
    // );
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
    // return _buildPaginationView(context);
  }

  Widget _itemBuilder(
      int index, BuildContext context, DocumentSnapshot documentSnapshot) {
    final item = Yust.service.transformDoc(widget.modelSetup, documentSnapshot);

    return widget.listItemBuilder(context, item, index);
  }
}

  // Widget _buildPaginationView(BuildContext context) {
  //   return RefreshIndicator(
  //     child: PagedListView.separated(
  //         pagingController: _pagingController,
  //         builderDelegate: PagedChildBuilderDelegate(
  //             firstPageErrorIndicatorBuilder: (context) =>
  //                 (Text('Sorry first page')),
  //             noItemsFoundIndicatorBuilder: (context) =>
  //                 (Text('Sorry, no items')),
  //             itemBuilder: (context, record, index) =>
  //                 widget.listItemBuilder(context, record, index)),
  //         separatorBuilder: (context, index) => SizedBox.shrink()),
  //     onRefresh: () => Future.sync(() => _pagingController.refresh()),
  //   );
  // }

  // Future<void> _fetchItems(int pageKey) async {
  //   try {
  //     final newItems = await Yust.service.getDocsOnce<T>(widget.modelSetup,
  //         orderByList: ['title'],
  //         filterList: widget.filter,
  //         lastVisible: _lastVisible,
  //         setLastVisible: setLastVisible);

  //     final pageExists = pageKey < _allPagedResults.length;

  //     if (pageExists) {
  //       _allPagedResults[pageKey] = newItems;
  //     } else {
  //       _allPagedResults.add(newItems);
  //     }

  //     _pagingController.appendPage(newItems, pageKey + 1);
  //   } catch (error) {
  //     _pagingController.error = error;
  //   }
  // }

  // void setLastVisible(DocumentSnapshot? newLastVisible) {
  //   _lastVisible = newLastVisible;
  // }

