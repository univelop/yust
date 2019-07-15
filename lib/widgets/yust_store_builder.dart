import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../yust.dart';
import '../yust_store.dart';

class YustStoreBuilder extends StatelessWidget {
  
  final Widget Function(BuildContext, Widget, YustStore) builder;

  YustStoreBuilder({@required this.builder});
  
  @override
  Widget build(BuildContext context) {
    return ScopedModel<YustStore>(
      model: Yust.store,
      child: ScopedModelDescendant<YustStore>(
        builder: builder,
      ),
    );
  }

}