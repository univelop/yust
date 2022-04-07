import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yust/models/yust_user.dart';
import 'package:yust/screens/yust_sign_in_screen.dart';
import 'package:yust/widgets/yust_focus_handler.dart';
import 'package:yust/widgets/yust_progress_button.dart';
import 'package:yust/widgets/yust_select.dart';

import '../util/yust_exception.dart';
import '../yust.dart';

class YustSignUpScreen extends StatefulWidget {
  static const String routeName = '/signUp';
  static const bool signInRequired = false;

  final String homeRouteName;
  final String? logoAssetName;
  final bool askForGender;

  YustSignUpScreen({
    Key? key,
    this.homeRouteName = '/',
    this.logoAssetName,
    this.askForGender = false,
  }) : super(key: key);

  @override
  _YustSignUpScreenState createState() => _YustSignUpScreenState();
}

class _YustSignUpScreenState extends State<YustSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  YustGender? _gender;
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _password;
  String? _passwordConfirmation;
  bool _waitingForSignUp = false;
  void Function()? _onSignedIn;

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _passwordConfirmationFocus = FocusNode();

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)!.settings.arguments;
    if (arguments is Map) {
      _onSignedIn = arguments['onSignedIn'];
    }

    return YustFocusHandler(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Registrierung'),
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.only(top: 40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    _buildLogo(context),
                    _buildGender(context),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Vorname',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        focusNode: _firstNameFocus,
                        onChanged: (value) => _firstName = value.trim(),
                        validator: (value) {
                          if (value == null || value == '') {
                            return 'Der Vorname darf nicht leer sein.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) {
                          _firstNameFocus.unfocus();
                          FocusScope.of(context).requestFocus(_lastNameFocus);
                          _scrollController.animateTo(
                              _scrollController.offset + 80,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.ease);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Nachname',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        focusNode: _lastNameFocus,
                        onChanged: (value) => _lastName = value.trim(),
                        validator: (value) {
                          if (value == null || value == '') {
                            return 'Der Nachname darf nicht leer sein.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) {
                          _firstNameFocus.unfocus();
                          FocusScope.of(context).requestFocus(_emailFocus);
                          _scrollController.animateTo(
                              _scrollController.offset + 80,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.ease);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'E-Mail',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        focusNode: _emailFocus,
                        onChanged: (value) => _email = value.trim(),
                        validator: (value) {
                          if (value == null || value == '') {
                            return 'Die E-Mail darf nicht leer sein.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) {
                          _emailFocus.unfocus();
                          FocusScope.of(context).requestFocus(_passwordFocus);
                          _scrollController.animateTo(
                              _scrollController.offset + 80,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.ease);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Passwort',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        focusNode: _passwordFocus,
                        onChanged: (value) => _password = value.trim(),
                        validator: (value) {
                          if (value == null || value == '') {
                            return 'Das Passwort darf nicht leer sein.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) async {
                          _passwordFocus.unfocus();
                          FocusScope.of(context)
                              .requestFocus(_passwordConfirmationFocus);
                          await _scrollController.animateTo(
                              _scrollController.offset + 80,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.ease);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Passwort bestätigen',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.send,
                        focusNode: _passwordConfirmationFocus,
                        onChanged: (value) =>
                            _passwordConfirmation = value.trim(),
                        validator: (value) {
                          if (value == null || value == '') {
                            return 'Die Passwortbestätigung darf nicht leer sein.';
                          }
                          if (_password != value) {
                            return 'Die Passwörter stimmen nicht überein.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) async {
                          _passwordConfirmationFocus.unfocus();
                          setState(() {
                            _waitingForSignUp = true;
                          });
                          await _signUp(context);
                          setState(() {
                            _waitingForSignUp = false;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: YustProgressButton(
                        color: Theme.of(context).colorScheme.secondary,
                        inProgress: _waitingForSignUp,
                        onPressed: () => _signUp(context),
                        child: Text('Registrieren',
                            style:
                                TextStyle(fontSize: 20.0, color: Colors.white)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20.0, top: 40.0, right: 20.0, bottom: 10.0),
                      child: Text('Du hast bereits einen Account?',
                          style: TextStyle(fontSize: 16.0)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 10.0),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, YustSignInScreen.routeName,
                              arguments: arguments);
                        },
                        child: Text('Hier Anmelden',
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

  Widget _buildGender(BuildContext context) {
    if (!widget.askForGender) {
      return SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: YustSelect(
        label: 'Anrede',
        value: _gender,
        optionValues: [YustGender.male, YustGender.female],
        optionLabels: ['Herr', 'Frau'],
        onSelected: (dynamic value) {
          setState(() {
            _gender = value;
          });
        },
        style: YustInputStyle.outlineBorder,
      ),
    );
  }

  Future<void> _signUp(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        await Yust.authService
            .signUp(
              context,
              _firstName!,
              _lastName!,
              _email!,
              _password!,
              _passwordConfirmation!,
              gender: _gender,
            )
            .timeout(Duration(seconds: 10));
        if (_onSignedIn != null) _onSignedIn!();
      } on YustException catch (err) {
        await Yust.alertService.showAlert(context, 'Fehler', err.message);
      } on PlatformException catch (err) {
        await Yust.alertService.showAlert(context, 'Fehler', err.message!);
      } on TimeoutException catch (_) {
        await Yust.alertService.showAlert(
          context,
          'Fehler',
          'Zeitüberschreitung der Anfrage',
        );
      } catch (err) {
        await Yust.alertService.showAlert(context, 'Fehler', err.toString());
      }
    }
  }
}
