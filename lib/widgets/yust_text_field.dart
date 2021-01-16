import 'package:flutter/material.dart';
import 'package:yust/yust.dart';

typedef StringCallback = void Function(String);
typedef TabCallback = void Function();

class YustTextField extends StatefulWidget {
  final String label;
  final String value;
  final StringCallback onChanged;
  final StringCallback onEditingComplete;
  final TabCallback onTab;
  final int minLines;
  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final YustInputStyle style;
  final Widget prefixIcon;
  final TextCapitalization textCapitalization;

  YustTextField({
    Key key,
    this.label,
    this.value = '',
    this.onChanged,
    this.onEditingComplete,
    this.onTab,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.style,
    this.prefixIcon,
    this.textCapitalization = TextCapitalization.sentences,
  }) : super(key: key);

  @override
  _YustTextFieldState createState() => _YustTextFieldState();
}

class _YustTextFieldState extends State<YustTextField> {
  TextEditingController _controller;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && widget.onEditingComplete != null) {
        widget.onEditingComplete(_controller.value.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: widget.label,
        contentPadding: const EdgeInsets.all(20.0),
        border: widget.style == YustInputStyle.outlineBorder
            ? OutlineInputBorder()
            : null,
        prefixIcon: widget.prefixIcon,
      ),
      maxLines: widget.obscureText ? 1 : null,
      minLines: widget.minLines,
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: widget.minLines != null
          ? TextInputAction.newline
          : TextInputAction.next,
      onChanged: widget.onChanged == null
          ? null
          : (value) => widget.onChanged(value.trim()),
      onTap: widget.onTab,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      textCapitalization: widget.textCapitalization,
    );
  }
}
