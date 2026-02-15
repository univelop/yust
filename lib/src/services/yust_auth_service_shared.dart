import '../../yust.dart';

class YustAuthServiceShared {
  static Future<bool> tryLinkYustUser(
    Yust yust,
    String email,
    String authUserId,
    YustAuthenticationMethod? method,
  ) async {
    final user = await yust.dbService.getFirst<YustUser>(
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

  static Future<YustUser> createYustUser({
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
    if (Yust.userSetup.newDoc == null) {
      throw YustException(
        'No newDoc function provided for ${Yust.userSetup.collectionName}, cannot initialize user.',
      );
    }

    final user = Yust.userSetup.newDoc!()
      ..email = email
      ..firstName = firstName
      ..lastName = lastName
      ..id = id
      ..authId = authId
      ..authenticationMethod = authenticationMethod
      ..domain = domain ?? email.split('@').last
      ..gender = gender
      ..lastLogin = DateTime.now()
      ..lastLoginDomain = Uri.base.scheme.contains('http')
          ? Uri.base.host
          : null;
    await yust.dbService.saveDoc<YustUser>(Yust.userSetup, user);
    return user;
  }
}

class YustUserAlreadyHasPasswordException extends YustException {
  YustUserAlreadyHasPasswordException(super.message);
}

class YustProviderNotAllowed extends YustException {
  final List<String> providerIds;
  YustProviderNotAllowed(super.message, {required this.providerIds});
}
