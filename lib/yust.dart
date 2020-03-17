library yust;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/yust_doc_setup.dart';
import 'models/yust_user.dart';
import 'yust_service.dart';
import 'yust_store.dart';

abstract class Yust {
  static final _store = YustStore();
  static final _service = YustService();
  static YustDocSetup _userSetup;

  static YustStore store() => _store;
  static YustService service() => _service;
  static YustDocSetup userSetup() => _userSetup;

  static void initialize({YustDocSetup userSetup}) {
    Yust._userSetup = userSetup ?? YustUser.setup;
    Firestore.instance.settings(persistenceEnabled: true);

    Yust.store().authState = AuthState.waiting;
    FirebaseAuth.instance.onAuthStateChanged.listen(

        ///Calls [Yust.store().setState] on each event.
        (fireUser) async {
      if (fireUser != null) {
        YustUser user = await Yust.service()
            .getDoc<YustUser>(Yust._userSetup, fireUser.uid)
            .first;

        Yust.store().setState(() {
          Yust.store().authState =
              (user == null) ? AuthState.signedOut : AuthState.signedIn;
          if (user != null) {
            Yust.store().currUser = user;
          }
        });
      } else {
        Yust.store().setState(() {
          Yust.store().authState = AuthState.signedOut;
          Yust.store().currUser = null;
        });
      }
    });
    // FirebaseAuth.instance.onAuthStateChanged.asyncMap<YustUser>((fireUser) {
    //   return Future<YustUser>(() async {
    //     if (fireUser == null) {
    //       return null;
    //     } else {
    //       return await Yust.service().getDocOnce<YustUser>(Yust.userSetup(), fireUser.uid);
    //     }
    //   });
    // }).listen((user) {
    //   Yust.store().setState(() {
    //     Yust.store().authState = (user == null) ? AuthState.signedOut : AuthState.signedIn;
    //     if (user != null) {
    //       Yust.store().currUser = user;
    //     }
    //   });
    // });
  }
}
