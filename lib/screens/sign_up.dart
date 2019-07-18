import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/yust_exception.dart';
import '../yust.dart';
import 'sign_in.dart';

class SignUpScreen extends StatefulWidget {
  
  static String routeName = 'signUp';

  final String homeRouteName;
  final String logoAssetName;

  SignUpScreen({Key key, this.homeRouteName = '/', this.logoAssetName}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  
  String _firstName;
  String _lastName;
  String _email;
  String _password;
  String _passwordConfirmation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrierung'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 40.0),
        children: <Widget>[
          _buildLogo(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Vorname',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _firstName = value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Nachname',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _lastName = value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'E-Mail',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _email = value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Passwort',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (value) => _password = value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Passwort bestätigen',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (value) => _passwordConfirmation = value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: RaisedButton(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              color: Theme.of(context).accentColor,
              onPressed: () async {
                try {
                  await Yust.service.signUp(_firstName, _lastName, _email, _password, _passwordConfirmation);
                  Navigator.pushReplacementNamed(context, widget.homeRouteName);
                } on YustException catch (err) {
                  Yust.service.showAlert(context, 'Fehler', err.message);
                } on PlatformException catch (err) {
                  Yust.service.showAlert(context, 'Fehler', err.message);
                }
              },
              child: Text('Registrieren', style: TextStyle(fontSize: 20.0, color: Colors.white)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 40.0, right: 20.0, bottom: 10.0),
            child: Text('Du hast bereits einen Account?', style: TextStyle(fontSize: 16.0)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: FlatButton(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Hier Anmelden', style: TextStyle(fontSize: 20.0, color: Theme.of(context).primaryColor)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    if (widget.logoAssetName == null) {
      return SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 50.0),
      child: Image.asset(widget.logoAssetName),
    );
  }

}