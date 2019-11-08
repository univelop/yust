import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yust/screens/reset_password.dart';
import 'package:yust/widgets/yust_progress_button.dart';
import 'package:yust/yust_store.dart';

import '../models/yust_exception.dart';
import '../yust.dart';
import 'sign_up.dart';

class SignInScreen extends StatefulWidget {
  static const String routeName = 'signIn';

  final String logoAssetName;
  final String targetRouteName;
  final dynamic targetRouteArguments;

  SignInScreen(
      {Key key,
      this.logoAssetName,
      this.targetRouteName,
      this.targetRouteArguments})
      : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String _email;
  String _password;
  bool _waitingForSignIn = false;

  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    SharedPreferences.getInstance().then((prefs) {
      _email = prefs.getString('email') ?? null;
      _emailController.text = _email;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anmeldung'),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.only(top: 40.0),
            children: <Widget>[
              _buildLogo(context),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-Mail',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  focusNode: _emailFocus,
                  onChanged: (value) => _email = value.trim(),
                  onSubmitted: (value) {
                    _emailFocus.unfocus();
                    FocusScope.of(context).requestFocus(_passwordFocus);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Passwort',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.send,
                  focusNode: _passwordFocus,
                  onChanged: (value) => _password = value.trim(),
                  onSubmitted: (value) async {
                    _passwordFocus.unfocus();
                    setState(() {
                      _waitingForSignIn = true;
                    });
                    await _signIn(context);
                    setState(() {
                      _waitingForSignIn = false;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: YustProgressButton(
                  color: Theme.of(context).accentColor,
                  inProgress: _waitingForSignIn,
                  onPressed: () => _signIn(context),
                  child: Text('Anmelden',
                      style: TextStyle(fontSize: 20.0, color: Colors.white)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, top: 40.0, right: 20.0, bottom: 10.0),
                child: Text('Du hast noch keinen Account?',
                    style: TextStyle(fontSize: 16.0)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: FlatButton(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  onPressed: () {
                    Navigator.pushNamed(context, SignUpScreen.routeName);
                  },
                  child: Text('Hier Registrieren',
                      style: TextStyle(
                          fontSize: 20.0,
                          color: Theme.of(context).primaryColor)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: FlatButton(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  onPressed: () {
                    Navigator.pushNamed(context, ResetPasswordScreen.routeName);
                  },
                  child: Text('Passwort vergessen',
                      style: TextStyle(
                          fontSize: 20.0,
                          color: Theme.of(context).primaryColor)),
                ),
              ),
            ],
          ),
        ),
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

  Future<void> _signIn(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('email', _email);
    try {
      await Yust.service.signIn(_email, _password);
      if (this.widget.targetRouteName != null) {
        Navigator.pushReplacementNamed(context, this.widget.targetRouteName,
            arguments: this.widget.targetRouteArguments);
      }
    } on YustException catch (err) {
      Yust.service.showAlert(context, 'Fehler', err.message);
    } on PlatformException catch (err) {
      Yust.service.showAlert(context, 'Fehler', err.message);
    } catch (err) {
      Yust.service.showAlert(context, 'Fehler', err.toString());
    }
  }
}
