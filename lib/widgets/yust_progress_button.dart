import 'package:flutter/material.dart';

import '../yust.dart';

class YustProgressButton extends StatefulWidget {
  final Widget? child;
  final Future<void> Function() onPressed;
  final Color? color;
  final Color spinnerColor;
  final bool inProgress;

  YustProgressButton({
    Key? key,
    this.child,
    required this.onPressed,
    this.color,
    this.spinnerColor = Colors.white,
    this.inProgress = false,
  }) : super(key: key);

  @override
  _YustProgressButtonState createState() => _YustProgressButtonState();
}

class _YustProgressButtonState extends State<YustProgressButton> {
  bool? _inProgressLocal;

  @override
  Widget build(BuildContext context) {
    bool? waiting;
    waiting = widget.inProgress;
    if (_inProgressLocal != null) {
      waiting = _inProgressLocal;
      _inProgressLocal = null;
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: widget.color,
      ),
      onPressed: (waiting ??= false) ? null : onPressed,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: double.infinity,
          height: 40.0,
          child: Center(child: _buildInnerButton(waiting)),
        ),
      ),
    );
  }

  Widget? _buildInnerButton(bool waiting) {
    if (waiting) {
      return CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(widget.spinnerColor),
      );
    } else {
      return widget.child;
    }
  }

  void onPressed() async {
    Yust.helperService.unfocusCurrent(context);
    setState(() {
      _inProgressLocal = true;
    });
    await widget.onPressed();
    if (mounted) {
      setState(() {
        _inProgressLocal = false;
      });
    }
  }
}
