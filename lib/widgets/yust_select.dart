import 'package:flutter/material.dart';
import 'package:yust/yust.dart';

class YustSelect<T> extends StatelessWidget {
  final String? label;
  final T value;
  final List<T> optionValues;
  final List<String> optionLabels;
  final void Function(T)? onSelected;
  final YustInputStyle style;
  final Widget? prefixIcon;
  final bool readOnly;

  const YustSelect({
    Key? key,
    this.label,
    required this.value,
    required this.optionValues,
    required this.optionLabels,
    this.onSelected,
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
    var padding;
    if (style == YustInputStyle.normal) {
      if (label != null && prefixIcon != null) {
        padding = const EdgeInsets.only(
            left: 8.0, top: 8.0, right: 16.0, bottom: 8.0);
      } else {
        padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
      }
    } else {
      padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0);
    }
    if (label == null) {
      return ListTile(
        title: Text(_valueCaption(value)),
        onTap: (onSelected == null || readOnly)
            ? null
            : () => _selectValue(context),
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
        trailing: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 150),
          child: Text(_valueCaption(value)),
        ),
        onTap: (onSelected == null || readOnly)
            ? null
            : () => _selectValue(context),
        contentPadding: padding,
      );
    }
  }

  String _valueCaption(T value) {
    final index = optionValues.indexOf(value);
    if (index == -1) {
      return '';
    }
    return optionLabels[index];
  }

  void _selectValue(BuildContext context) async {
    Yust.service.unfocusCurrent(context);
    if (onSelected != null) {
      var selectedValue = await showDialog<T>(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: (label == null) ? null : Text('$label wählen'),
              children: optionValues.map((optionValue) {
                return SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, optionValue);
                  },
                  child: Text(_valueCaption(optionValue)),
                );
              }).toList(),
            );
          });
      if (selectedValue != null) {
        onSelected!(selectedValue);
      }
    }
  }
}
