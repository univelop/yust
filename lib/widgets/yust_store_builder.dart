import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../yust.dart';
import '../yust_store.dart';

class YustStoreBuilder<T extends YustStore> extends StatelessWidget {
  final Widget Function(BuildContext, Widget, T) builder;

  YustStoreBuilder({
    Key key,
    @required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScopedModel<T>(
      model: Yust.store as T,
      child: ScopedModelDescendant<T>(
        builder: builder,
      ),
    );
  }
}
