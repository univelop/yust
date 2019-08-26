import 'package:flutter/material.dart';

class YustSwitch extends StatelessWidget {
  const YustSwitch({Key key, this.label, this.value, this.onChanged})
      : super(key: key);

  final String label;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(label ?? '', style: TextStyle(color: Colors.grey[600])),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),
        Divider(height: 1.0, color: Colors.grey[800])
      ],
    );
  }
}
