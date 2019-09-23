import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_store_builder.dart';

import '../yust.dart';
import 'account_edit.dart';

class AccountScreen extends StatelessWidget {
  
  static String routeName = 'account';
  
  @override
  Widget build(BuildContext context) {
    return YustStoreBuilder(
      builder: (context, child, store) => Scaffold(
        appBar: AppBar(title: Text('Account')),
        body: ListView(
          padding: const EdgeInsets.only(top: 20.0),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                children: <Widget>[
                  Icon(
                    Icons.person,
                    color: Theme.of(context).accentColor,
                    size: 100.0,
                  ),
                  Text(
                    store.currUser.firstName + ' ' + Yust.store.currUser.lastName,
                    style: TextStyle(
                      color: Theme.of(context).accentColor, 
                      fontSize: 20.0
                    )
                  ),
                ]
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.person, color: Theme.of(context).accentColor, size: 40.0),
              title: Text('Persönliche Daten', style: TextStyle(color: Theme.of(context).accentColor)),
              onTap: () {
                Navigator.pushNamed(context, AccountEditScreen.routeName);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.power_settings_new, color: Theme.of(context).accentColor, size: 40.0),
              title: Text('Abmelden', style: TextStyle(color: Theme.of(context).accentColor)),
              onTap: () {
                Yust.service.signOut();
                Navigator.pop(context);
              },
            ),
            Divider(),
          ],
        ),
      )
    );
  }

}