import 'package:flutter/material.dart';
import 'package:yust/yust.dart';

class YustSelect<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> optionValues;
  final List<String> optionLabels;
  final void Function(T) onSelected;
  final YustInputStyle style;

  const YustSelect({
    Key key,
    this.label,
    this.value,
    this.optionValues,
    this.optionLabels,
    this.onSelected,
    this.style = YustInputStyle.normal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (style == YustInputStyle.normal) {
      return Column(
        children: <Widget>[
          _buildInner(context),
          Divider(height: 1.0, color: Colors.grey[800]),
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
      padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    } else {
      padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0);
    }
    if (label == null) {
      return ListTile(
        title: Text(_valueCaption(value)),
        onTap: () => _selectValue(context),
        contentPadding: padding,
      );
    } else {
      return ListTile(
        title: Text(label ?? '', style: TextStyle(color: Colors.grey[600])),
        trailing: Text(_valueCaption(value)),
        onTap: () => _selectValue(context),
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
                  child: Text(_valueCaption(optionValue) ?? ''),
                );
              }).toList(),
            );
          });
      if (selectedValue != null) {
        onSelected(selectedValue);
      }
    }
  }
}
