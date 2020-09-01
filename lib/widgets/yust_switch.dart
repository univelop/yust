import 'package:flutter/material.dart';

class YustSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final Color activeColor;
  final Widget prefixIcon;
  final void Function(bool) onChanged;

  const YustSwitch({
    Key key,
    this.label,
    this.value,
    this.activeColor,
    this.prefixIcon,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: prefixIcon,
                ),
              Text(label ?? '', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          trailing: Switch(
            value: value,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
          contentPadding: prefixIcon != null
              ? const EdgeInsets.only(
                  left: 8.0, top: 8.0, right: 16.0, bottom: 8.0)
              : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),
        Divider(height: 1.0, thickness: 1.0, color: Colors.grey)
      ],
    );
  }
}
