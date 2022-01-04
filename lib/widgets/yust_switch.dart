import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_list_tile.dart';

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
      return YustListTile(
          label: label,
          suffixChild: Checkbox(
            checkColor: activeColor,
            value: value,
            onChanged: (bool? value) {
              Yust.helperService.unfocusCurrent(context);
              readOnly || value == null || onChanged == null
                  ? null
                  : onChanged!(value);
            },
          ),
          onTap: readOnly || onChanged == null
              ? null
              : () {
                  Yust.helperService.unfocusCurrent(context);
                  onChanged!(!value);
                },
          prefixIcon: prefixIcon);
    } else {
      return YustListTile(
          label: label,
          suffixChild: Switch(
            value: value,
            activeColor: activeColor ?? Theme.of(context).primaryColor,
            onChanged: (value) {
              Yust.helperService.unfocusCurrent(context);
              readOnly || onChanged == null ? null : onChanged!(value);
            },
          ),
          onTap: readOnly || onChanged == null
              ? null
              : () {
                  Yust.helperService.unfocusCurrent(context);
                  onChanged!(!value);
                },
          prefixIcon: prefixIcon);
    }
  }
}
