import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yust/widgets/yust_text_field.dart';
import 'package:yust/yust.dart';

typedef ChangeCallback = void Function(num?);
typedef TapCallback = void Function();

class YustNumberField extends StatelessWidget {
  final String? label;
  final num? value;
  final ChangeCallback? onChanged;
  final ChangeCallback? onEditingComplete;
  final TextEditingController? controller;
  final TapCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final YustInputStyle style;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool hideKeyboardOnAutofocus;
  final FormFieldValidator<num?>? validator;
  final bool divider;

  YustNumberField({
    Key? key,
    this.label,
    this.value,
    this.onChanged,
    this.onEditingComplete,
    this.controller,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.style = YustInputStyle.normal,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.autofocus = false,
    this.hideKeyboardOnAutofocus = true,
    this.validator,
    this.divider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return YustTextField(
      style: style,
      label: label,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      value: _numToString(value),
      controller: controller,
      onChanged: onChanged == null
          ? null
          : (value) {
              var numValue = _valueToNum(value?.trim() ?? '');
              onChanged!(numValue);
            },
      onEditingComplete: onEditingComplete == null
          ? null
          : (value) => onEditingComplete!(_valueToNum(value?.trim() ?? '')),
      keyboardType: kIsWeb
          ? null
          : TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[0-9\,\.\-]'))
      ],
      textInputAction: TextInputAction.next,
      onTap: onTap,
      readOnly: readOnly,
      enabled: enabled,
      autovalidateMode:
          validator != null ? AutovalidateMode.onUserInteraction : null,
      autofocus: autofocus,
      hideKeyboardOnAutofocus: hideKeyboardOnAutofocus,
      validator:
          validator == null ? null : (value) => validator!(_valueToNum(value)),
      divider: divider,
    );
  }

  String? _numToString(num? value) {
    if (value?.floorToDouble() == value) {
      value = value?.toInt();
    }
    return value?.toString().replaceAll(RegExp(r'\.'), ',');
  }

  num? _valueToNum(String? value) {
    if (value == '' || value == null) {
      return null;
    } else {
      value = value.replaceAll(RegExp(r'\,'), '.');
      final numValue = num.tryParse(value);
      return numValue;
    }
  }
}
