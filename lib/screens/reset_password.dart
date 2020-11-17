import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yust/widgets/yust_focus_handler.dart';
import 'package:yust/widgets/yust_progress_button.dart';

import '../util/yust_exception.dart';
import '../yust.dart';

class ResetPasswordScreen extends StatefulWidget {
  static const String routeName = '/resetPassword';
  static const bool signInRequired = false;

  final String logoAssetName;

  ResetPasswordScreen({Key key, this.logoAssetName}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  String _email;

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
              child: Column(
                children: <Widget>[
                  _buildLogo(context),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'E-Mail',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _email = value.trim(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: YustProgressButton(
                      color: Theme.of(context).accentColor,
                      onPressed: () async {
                        try {
                          await Yust.service.sendPasswordResetEmail(_email);
                          Navigator.pop(context);
                          Yust.service.showAlert(context, 'E-Mail verschickt',
                              'Du erhälst eine E-Mail. Folge den Anweisungen um ein neues Passwort zu erstellen.');
                        } catch (err) {
                          Yust.service.showAlert(context, 'Fehler',
                              err.message ?? 'Unbekannter Fehler');
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
    );
  }

  Widget _buildLogo(BuildContext context) {
    if (widget.logoAssetName == null) {
      return SizedBox.shrink();
    }
    return SizedBox(
      height: 200,
      child: Center(
        child: Image.asset(widget.logoAssetName),
      ),
    );
  }
}
