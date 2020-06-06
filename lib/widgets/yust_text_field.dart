import 'package:flutter/material.dart';
import 'package:yust/yust.dart';

typedef StringCallback = void Function(String);
typedef TabCallback = void Function();

class YustTextField extends StatefulWidget {
  final String label;
  final String value;
  final StringCallback onChanged;
  final TabCallback onTab;
  final int minLines;
  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final YustInputStyle style;

  YustTextField({
    Key key,
    this.label,
    this.value = '',
    this.onChanged,
    this.onTab,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.style,
  }) : super(key: key);

  @override
  _YustTextFieldState createState() => _YustTextFieldState();
}

class _YustTextFieldState extends State<YustTextField> {
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.text != widget.value) {
      _controller.text = widget.value;
    }
    return TextField(
      decoration: InputDecoration(
          labelText: widget.label,
          contentPadding: const EdgeInsets.all(20.0),
          border: widget.style == YustInputStyle.outlineBorder
              ? OutlineInputBorder()
              : null),
      maxLines: widget.obscureText ? 1 : null,
      minLines: widget.minLines,
      controller: _controller,
      onChanged: widget.onChanged,
      onTap: widget.onTab,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
