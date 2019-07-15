import 'package:flutter/material.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../yust.dart';

class YustDocBuilder<T extends YustDoc> extends StatelessWidget {
  
  final YustDocSetup modelSetup;
  final String id;
  final Widget Function(T) builder;

  YustDocBuilder({@required this.modelSetup, @required this.id, @required this.builder});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: Yust.service.getDoc(modelSetup, id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        return builder(snapshot.data);
      },
    );
  }

}