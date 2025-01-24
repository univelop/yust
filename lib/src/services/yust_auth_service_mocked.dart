import 'package:uuid/uuid.dart';

import '../../yust.dart';

import 'yust_auth_service.dart';

class YustAuthServiceMocked extends YustAuthService {
  final Yust _yust;

  YustAuthServiceMocked(super.yust) : _yust = yust;

  @override
  Future<YustUser?> createAccount(
      String firstName, String lastName, String email, String password,
      {YustGender? gender, bool useOAuth = false}) {
    final id = Uuid().v4();

    return YustAuthServiceShared.createYustUser(
      yust: _yust,
      firstName: firstName,
      lastName: lastName,
      email: email,
      id: id,
      authId: id,
    );
  }
}
