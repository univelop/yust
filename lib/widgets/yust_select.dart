import 'package:flutter/material.dart';

class YustSelect<T> extends StatelessWidget {
  const YustSelect(
      {Key key,
      this.label,
      this.value,
      this.optionValues,
      this.optionLabels,
      this.onSelected})
      : super(key: key);

  final String label;
  final T value;
  final List<T> optionValues;
  final List<String> optionLabels;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(label ?? '', style: TextStyle(color: Colors.grey[600])),
          trailing: Text(_valueCaption(value)),
          onTap: () => _selectValue(context),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),
        Divider(height: 1.0, color: Colors.grey[800])
      ],
    );
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
              title: Text('$label wählen'),
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
        onSelected(selectedValue);
      }
    }
  }
}
