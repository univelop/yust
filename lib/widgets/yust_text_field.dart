import 'package:flutter/material.dart';

typedef StringCallback = void Function(String);

class YustTextField extends StatefulWidget {

  YustTextField({Key key, this.label, this.value, this.onChanged, this.minLines}): super(key: key);

  final String label;
  final String value;
  final StringCallback onChanged;
  final int minLines;

  @override
  _YustTextFieldState createState() => _YustTextFieldState();
}

class _YustTextFieldState extends State<YustTextField> {

  FocusNode focusNode;
  TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: widget.value);
    
    focusNode = FocusNode();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        if (controller.text != widget.value) {
          widget.onChanged(controller.text);
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();

    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: widget.label,
        contentPadding: const EdgeInsets.all(20.0)
      ),
      maxLines: null,
      minLines: widget.minLines,
      controller: controller,
      focusNode: focusNode,
    );
  }
}
