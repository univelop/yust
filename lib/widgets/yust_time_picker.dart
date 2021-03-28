import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_date_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../yust.dart';

class YustTimePicker extends StatelessWidget {
  FocusNode _focusNode = FocusNode();

  final String label;
  final DateTime value;
  final DateTime initialValue;
  final DateTimeCallback onChanged;
  final bool hideClearButton;
  final YustInputStyle style;
  final Widget prefixIcon;
  final MaskTextInputFormatter maskFormatter;

  YustTimePicker({
    Key key,
    this.label,
    this.value,
    this.initialValue,
    this.onChanged,
    this.hideClearButton = false,
    this.style = YustInputStyle.normal,
    this.prefixIcon,
  })  : maskFormatter = MaskTextInputFormatter(
            mask: 'H#:M#',
            filter: {
              '#': RegExp(r'[0-9]'),
              'H': RegExp(r'[0-2]'),
              'M': RegExp(r'[0-5]')
            },
            initialText: Yust.service.formatTime(value)),
        super(key: key) {
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _setTimeString();
      }
    });
  }

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
        trailing: _buildTrailing(context),
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
            Expanded(child: _buildFormatTextField(timeText)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildTrailing(context),
          ],
        ),
        contentPadding: padding,
      );
    }
  }

  Widget _buildFormatTextField(timeText) {
    var textEditingController = TextEditingController(text: timeText);
    return TextField(
        keyboardType: TextInputType.number,
        focusNode: _focusNode,
        controller: textEditingController,
        inputFormatters: [maskFormatter],
        textAlign: TextAlign.center,
        decoration: InputDecoration(border: InputBorder.none),
        onEditingComplete: () => _setTimeString());
  }

  void _setTimeString() {
    var time = int.tryParse(maskFormatter.getUnmaskedText().padRight(4, '0'));
    if (time == 2400) {
      time == 0;
    }
    var hour = time ~/ 100 >= 24 ? 0 : time ~/ 100;
    var minute = time % 100 >= 60 ? 0 : time % 100;
    var dateTime = DateTime(1970, 1, 1, hour, minute, 0, 0, 0);
    onChanged(dateTime);
  }

  /// build the clock- / x-icon
  Widget _buildTrailing(BuildContext context) {
    if (value == null) {
      return IconButton(
        icon: Icon(Icons.access_time),
        onPressed: onChanged == null ? null : () => _pickTime(context),
      );
    } else {
      if (hideClearButton) {
        return SizedBox.shrink();
      }
      return IconButton(
        icon: Icon(Icons.clear),
        onPressed: onChanged == null ? null : () => onChanged(null),
      );
    }
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
