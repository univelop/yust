import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_date_picker.dart';

import '../yust.dart';

class YustTimePicker extends StatelessWidget {
  final String label;
  final DateTime value;
  final DateTime initialValue;
  final DateTimeCallback onChanged;
  final bool hideClearButton;
  final YustInputStyle style;
  final Widget prefixIcon;

  YustTimePicker({
    Key key,
    this.label,
    this.value,
    this.initialValue,
    this.onChanged,
    this.hideClearButton = false,
    this.style = YustInputStyle.normal,
    this.prefixIcon,
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
    final timeText = Yust.service.formatTime(value);
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
        title: Text(timeText),
        trailing: _buildClearTime(context),
        onTap: onChanged == null ? null : () => _pickTime(context),
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
            Text(timeText),
            _buildClearTime(context),
          ],
        ),
        onTap: onChanged == null ? null : () => _pickTime(context),
        contentPadding: padding,
      );
    }
  }

  Widget _buildClearTime(BuildContext context) {
    if (value == null || hideClearButton) {
      return SizedBox.shrink();
    }
    return IconButton(
      icon: Icon(Icons.clear),
      onPressed: onChanged == null ? null : () => onChanged(null),
    );
  }

  void _pickTime(BuildContext context) async {
    var dateTime = value ?? initialValue;
    if (dateTime == null) {
      final now = DateTime.now();
      dateTime = DateTime(1970, 1, 1, now.hour, now.minute, 0, 0, 0);
    }
    final initialTime = TimeOfDay.fromDateTime(dateTime);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      cancelText: 'Abbrechen',
      confirmText: 'OK',
      helpText: 'Uhrzeit wählen',
    );
    if (selectedTime != null) {
      dateTime = DateTime(dateTime.year, dateTime.month, dateTime.day,
          selectedTime.hour, selectedTime.minute, 0, 0, 0);
      onChanged(dateTime);
    }
  }
}
