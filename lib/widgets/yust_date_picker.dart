import 'package:flutter/material.dart';

import '../yust.dart';

typedef DateTimeCallback = void Function(DateTime?);

class YustDatePicker extends StatelessWidget {
  final String? label;
  final DateTime? value;
  final DateTime? initialValue;
  final DateTimeCallback? onChanged;
  final bool hideClearButton;
  final YustInputStyle style;
  final Widget? prefixIcon;
  final bool readOnly;

  YustDatePicker({
    Key? key,
    this.label,
    this.value,
    this.initialValue,
    this.onChanged,
    this.hideClearButton = false,
    this.style = YustInputStyle.normal,
    this.prefixIcon,
    this.readOnly = false,
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
      if (label != null && prefixIcon != null) {
        padding = EdgeInsets.only(
            left: 8.0,
            top: 8.0,
            right: hideClearButton ? 16.0 : 8.0,
            bottom: 8.0);
      } else {
        padding = EdgeInsets.only(
            left: 16.0,
            top: 8.0,
            right: hideClearButton ? 16.0 : 8.0,
            bottom: 8.0);
      }
    } else {
      padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0);
    }
    if (label == null) {
      return ListTile(
        title: Text(dateText),
        trailing: _buildClearDate(context),
        onTap:
            (onChanged == null || readOnly) ? null : () => _pickDate(context),
        contentPadding: padding,
      );
    } else {
      return ListTile(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefixIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: prefixIcon,
              ),
            Flexible(
              child: Text(
                label ?? '',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(dateText),
            _buildClearDate(context),
          ],
        ),
        onTap:
            (onChanged == null || readOnly) ? null : () => _pickDate(context),
        contentPadding: padding,
      );
    }
  }

  Widget _buildClearDate(BuildContext context) {
    if (value == null || hideClearButton || readOnly) {
      return SizedBox.shrink();
    }
    return IconButton(
      icon: Icon(Icons.clear),
      onPressed: onChanged == null ? null : () => onChanged!(null),
    );
  }

  void _pickDate(BuildContext context) async {
    Yust.service.unfocusCurrent(context);
    var dateTime = value ?? initialValue;
    if (dateTime == null) {
      final now = DateTime.now();
      dateTime = DateTime(now.year, now.month, now.day, 0, 0, 0, 0, 0);
    }
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: dateTime,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: Locale('de', 'DE'),
    );
    if (selectedDate != null) {
      dateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond,
          dateTime.microsecond);
      onChanged!(dateTime);
    }
  }
}
