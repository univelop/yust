import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_text_field.dart';
import 'package:yust/yust.dart';
import '../yust.dart';

typedef TapCallback = void Function();
typedef DeleteCallback = Future<void> Function();

class YustInputTile extends StatelessWidget {
  final String? label;
  final String? text;
  final TextStyle? textStyle;
  final Widget? prefixIcon;
  final YustInputStyle style;
  final TapCallback? onTap;
  final DeleteCallback? onDelete;
  final Widget? suffixChild;
  final FormFieldValidator<String>? validator;

  const YustInputTile({
    Key? key,
    this.label,
    this.text,
    this.textStyle,
    this.prefixIcon,
    this.style = YustInputStyle.normal,
    this.onTap,
    this.onDelete,
    this.suffixChild,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return YustTextField(
      label: label,
      value: text,
      textStyle: textStyle,
      style: style,
      readOnly: true,
      showSelected: false,
      prefixIcon: prefixIcon,
      suffixIcon: suffixChild,
      onTap: onTap,
      onDelete: onDelete == null
          ? null
          : () async {
              FocusScope.of(context).unfocus();
              await onDelete!();
            },
      validator: validator,
    );
  }
}
