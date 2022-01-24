import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

class YustPaginatedListView<T extends YustDoc> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final query = Yust.databaseService
        .getQuery(modelSetup: modelSetup, orderByList: orderBy);

    return PaginateFirestore(
      scrollController: scrollController,
      header: header,
      footer: footer,
      emptyDisplay: emptyInfo,
      itemBuilderType: PaginateBuilderType.listView,
      itemBuilder: (index, context, documentSnapshot) =>
          _itemBuilder(index, context, documentSnapshot),
      // orderBy is compulsary to enable pagination
      query: query,
      itemsPerPage: 50,
      isLive: true,
      initialLoader: SingleChildScrollView(
        controller: scrollController,
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _itemBuilder(
      int index, BuildContext context, DocumentSnapshot documentSnapshot) {
    final item =
        Yust.databaseService.transformDoc(modelSetup, documentSnapshot);
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
      return listItemBuilder(context, item, index);
    }
  }
}
