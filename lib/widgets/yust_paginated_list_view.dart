import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:paginate_firestore/paginate_firestore.dart';
import 'package:paginate_firestore/widgets/empty_display.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

class YustPaginatedListView<T extends YustDoc> extends StatefulWidget {
  final YustDocSetup<T> modelSetup;

  final ScrollController? scrollController;
  final List<String> orderBy;
  final Widget Function(BuildContext, T?, int) listItemBuilder;
  final Widget? footer;
  final Widget? header;
  final Widget emptyInfo;

  YustPaginatedListView({
    Key? key,
    required this.modelSetup,
    required this.listItemBuilder,
    this.scrollController,
    required this.orderBy,
    this.emptyInfo = const EmptyDisplay(),
    this.footer,
    this.header,
  }) : super(key: key);

  @override
  YustPaginatedListViewState<T> createState() =>
      YustPaginatedListViewState<T>();
}

class YustPaginatedListViewState<T extends YustDoc>
    extends State<YustPaginatedListView<T>> {
  @override
  Widget build(BuildContext context) {
    final query = Yust.service
        .getQuery(modelSetup: widget.modelSetup, orderByList: widget.orderBy);
    return PaginateFirestore(
      scrollController: widget.scrollController,
      header: widget.header,
      footer: widget.footer,
      emptyDisplay: widget.emptyInfo,
      itemBuilderType: PaginateBuilderType.listView,
      itemBuilder: (index, context, documentSnapshot) =>
          _itemBuilder(index, context, documentSnapshot),
      // orderBy is compulsary to enable pagination
      query: query,
      itemsPerPage: 50,
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
