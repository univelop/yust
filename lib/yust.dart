library yust;

import 'package:firebase_auth/firebase_auth.dart';

import 'models/yust_user.dart';
import 'yust_service.dart';
import 'yust_store.dart';

class Yust {

  static final store = YustStore();
  static final service = YustService();

  static void initialize() {
    Yust.store.authState = AuthState.waiting;
    FirebaseAuth.instance.onAuthStateChanged.asyncMap<YustUser>((fireUser) {
      return Future<YustUser>(() async {
        if (fireUser == null) {
          return null;
        } else {
          return await Yust.service.getDoc<YustUser>(YustUser.setup, fireUser.uid).first;
        }
      });
    }).listen((user) {
      Yust.store.setState(() {
        Yust.store.authState = (user == null) ? AuthState.signedOut : AuthState.signedIn;
        if (user != null) {
          Yust.store.currUser = user;
        }
      });
    });
  }

}
