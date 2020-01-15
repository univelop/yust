import 'package:flutter/material.dart';

class YustProgressButton extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onPressed;
  final Color color;
  final Color spinnerColor;
  final bool inProgress;

  YustProgressButton(
      {Key key,
      this.child,
      this.onPressed,
      this.color,
      this.spinnerColor = Colors.white,
      this.inProgress = false})
      : super(key: key);

  @override
  _YustProgressButtonState createState() => _YustProgressButtonState();
}

class _YustProgressButtonState extends State<YustProgressButton> {
  bool _inProgressLocal;

  @override
  Widget build(BuildContext context) {
    bool waiting;
    if (widget.inProgress != null) {
      waiting = widget.inProgress;
    }
    if (_inProgressLocal != null) {
      waiting = _inProgressLocal;
      _inProgressLocal = null;
    }
    return RaisedButton(
      color: widget.color,
      disabledColor: widget.color,
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        width: double.infinity,
        height: 40.0,
        child: Center(child: _buildInnerButton(waiting)),
      ),
      onPressed: waiting ? null : onPressed,
    );
  }

  Widget _buildInnerButton(bool waiting) {
    if (waiting) {
      return CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(widget.spinnerColor),
      );
    } else {
      return widget.child;
    }
  }

  void onPressed() async {
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
