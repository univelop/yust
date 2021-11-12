import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:paginate_firestore/bloc/pagination_listeners.dart';
import 'package:paginate_firestore/paginate_firestore.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

class YustPaginatedListView<T extends YustDoc> extends StatefulWidget {
  final YustDocSetup<T> modelSetup;

  final ScrollController? scrollController;
  final List<String> orderBy;

  /// There will never be a null for the list given.
  // final Widget Function(List<T>, YustBuilderInsights) builder;
  final Widget Function(BuildContext, T?, int) listItemBuilder;

  YustPaginatedListView({
    Key? key,
    required this.modelSetup,
    required this.listItemBuilder,
    this.scrollController,
    required this.orderBy,
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

  @override
  void didUpdateWidget(YustPaginatedListView oldWidget) {
    super.didUpdateWidget(oldWidget as YustPaginatedListView<T>);
    updateStreamConditionally(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final query = Yust.service
        .getQuery(modelSetup: widget.modelSetup, orderByList: widget.orderBy);
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
        itemsPerPage: 50,
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

  void updateStreamConditionally(YustPaginatedListView oldWidget) {
    if (widget.modelSetup != oldWidget.modelSetup) {
      _refreshListener.refreshed = true;
      setState(() {
        key = Yust.service.randomString();
      });
    }
  }
}
