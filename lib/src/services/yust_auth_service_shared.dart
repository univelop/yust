import '../../yust.dart';

class YustAuthServiceShared {
  static Future<bool> tryLinkYustUser(
    String email,
    String authUserId,
    YustAuthenticationMethod? method,
  ) async {
    final user = await Yust.databaseService.getFirst<YustUser>(
      Yust.userSetup,
      filters: [
        YustFilter(
          field: 'email',
          comparator: YustFilterComparator.equal,
          value: email,
        ),
      ],
    );
    if (user == null) return false;
    await user.linkAuth(authUserId, method);
    return true;
  }

  static Future<YustUser> createUser({
    required Yust yust,
    required String firstName,
    required String lastName,
    required String email,
    required String id,
    required String authId,
    YustAuthenticationMethod? authenticationMethod,
    String? domain,
    YustGender? gender,
  }) async {
    final user = Yust.userSetup.newDoc()
      ..email = email
      ..firstName = firstName
      ..lastName = lastName
      ..id = id
      ..authId = authId
      ..authenticationMethod = authenticationMethod
      ..domain = domain ?? email.split('@').last
      ..gender = gender
      ..lastLogin = DateTime.now()
      ..lastLoginDomain =
          Uri.base.scheme.contains('http') ? Uri.base.host : null;
    await yust.dbService.saveDoc<YustUser>(Yust.userSetup, user);
    return user;
  }
}
