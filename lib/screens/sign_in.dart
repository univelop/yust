import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yust/screens/reset_password.dart';
import 'package:yust/widgets/yust_focus_handler.dart';
import 'package:yust/widgets/yust_progress_button.dart';

import '../util/yust_exception.dart';
import '../yust.dart';
import '../yust_store.dart';
import 'sign_up.dart';

class SignInScreen extends StatefulWidget {
  static const String routeName = '/signIn';
  static const bool signInRequired = false;

  final String logoAssetName;
  @Deprecated('Use onSignedIn instead')
  final String targetRouteName;
  @Deprecated('Use onSignedIn instead')
  final dynamic targetRouteArguments;

  SignInScreen({
    Key key,
    this.logoAssetName,
    this.targetRouteName,
    this.targetRouteArguments,
  }) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String _email;
  String _password;
  bool _waitingForSignIn = false;
  void Function() _onSignedIn;

  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  void Function() _storeListener;

  @override
  void initState() {
    SharedPreferences.getInstance().then((prefs) {
      _email = prefs.getString('email') ?? null;
      _emailController.text = _email;
    });

    _storeListener = () {
      if (Yust.store.authState == AuthState.signedIn) {
        Yust.store.removeListener(_storeListener);
        Navigator.pushNamedAndRemoveUntil(
          context,
          widget.targetRouteName ?? '/',
          (_) => false,
          arguments: widget.targetRouteArguments,
        );
      }
    };
    Yust.store.addListener(_storeListener);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context).settings.arguments;
    if (arguments is Map) {
      _onSignedIn = arguments['onSignedIn'];
    }

    return YustFocusHandler(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Anmeldung'),
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
                          style:
                              TextStyle(fontSize: 20.0, color: Colors.white)),
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
                        Navigator.pushNamed(context, SignUpScreen.routeName,
                            arguments: arguments);
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
                        Navigator.pushNamed(
                            context, ResetPasswordScreen.routeName);
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

  Future<void> _signIn(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('email', _email);
    try {
      await Yust.service
          .signIn(context, _email, _password)
          .timeout(Duration(seconds: 10));
      if (_onSignedIn != null) _onSignedIn();
      Navigator.popUntil(
        context,
        (route) => ![SignUpScreen.routeName, SignInScreen.routeName]
            .contains(route.settings.name),
      );
    } on YustException catch (err) {
      Yust.service.showAlert(context, 'Fehler', err.message);
    } on PlatformException catch (err) {
      Yust.service.showAlert(context, 'Fehler', err.message);
    } on TimeoutException catch (_) {
      Yust.service.showAlert(
        context,
        'Fehler',
        'Zeitüberschreitung der Anfrage',
      );
    } catch (err) {
      Yust.service.showAlert(context, 'Fehler', err.toString());
    }
  }
}
