import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_store_builder.dart';

import '../yust.dart';
import '../yust_store.dart';
import 'account_edit.dart';

class AccountScreen<T extends YustStore> extends StatelessWidget {
  static const String routeName = '/account';
  static const bool signInRequired = true;

  @override
  Widget build(BuildContext context) {
    return YustStoreBuilder<T>(
      builder: (context, child, store) {
        if (store.currUser == null) {
          return Scaffold(
            body: Center(
              child: Text('In Arbeit...'),
            ),
          );
        }
        return Scaffold(
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
                      color: Theme.of(context).colorScheme.secondary,
                      size: 100.0,
                    ),
                    Text(
                        (store.currUser!.firstName) +
                            ' ' +
                            (Yust.store.currUser!.lastName),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 20.0)),
                  ],
                ),
              ),
              Divider(thickness: 1.0),
              ListTile(
                leading: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 40.0,
                ),
                title: Text(
                  'Persönliche Daten',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
                onTap: () {
                  Navigator.pushNamed(context, AccountEditScreen.routeName);
                },
              ),
              Divider(thickness: 1.0),
              ListTile(
                leading: Icon(
                  Icons.power_settings_new,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 40.0,
                ),
                title: Text(
                  'Abmelden',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
                onTap: () {
                  Yust.service.signOut(context);
                },
              ),
              Divider(thickness: 1.0),
            ],
          ),
        );
      },
    );
  }
}
