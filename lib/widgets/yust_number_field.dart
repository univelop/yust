import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:yust/widgets/yust_text_field.dart';
import 'package:yust/yust.dart';

typedef ChangeCallback = void Function(num?);
typedef TapCallback = void Function();

class YustNumberField extends StatelessWidget {
  final String? label;
  final num? value;
  final int? decimalCount;
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
    this.decimalCount,
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
      value: numToString(value, decimalCount),
      controller: controller,
      onChanged: onChanged == null
          ? null
          : (value) {
              var numValue = valueToNum(value?.trim() ?? '');
              onChanged!(numValue);
            },
      onEditingComplete: onEditingComplete == null
          ? null
          : (value) => onEditingComplete!(valueToNum(value?.trim() ?? '')),
      keyboardType: kIsWeb
          ? null
          : TextInputType.numberWithOptions(decimal: true, signed: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9\,\-]'))],
      textInputAction: TextInputAction.next,
      onTap: onTap,
      readOnly: readOnly,
      enabled: enabled,
      autovalidateMode:
          validator != null ? AutovalidateMode.onUserInteraction : null,
      autofocus: autofocus,
      hideKeyboardOnAutofocus: hideKeyboardOnAutofocus,
      validator:
          validator == null ? null : (value) => validator!(valueToNum(value)),
      divider: divider,
    );
  }

  static String? numToString(num? value, [int? decimalCount]) {
    if (value?.floorToDouble() == value) {
      value = value?.toInt();
    }
    final format = NumberFormat(
        decimalCount != null
            ? ('0' + (decimalCount == 0 ? '' : '.') + ('0' * decimalCount))
            : null,
        'de-DE');
    return value != null ? format.format(value) : null;
  }

  static num? valueToNum(String? value) {
    if (value == '' || value == null) {
      return null;
    } else {
      value = value.replaceAll(RegExp(r'\.'), '');
      value = value.replaceAll(RegExp(r'\,'), '.');
      final numValue = num.tryParse(value);
      return numValue;
    }
  }
}
