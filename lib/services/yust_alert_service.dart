import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_select.dart';

class YustAlertService {
  final _yustServiceValidationKey = GlobalKey<FormState>();

  Future<void> showAlert(
      BuildContext context, String title, String message) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> showConfirmation(
    BuildContext context,
    String title,
    String action, [
    String? description,
  ]) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: description != null ? Text(description) : null,
          actions: <Widget>[
            TextButton(
              child: Text("Abbrechen"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(action),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> showTextFieldDialog(
    BuildContext context,
    String title,
    String? placeholder,
    String action, {
    String initialText = '',

    /// if validator is set, action gets only triggerd if the validator returns null (means true)
    FormFieldValidator<String>? validator,
  }) {
    final controller = TextEditingController(text: initialText);
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Form(
          key: _yustServiceValidationKey,
          child: AlertDialog(
            title: Text(title),
            content: TextFormField(
              controller: controller,
              decoration: InputDecoration(hintText: placeholder),
              autovalidateMode:
                  validator == null ? null : AutovalidateMode.onUserInteraction,
              validator: validator == null
                  ? null
                  : (value) => validator(value!.trim()),
              autofocus: true,
            ),
            actions: <Widget>[
              TextButton(
                child: Text("Abbrechen"),
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
              ),
              TextButton(
                child: Text(action),
                onPressed: () {
                  if (validator == null) {
                    Navigator.of(context).pop(controller.text);
                  } else if (_yustServiceValidationKey.currentState!
                      .validate()) {
                    //if ( validator(controller.text.trim()) == null
                    Navigator.of(context).pop(controller.text);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> showPickerDialog(
    BuildContext context,
    String title,
    String action, {
    required List<String> optionLabels,
    required List<String> optionValues,
    String initialText = '',
  }) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        var selected = '';
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: 100,
                child: YustSelect(
                  value: selected,
                  optionLabels: optionLabels,
                  optionValues: optionValues,
                  onSelected: (value) =>
                      {setState(() => selected = value as String)},
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Abbrechen"),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: Text(action),
              onPressed: () {
                Navigator.of(context).pop(selected);
              },
            ),
          ],
        );
      },
    );
  }

  void showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
