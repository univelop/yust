import 'package:flutter/material.dart';

class YustSelect<T> extends StatelessWidget {
  const YustSelect({Key key, this.label, this.value, this.optionValues, this.optionCaptions, this.onSelected}) : super(key: key);

  final String label;
  final T value;
  final List<T> optionValues;
  final List<String> optionCaptions;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: ListTile(
            title: Text(label ?? ''),
            trailing: Text(_valueCaption(value)),
            onTap: () => _selectValue(context),
          ),
        ),
        Divider()
      ],
    );
  }

  String _valueCaption(T value) {
    final index = optionValues.indexOf(value);
    if (index == -1) {
      return '';
    }
    return optionCaptions[index];
  }

  void _selectValue(BuildContext context) async {
    var selectedValue = await showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        // subjects.insert(0, 
        //   Subject()
        //   ..id = '_null'
        //   ..shortName = 'Kein Fach');
        return SimpleDialog(
          title: Text('$label wählen'),
          children: optionValues.map((optionValue) {
            return SimpleDialogOption(
              onPressed: () { Navigator.pop(context, optionValue); },
              child: Text(_valueCaption(optionValue)),
            );
          }).toList()
        );
      }
    );
    if (selectedValue != null) {
      onSelected(selectedValue);
    }
  }
}