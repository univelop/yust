library yust;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info/package_info.dart';

import 'models/yust_doc_setup.dart';
import 'models/yust_user.dart';
import 'yust_service.dart';
import 'yust_store.dart';

class Yust {
  static final store = YustStore();
  static final service = YustService();
  static YustDocSetup<YustUser> userSetup;

  static void initialize({YustDocSetup userSetup}) {
    Yust.userSetup = userSetup ?? YustUser.setup;
    Firestore.instance.settings(persistenceEnabled: true);

    Yust.store.authState = AuthState.waiting;
    FirebaseAuth.instance.onAuthStateChanged.listen(

        ///Calls [Yust.store.setState] on each event.
        (fireUser) async {
      if (fireUser != null) {
        YustUser user = await Yust.service
            .getDoc<YustUser>(Yust.userSetup, fireUser.uid)
            .first;

        if (user == null) {
          user = Yust.userSetup.newDoc()
            ..id = fireUser.uid
            ..email = fireUser.email;
          await Yust.service.saveDoc<YustUser>(Yust.userSetup, user);
        }

        Yust.store.setState(() {
          Yust.store.authState = AuthState.signedIn;
          Yust.store.currUser = user;
        });
      } else {
        Yust.store.setState(() {
          Yust.store.authState = AuthState.signedOut;
          Yust.store.currUser = null;
        });
      }
    });

    if (!kIsWeb) {
      PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
        Yust.store.setState(() {
          Yust.store.packageInfo = packageInfo;
        });
      });
    }
  }
}
