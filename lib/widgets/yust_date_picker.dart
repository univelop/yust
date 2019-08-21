import 'package:flutter/material.dart';

import '../yust.dart';

typedef StringCallback = void Function(String);

class YustDatePicker extends StatefulWidget {
  YustDatePicker({Key key, this.label, this.value = '', this.onChanged})
      : super(key: key);

  final String label;
  final String value;
  final StringCallback onChanged;

  @override
  _YustDatePickerState createState() => _YustDatePickerState();
}

class _YustDatePickerState extends State<YustDatePicker> {
  String _date;

  @override
  void initState() {
    super.initState();

    _date = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _date != null ? Yust.service.formatDate(_date) : '';
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(widget.label, style: TextStyle(color: Colors.grey[600])),
          trailing: Text(dateText),
          onTap: () => _pickDate(context),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),
        Divider(height: 1.0, color: Colors.grey[800]),
      ],
    );
  }

  void _pickDate(BuildContext context) async {
    final initDate = _date != null ? DateTime.parse(_date) : DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: DateTime(2018),
      lastDate: DateTime(2030),
      locale: Locale('de', 'DE'),
    );
    if (selectedDate != null) {
      setState(() {
        _date = selectedDate.toIso8601String();
      });
      widget.onChanged(_date);
    }
  }
}
