import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../yust_store.dart';

class YustStoreProvider<T extends YustStore> extends ChangeNotifierProvider<T> {
  YustStoreProvider({
    Key key,
    T Function(BuildContext) create,
    Widget child,
  }) : super(key: key, create: create, child: child);
}
