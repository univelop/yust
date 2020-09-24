import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yust/yust.dart';

typedef ChangeCallback = void Function(num);
typedef TabCallback = void Function();

class YustNumberField extends StatefulWidget {
  final String label;
  final num value;
  final ChangeCallback onChanged;
  final ChangeCallback onEditingComplete;
  final TabCallback onTab;
  final bool readOnly;
  final bool enabled;
  final YustInputStyle style;
  final Widget prefixIcon;

  YustNumberField({
    Key key,
    this.label,
    this.value,
    this.onChanged,
    this.onEditingComplete,
    this.onTab,
    this.enabled = true,
    this.readOnly = false,
    this.style,
    this.prefixIcon,
  }) : super(key: key);

  @override
  _YustNumberFieldState createState() => _YustNumberFieldState();
}

class _YustNumberFieldState extends State<YustNumberField> {
  TextEditingController _controller;
  FocusNode _focusNode = FocusNode();
  num _oldValue;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
        text: widget.value?.toString()?.replaceAll(RegExp(r'\.'), ','));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && widget.onEditingComplete != null) {
        widget.onEditingComplete(_valueToNum(_controller.value.text));
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
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged == null
          ? null
          : (value) {
              num numValue = _valueToNum(value);
              if (numValue != _oldValue) {
                setState(() {
                  _oldValue = numValue;
                });
                widget.onChanged(numValue);
              }
            },
      keyboardType: kIsWeb
          ? null
          : TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp("[0-9\,\.\-]"))
      ],
      onTap: widget.onTab,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
    );
  }

  num _valueToNum(String value) {
    if (value == '') {
      return null;
    } else {
      value = value.replaceAll(RegExp(r'\,'), '.');
      final numValue = num.tryParse(value);
      return numValue;
    }
  }
}
