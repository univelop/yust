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
  final TabCallback onTab;
  final bool readOnly;
  final bool enabled;
  final YustInputStyle style;

  YustNumberField({
    Key key,
    this.label,
    this.value,
    this.onChanged,
    this.onTab,
    this.enabled = true,
    this.readOnly = false,
    this.style,
  }) : super(key: key);

  @override
  _YustNumberFieldState createState() => _YustNumberFieldState();
}

class _YustNumberFieldState extends State<YustNumberField> {
  TextEditingController _controller;
  num oldValue;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
        text: widget.value?.toString()?.replaceAll(RegExp(r'\.'), ','));
  }

  @override
  void dispose() {
    _controller.dispose();

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
              : null),
      controller: _controller,
      onChanged: (value) {
        if (value == '') {
          widget.onChanged(null);
        } else {
          value = value.replaceAll(RegExp(r'\,'), '.');
          final numValue = num.tryParse(value);
          if (numValue != null && numValue != oldValue) {
            setState(() {
              oldValue = numValue;
            });
            widget.onChanged(numValue);
          }
        }
      },
      keyboardType: kIsWeb
          ? null
          : TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [WhitelistingTextInputFormatter(RegExp("[0-9\,\.\-]"))],
      onTap: widget.onTab,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
    );
  }
}
