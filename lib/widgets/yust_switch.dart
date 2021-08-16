import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_input_tile.dart';

import '../yust.dart';

class YustSwitch extends StatelessWidget {
  final String? label;
  final bool value;
  final Color? activeColor;
  final Widget? prefixIcon;
  final void Function(bool)? onChanged;
  final bool readOnly;
  //switchRepresentation could be: 'yesNo', 'checkbox', 'label',
  final String switchRepresentation;

  const YustSwitch({
    Key? key,
    this.label,
    required this.value,
    this.activeColor,
    this.prefixIcon,
    this.onChanged,
    this.readOnly = false,
    this.switchRepresentation = 'yesNo',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (switchRepresentation == 'checkbox') {
      return YustInputTile(
          child: Checkbox(
            checkColor: activeColor,
            value: value,
            onChanged: (bool? value) {
              Yust.service.unfocusCurrent(context);
              readOnly || value == null || onChanged == null
                  ? null
                  : onChanged!(value);
            },
          ),
          label: label,
          prefixIcon: prefixIcon);
    } else {
      return YustInputTile(
          child: Switch(
            value: value,
            activeColor: activeColor,
            onChanged: (value) {
              Yust.service.unfocusCurrent(context);
              readOnly || onChanged == null ? null : onChanged!(value);
            },
          ),
          label: label,
          prefixIcon: prefixIcon);
    }
  }
}
