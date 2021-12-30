import 'package:flutter/material.dart';

class YustButtonTile extends StatelessWidget {
  final String? label;
  final Color? color;
  final Color? textColor;
  final Widget? icon;
  final void Function()? onPressed;
  final Widget? above;
  final Widget? below;
  final bool elevated;
  final bool divider;

  const YustButtonTile({
    Key? key,
    this.label = '',
    this.color,
    this.textColor = Colors.white,
    this.icon,
    this.onPressed,
    this.above,
    this.below,
    this.elevated = true,
    this.divider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        above ?? SizedBox(),
        Padding(
          padding: const EdgeInsets.all(10),
          child: elevated
              ? ElevatedButton.icon(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    primary: color,
                    onPrimary: textColor,
                  ),
                  icon: icon ?? SizedBox(),
                  label: Text(
                    label!,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : TextButton.icon(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    primary: color,
                  ),
                  icon: icon ?? SizedBox(),
                  label: Text(
                    label!,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),
        below ?? SizedBox(),
        if (divider) Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
      ],
    );
  }
}
