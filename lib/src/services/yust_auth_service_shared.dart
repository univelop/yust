import 'package:firebase_auth/firebase_auth.dart';

import '../../yust.dart';

class YustAuthServiceShared {
  static Future<bool> tryLinkYustUser(
    Yust yust,
    User user,
    YustAuthenticationMethod? method,
  ) async {
    final yustUser = await yust.dbService.getFirst<YustUser>(
      Yust.userSetup,
      filters: [
        YustFilter(
          field: 'email',
          comparator: YustFilterComparator.equal,
          value: user.email,
        ),
      ],
    );
    if (yustUser == null) return false;

    await yustUser.linkAuth(user.uid, method);

    await yustUser.setLoginFields(user: user, skipSave: true);

    return true;
  }

  static Future<YustUser> createYustUser({
    required Yust yust,
    required String firstName,
    required String lastName,
    required User user,
    YustAuthenticationMethod? authenticationMethod,
    String? domain,
    YustGender? gender,
  }) async {
    if (Yust.userSetup.newDoc == null) {
      throw YustException(
        'No newDoc function provided for ${Yust.userSetup.collectionName}, cannot initialize user.',
      );
    }

    final yustUser = Yust.userSetup.newDoc!()
      ..email = user.email ?? ''
      ..firstName = firstName
      ..lastName = lastName
      ..id = user.uid
      ..authId = user.uid
      ..authenticationMethod = authenticationMethod
      ..domain = domain ?? (user.email ?? '').split('@').last
      ..gender = gender
      ..lastLogin = DateTime.now()
      ..lastLoginDomain = Uri.base.scheme.contains('http')
          ? Uri.base.host
          : null;

    await yustUser.setLoginFields(user: user, skipSave: true);

    await yust.dbService.saveDoc<YustUser>(Yust.userSetup, yustUser);
    return yustUser;
  }
}

class YustUserAlreadyHasPasswordException extends YustException {
  YustUserAlreadyHasPasswordException(super.message);
}

class YustProviderNotAllowed extends YustException {
  final List<String> providerIds;
  YustProviderNotAllowed(super.message, {required this.providerIds});
}
