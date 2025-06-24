import 'package:json_annotation/json_annotation.dart';

import '../yust.dart';
import 'yust_doc.dart';
import 'yust_doc_setup.dart';
import 'yust_image.dart';

part 'yust_user.g.dart';

/// The user model.
@JsonSerializable()
class YustUser extends YustDoc {
  static YustDocSetup<YustUser> setup() => YustDocSetup<YustUser>(
        collectionName: 'users',
        newDoc: () => YustUser(email: '', firstName: '', lastName: ''),
        fromJson: (json) => YustUser.fromJson(json),
      );

  String get searchTag => '${firstName.toLowerCase()} ${lastName.toLowerCase()}'
      .replaceAll(' ', '_');

  /// The email of the user.
  String email;

  /// The first name of the user.
  String firstName;

  /// The last name of the user.
  String lastName;

  /// The gender of the user.
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  YustGender? gender;

  /// The tenant the user has access to.
  @JsonKey(defaultValue: {})
  Map<String, bool?> envIds = {};

  /// The current tenant the user is using.
  String? currEnvId;

  /// ID of devices the user is using.
  List<String>? deviceIds = [];

  /// The timestamp of the last login.
  DateTime? lastLogin;

  /// The domain of the last login.
  String? lastLoginDomain;

  /// The authentication method.
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  YustAuthenticationMethod? authenticationMethod;

  /// The domain of the user mail.
  String? domain;

  /// The link to the authentication user uid.
  String? authId;

  /// Profile picture.
  YustImage? profilePicture;

  /// Locale
  String locale;

  /// The attributes for a user.
  @JsonKey(defaultValue: {})
  Map<String, dynamic> userAttributes = {};

  YustUser({
    required this.email,
    required this.firstName,
    required this.lastName,
    this.gender,
    this.authId,
    String? locale,
  }) : locale = locale ?? 'de';

  factory YustUser.fromJson(Map<String, dynamic> json) =>
      _$YustUserFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$YustUserToJson(this);

  /// Saves the current [DateTime] as the last login and the current domain.
  Future<void> setLoginFields({Yust? yust}) async {
    lastLoginDomain =
        Uri.base.scheme.contains('http') ? Uri.base.host : lastLoginDomain;
    lastLogin = Yust.helpers.utcNow();
    await (yust?.dbService ?? Yust.databaseService)
        .saveDoc<YustUser>(Yust.userSetup, this);
  }

  /// Returns the user name.
  String getName() {
    return '$firstName $lastName';
  }

  /// Deletes the user.
  Future<void> delete(
      {String? password, bool deleteAuth = true, Yust? yust}) async {
    await (yust?.dbService ?? Yust.databaseService)
        .deleteDoc<YustUser>(YustUser.setup(), this);
    if (deleteAuth) await Yust.authService.deleteAccount(password);
  }

  Future<void> linkAuth(String uid, YustAuthenticationMethod? method,
      {Yust? yust}) async {
    authId = uid;
    authenticationMethod = method;
    await (yust?.dbService ?? Yust.databaseService)
        .saveDoc<YustUser>(Yust.userSetup, this);
  }

  /// This method returns the value of the attribute with the given key.
  T getAttribute<T>(String key, T defaultValue) {
    if (userAttributes[key] == null) return defaultValue;
    if (T == DateTime) {
      return DateTime.parse(userAttributes[key] as String) as T;
    }
    return userAttributes[key];
  }

  /// This method returns the value of the attribute with the given key or null if the attribute does not exist.
  T? getAttributeOrNull<T>(String key) => userAttributes[key];

  /// This method sets the value of the attribute with the given key.
  void setAttribute(String key, dynamic value) => userAttributes[key] = value;
}

enum YustGender {
  male,
  female,
}

enum YustAuthenticationMethod {
  mail('Email'),
  microsoft('Microsoft'),
  // github('GitHub'),
  google('Google'),
  apple('Apple'),
  openId('OpenID');

  const YustAuthenticationMethod(this.label);

  final String label;
}
