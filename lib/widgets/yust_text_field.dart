import 'package:flutter/material.dart';

typedef StringCallback = void Function(String);

class YustTextField extends StatefulWidget {

  YustTextField({Key key, this.label, this.value = '', this.onChanged, this.minLines}): super(key: key);

  final String label;
  final String value;
  final StringCallback onChanged;
  final int minLines;

  @override
  _YustTextFieldState createState() => _YustTextFieldState();
}

class _YustTextFieldState extends State<YustTextField> {

  FocusNode _focusNode;
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
        contentPadding: const EdgeInsets.all(20.0)
      ),
      maxLines: null,
      minLines: widget.minLines,
      controller: _controller,
      onChanged: (value) {
        widget.onChanged(value);
      },
    );
  }
}
