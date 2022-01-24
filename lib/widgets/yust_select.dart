import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_input_tile.dart';
import 'package:yust/yust.dart';

typedef DeleteCallback = Future<void> Function();

class YustSelect<T> extends StatelessWidget {
  final String? label;
  final T value;
  final List<T> optionValues;
  final List<String> optionLabels;
  final void Function(T)? onSelected;
  final DeleteCallback? onDelete;
  final YustInputStyle style;
  final Widget? prefixIcon;
  final Widget? suffixChild;
  final bool readOnly;

  const YustSelect({
    Key? key,
    this.label,
    required this.value,
    required this.optionValues,
    required this.optionLabels,
    this.onSelected,
    this.onDelete,
    this.style = YustInputStyle.normal,
    this.prefixIcon,
    this.suffixChild,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return YustInputTile(
      label: label ?? '',
      text: _valueCaption(value),
      prefixIcon: prefixIcon,
      suffixChild: suffixChild,
      style: style,
      onTap:
          (onSelected == null || readOnly) ? null : () => _selectValue(context),
      onDelete: onDelete,
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
    Yust.helperService.unfocusCurrent(context);
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
