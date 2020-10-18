import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../yust_store.dart';

class YustStoreBuilder<T extends YustStore> extends StatelessWidget {
  final Widget Function(BuildContext, Widget, T) builder;
  final Widget child;

  YustStoreBuilder({
    Key key,
    @required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      builder: (context, store, child) => builder(context, child, store),
      child: child,
    );
  }
}
