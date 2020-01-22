import 'package:scoped_model/scoped_model.dart';

import 'models/yust_user.dart';

enum AuthState {
  waiting,
  signedIn,
  signedOut,
}

class YustStore extends Model {
  AuthState authState;

  ///Null if the user is signed out.
  YustUser currUser;

  void setState(void Function() f) {
    f();
    notifyListeners();
  }
}
