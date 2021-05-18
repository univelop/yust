import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'models/yust_user.dart';

enum AuthState {
  waiting,
  signedIn,
  signedOut,
}

class YustStore extends ChangeNotifier {
  AuthState authState = AuthState.waiting;

  ///Null if the user is signed out.
  YustUser? currUser;

  late PackageInfo packageInfo;

  void setState(void Function() f) {
    f();
    notifyListeners();
  }
}
