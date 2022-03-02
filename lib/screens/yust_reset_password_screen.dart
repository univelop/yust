import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_focus_handler.dart';
import 'package:yust/widgets/yust_progress_button.dart';

import '../yust.dart';

class YustResetPasswordScreen extends StatefulWidget {
  static const String routeName = '/resetPassword';
  static const bool signInRequired = false;

  final String? logoAssetName;

  YustResetPasswordScreen({Key? key, this.logoAssetName}) : super(key: key);

  @override
  _YustResetPasswordScreenState createState() =>
      _YustResetPasswordScreenState();
}

class _YustResetPasswordScreenState extends State<YustResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _email;

  @override
  Widget build(BuildContext context) {
    return YustFocusHandler(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Passwort vergessen'),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.only(top: 40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    _buildLogo(context),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'E-Mail',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value == '') {
                            return 'Die E-Mail darf nicht leer sein.';
                          }
                          return null;
                        },
                        onChanged: (value) => _email = value.trim(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: YustProgressButton(
                        color: Theme.of(context).colorScheme.secondary,
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              await Yust.authService
                                  .sendPasswordResetEmail(_email!);
                              Navigator.pop(context);
                              await Yust.alertService.showAlert(
                                  context,
                                  'E-Mail verschickt',
                                  'Du erhälst eine E-Mail. Folge den Anweisungen um ein neues Passwort zu erstellen.');
                            } catch (err) {
                              await Yust.alertService
                                  .showAlert(context, 'Fehler', err.toString());
                            }
                          }
                        },
                        child: Text('Passwort vergessen',
                            style:
                                TextStyle(fontSize: 20.0, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    if (widget.logoAssetName == null) {
      return SizedBox.shrink();
    }
    return SizedBox(
      height: 200,
      child: Center(
        child: Image.asset(widget.logoAssetName!),
      ),
    );
  }
}
