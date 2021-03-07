import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_input_tile.dart';

class YustButtonTile extends StatelessWidget {
  final String label;
  final String buttonText;
  final Color activeColor;
  final Widget prefixIcon;
  final void Function() onPressed;

  const YustButtonTile(
      {Key key,
      this.label,
      this.activeColor,
      this.prefixIcon,
      this.onPressed,
      this.buttonText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return YustInputTile(
        child: TextButton(onPressed: onPressed, child: Text(buttonText)),
        label: label,
        prefixIcon: prefixIcon,
        key: key);
  }
}
