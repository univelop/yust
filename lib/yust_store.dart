import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

import 'models/yust_user.dart';

enum AuthState {
  waiting,
  signedIn,
  signedOut,
}

class YustStore extends ChangeNotifier {
  AuthState authState;

  ///Null if the user is signed out.
  YustUser currUser;

  PackageInfo packageInfo;

  void setState(void Function() f) {
    f();
    notifyListeners();
  }
}
