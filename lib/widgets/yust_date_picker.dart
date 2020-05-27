import 'package:flutter/material.dart';

import '../yust.dart';

typedef DateTimeCallback = void Function(DateTime);

class YustDatePicker extends StatelessWidget {
  final String label;
  final DateTime value;
  final DateTimeCallback onChanged;
  final bool hideClearButton;
  final YustInputStyle style;

  YustDatePicker({
    Key key,
    this.label,
    this.value,
    this.onChanged,
    this.hideClearButton = false,
    this.style = YustInputStyle.normal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (style == YustInputStyle.normal) {
      return Column(
        children: <Widget>[
          _buildInner(context),
          Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
        ],
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: _buildInner(context),
      );
    }
  }

  Widget _buildInner(BuildContext context) {
    final dateText = Yust.service.formatDate(value);
    var padding;
    if (style == YustInputStyle.normal) {
      padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    } else {
      padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0);
    }
    if (label == null) {
      return ListTile(
        title: Text(dateText),
        trailing: _buildClearDate(context),
        onTap: () => _pickDate(context),
        contentPadding: padding,
      );
    } else {
      return ListTile(
        title: Text(label, style: TextStyle(color: Colors.grey[600])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(dateText),
            _buildClearDate(context),
          ],
        ),
        onTap: () => _pickDate(context),
        contentPadding: padding,
      );
    }
  }

  Widget _buildClearDate(BuildContext context) {
    if (value == null || hideClearButton) {
      return SizedBox.shrink();
    }
    return IconButton(
      icon: Icon(Icons.clear),
      onPressed: () {
        onChanged(null);
      },
    );
  }

  void _pickDate(BuildContext context) async {
    final initDate = value ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: DateTime(2018),
      lastDate: DateTime(2030),
      locale: Locale('de', 'DE'),
    );
    if (selectedDate != null) {
      onChanged(selectedDate);
    }
  }
}
