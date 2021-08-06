import 'package:flutter/material.dart';

import '../yust.dart';

class YustFocusHandler extends StatelessWidget {
  final Widget child;

  YustFocusHandler({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Yust.service.unfocusCurrent(context);
      },
      child: child,
    );
  }
}
