import 'package:flutter/material.dart';

class YustProgressButton extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onPressed;
  final Color color;
  final Color spinnerColor;

  YustProgressButton(
      {Key key,
      this.child,
      this.onPressed,
      this.color,
      this.spinnerColor = Colors.white})
      : super(key: key);

  @override
  _YustProgressButtonState createState() => _YustProgressButtonState();
}

class _YustProgressButtonState extends State<YustProgressButton> {
  bool _waiting = false;

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: widget.color,
      disabledColor: widget.color,
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        width: double.infinity,
        height: 40.0,
        child: Center(child: _buildInnerButton()),
      ),
      onPressed: _waiting ? null : onPressed,
    );
  }

  Widget _buildInnerButton() {
    if (_waiting) {
      return CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(widget.spinnerColor),
      );
    } else {
      return widget.child;
    }
  }

  void onPressed() async {
    setState(() {
      _waiting = true;
    });
    await widget.onPressed();
    setState(() {
      _waiting = false;
    });
  }
}
