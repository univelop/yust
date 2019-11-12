import 'package:yust/models/yust_user.dart';
import 'package:yust/widgets/yust_select.dart';
import 'package:yust/widgets/yust_store_builder.dart';
import 'package:yust/widgets/yust_text_field.dart';
import 'package:yust/yust.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AccountEditScreen extends StatelessWidget {
  static const String routeName = '/accountEdit';

  final bool askForGender;

  AccountEditScreen({Key key, this.askForGender = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Persönliche Daten')),
      body: YustStoreBuilder(builder: (context, child, store) {
        final user = store.currUser;
        return ListView(
          padding: const EdgeInsets.only(top: 20.0),
          children: <Widget>[
            _buildGender(context, user),
            YustTextField(
              label: 'Vorname',
              value: user.firstName,
              onChanged: (value) {
                user.firstName = value;
                Yust.service.saveDoc<YustUser>(YustUser.setup, user);
              },
            ),
            YustTextField(
              label: 'Nachname',
              value: user.lastName,
              onChanged: (value) {
                user.lastName = value;
                Yust.service.saveDoc<YustUser>(YustUser.setup, user);
              },
            ),
            YustTextField(
              label: 'E-Mail',
              value: user.email,
              enabled: false,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: RaisedButton(
                padding: const EdgeInsets.all(20.0),
                child: Text('E-Mail ändern'),
                onPressed: () => _changeEmail(context),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              child: RaisedButton(
                padding: const EdgeInsets.all(20.0),
                child: Text('Passwort ändern'),
                onPressed: () => _changePassword(context),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildGender(BuildContext context, YustUser user) {
    if (!askForGender) {
      return SizedBox.shrink();
    }
    return YustSelect(
      label: 'Anrede',
      value: user.gender,
      optionValues: [YustGender.male, YustGender.female],
      optionLabels: ['Herr', 'Frau'],
      onSelected: (value) {
        user.gender = value;
        Yust.service.saveDoc<YustUser>(YustUser.setup, user);
      },
    );
  }

  void _changeEmail(BuildContext context) {
    var email;
    var password;
    showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('E-Mail ändern'),
          children: [
            YustTextField(
              label: 'Neue E-Mail Adresse',
              value: email,
              onChanged: (value) => email = value,
            ),
            YustTextField(
              label: 'Passwort zur Bestätigung',
              value: password,
              onChanged: (value) => password = value,
              obscureText: true,
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlatButton(
                  child: Text("Abbrechen"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text('Speichern'),
                  textColor: Theme.of(context).accentColor,
                  onPressed: () async {
                    try {
                      await Yust.service.changeEmail(email, password);
                      Navigator.of(context).pop();
                      Yust.service.showAlert(context, 'E-Mail geändert',
                          'Deine E-Mail wurde erfolgreich geändert.');
                    } on PlatformException catch (err) {
                      Navigator.of(context).pop();
                      Yust.service.showAlert(context, 'Fehler', err.message);
                    } catch (err) {
                      Navigator.of(context).pop();
                      Yust.service.showAlert(context, 'Fehler', err.toString());
                    }
                  },
                ),
              ],
            )
          ],
        );
      },
    );
  }

  void _changePassword(BuildContext context) {
    var newPassword;
    var oldPassword;
    showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Passwort ändern'),
          children: [
            YustTextField(
              label: 'Neues Passwort',
              value: newPassword,
              onChanged: (value) => newPassword = value,
              obscureText: true,
            ),
            YustTextField(
              label: 'Altes Passwort zur Bestätigung',
              value: oldPassword,
              onChanged: (value) => oldPassword = value,
              obscureText: true,
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlatButton(
                  child: Text("Abbrechen"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text('Speichern'),
                  textColor: Theme.of(context).accentColor,
                  onPressed: () async {
                    try {
                      await Yust.service
                          .changePassword(newPassword, oldPassword);
                      Navigator.of(context).pop();
                      Yust.service.showAlert(context, 'Passwort geändert',
                          'Dein Passwort wurde erfolgreich geändert.');
                    } on PlatformException catch (err) {
                      Navigator.of(context).pop();
                      Yust.service.showAlert(context, 'Fehler', err.message);
                    } catch (err) {
                      Navigator.of(context).pop();
                      Yust.service.showAlert(context, 'Fehler', err.toString());
                    }
                  },
                ),
              ],
            )
          ],
        );
      },
    );
  }
}
