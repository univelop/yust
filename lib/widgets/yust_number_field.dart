import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yust/yust.dart';

typedef ChangeCallback = void Function(num?);
typedef TabCallback = void Function();

class YustNumberField extends StatefulWidget {
  final String? label;
  final num? value;
  final ChangeCallback? onChanged;
  final ChangeCallback? onEditingComplete;
  final void Function()? onRealEditingComplete;
  final TextEditingController? controller;
  final TabCallback? onTab;
  final bool readOnly;
  final bool enabled;
  final YustInputStyle? style;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;

  YustNumberField({
    Key? key,
    this.label,
    this.value,
    this.onChanged,
    this.onEditingComplete,
    this.onRealEditingComplete,
    this.controller,
    this.onTab,
    this.enabled = true,
    this.readOnly = false,
    this.style,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
  }) : super(key: key);

  @override
  _YustNumberFieldState createState() => _YustNumberFieldState();
}

class _YustNumberFieldState extends State<YustNumberField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  num? _oldValue;
  late num _initValue;

  @override
  void initState() {
    super.initState();
    final value = widget.value?.toString().replaceAll(RegExp(r'\.'), ',');
    if (widget.controller != null && value != null) {
      widget.controller!.text = value;
    }
    _controller = widget.controller ?? TextEditingController(text: value);
    _initValue = widget.value ?? 0;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && widget.onEditingComplete != null) {
        widget.onEditingComplete!(_valueToNum(_controller.value.text.trim()));
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
    if (widget.value != null &&
        widget.onChanged == null &&
        widget.value != _initValue &&
        widget.value != _valueToNum(_controller.text.trim())) {
      _controller.text =
          widget.value!.toString().replaceAll(RegExp(r'\.'), ',');
      _initValue = widget.value!;
    }
    return TextField(
      decoration: InputDecoration(
        labelText: widget.label,
        contentPadding: const EdgeInsets.all(20.0),
        border: widget.style == YustInputStyle.outlineBorder
            ? OutlineInputBorder()
            : null,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
      ),
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged == null
          ? null
          : (value) {
              num? numValue = _valueToNum(value.trim());
              if (numValue != _oldValue) {
                setState(() {
                  _oldValue = numValue;
                });
                widget.onChanged!(numValue);
              }
            },
      onEditingComplete: widget.onRealEditingComplete,
      keyboardType: kIsWeb
          ? null
          : TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp("[0-9\,\.\-]"))
      ],
      textInputAction: TextInputAction.next,
      onTap: widget.onTab,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
    );
  }

  num? _valueToNum(String value) {
    if (value == '') {
      return null;
    } else {
      value = value.replaceAll(RegExp(r'\,'), '.');
      final numValue = num.tryParse(value);
      return numValue;
    }
  }
}
