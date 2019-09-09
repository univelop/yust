import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yust/widgets/yust_progress_button.dart';

import '../models/yust_exception.dart';
import '../yust.dart';
import 'sign_up.dart';

class SignInScreen extends StatefulWidget {
  static String routeName = 'signIn';

  final String logoAssetName;

  SignInScreen({Key key, this.logoAssetName}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String _email;
  String _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anmeldung'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 40.0),
        children: <Widget>[
          _buildLogo(context),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'E-Mail',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _email = value,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: YustProgressButton(
              color: Theme.of(context).accentColor,
              onPressed: () async {
                try {
                  await Yust.service.signIn(_email, _password);
                } on YustException catch (err) {
                  Yust.service.showAlert(context, 'Fehler', err.message);
                } on PlatformException catch (err) {
                  Yust.service.showAlert(context, 'Fehler', err.message);
                } catch (err) {
                  Yust.service.showAlert(context, 'Fehler', err.toString());
                }
              },
              child: Text('Anmelden', style: TextStyle(fontSize: 20.0, color: Colors.white)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 20.0, top: 40.0, right: 20.0, bottom: 10.0),
            child: Text('Du hast noch keinen Account?',
                style: TextStyle(fontSize: 16.0)),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: FlatButton(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              onPressed: () {
                Navigator.pushNamed(context, SignUpScreen.routeName);
              },
              child: Text('Hier Registrieren',
                  style: TextStyle(
                      fontSize: 20.0, color: Theme.of(context).primaryColor)),
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
