import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_input_tile.dart';

class YustSwitch extends StatelessWidget {
  final String? label;
  final bool value;
  final Color? activeColor;
  final Widget? prefixIcon;
  final void Function(bool)? onChanged;

  const YustSwitch({
    Key? key,
    this.label,
    required this.value,
    this.activeColor,
    this.prefixIcon,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return YustInputTile(
        child: Switch(
          value: value,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
        label: label,
        prefixIcon: prefixIcon);
  }
}
