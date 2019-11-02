library yust;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'models/yust_user.dart';
import 'yust_service.dart';
import 'yust_store.dart';

class Yust {

  static final store = YustStore();
  static final service = YustService();

  static void initialize() {
    Firestore.instance.settings(persistenceEnabled: true);
    
    Yust.store.authState = AuthState.waiting;
    FirebaseAuth.instance.onAuthStateChanged.listen((fireUser) {
      if (fireUser != null) {
        Yust.service.getDoc<YustUser>(YustUser.setup, fireUser.uid).listen((user) {
          Yust.store.setState(() {
            Yust.store.authState = (user == null) ? AuthState.signedOut : AuthState.signedIn;
            if (user != null) {
              Yust.store.currUser = user;
            }
          });
        });
      } else {
        Yust.store.setState(() {
          Yust.store.authState = AuthState.signedOut;
        });
      }
    });
    // FirebaseAuth.instance.onAuthStateChanged.asyncMap<YustUser>((fireUser) {
    //   return Future<YustUser>(() async {
    //     if (fireUser == null) {
    //       return null;
    //     } else {
    //       return await Yust.service.getDocOnce<YustUser>(YustUser.setup, fireUser.uid);
    //     }
    //   });
    // }).listen((user) {
    //   Yust.store.setState(() {
    //     Yust.store.authState = (user == null) ? AuthState.signedOut : AuthState.signedIn;
    //     if (user != null) {
    //       Yust.store.currUser = user;
    //     }
    //   });
    // });
  }

}
