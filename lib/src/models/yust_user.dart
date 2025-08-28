import 'package:collection/collection.dart';
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
  String _email;
  String get email => _email;
  set email(String s) {
    if (s != _email) updateMask.add('email');
    _email = s;
  }

  /// The first name of the user.
  String _firstName;
  String get firstName => _firstName;
  set firstName(String s) {
    if (s != _firstName) updateMask.add('firstName');
    _firstName = s;
  }

  /// The last name of the user.
  String _lastName;
  String get lastName => _lastName;
  set lastName(String s) {
    if (s != _lastName) updateMask.add('lastName');
    _lastName = s;
  }

  /// The gender of the user.
  YustGender? _gender;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  YustGender? get gender => _gender;
  set gender(YustGender? s) {
    if (s != _gender) updateMask.add('gender');
    _gender = s;
  }

  /// The tenant the user has access to.
  Map<String, bool?> _envIds;

  /// The envIds the user has access to.
  /// This should not be used directly,
  /// but rather use [getEnvIds], [hasEnvId], [addEnvId], [removeEnvId] instead.
  Map<String, bool?> get envIds => Map.unmodifiable(_envIds);

  /// The current tenant the user is using.
  String? _currEnvId;
  String? get currEnvId => _currEnvId;
  set currEnvId(String? s) {
    if (s != _currEnvId) updateMask.add('currEnvId');
    _currEnvId = s;
  }

  /// ID of devices the user is using.
  List<String>? _deviceIds;
  List<String> get deviceIds => List.unmodifiable(_deviceIds ?? []);

  /// The timestamp of the last login.
  DateTime? _lastLogin;
  DateTime? get lastLogin => _lastLogin;
  set lastLogin(DateTime? s) {
    if (s != _lastLogin) updateMask.add('lastLogin');
    _lastLogin = s;
  }

  /// The domain of the last login.
  String? _lastLoginDomain;
  String? get lastLoginDomain => _lastLoginDomain;
  set lastLoginDomain(String? s) {
    if (s != _lastLoginDomain) updateMask.add('lastLoginDomain');
    _lastLoginDomain = s;
  }

  /// The authentication method.
  YustAuthenticationMethod? _authenticationMethod;
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  YustAuthenticationMethod? get authenticationMethod => _authenticationMethod;
  set authenticationMethod(YustAuthenticationMethod? s) {
    if (s != _authenticationMethod) updateMask.add('authenticationMethod');
    _authenticationMethod = s;
  }

  /// The domain of the user mail.
  String? _domain;
  String? get domain => _domain;
  set domain(String? s) {
    if (s != _domain) updateMask.add('domain');
    _domain = s;
  }

  /// The link to the authentication user uid.
  String? _authId;
  String? get authId => _authId;
  set authId(String? s) {
    if (s != _authId) updateMask.add('authId');
    _authId = s;
  }

  /// Profile picture.
  YustImage? _profilePicture;
  YustImage? get profilePicture => _profilePicture;
  set profilePicture(YustImage? s) {
    if (s != _profilePicture) updateMask.add('profilePicture');
    _profilePicture = s;
  }

  /// Locale
  String _locale;
  String get locale => _locale;
  set locale(String s) {
    if (s != _locale) updateMask.add('locale');
    _locale = s;
  }

  /// The attributes for a user.
  @JsonKey(defaultValue: {})
  Map<String, dynamic> _userAttributes;
  Map<String, dynamic> get userAttributes => Map.unmodifiable(_userAttributes);

  YustUser({
    required String email,
    required String firstName,
    required String lastName,
    YustGender? gender,
    Map<String, bool?> envIds = const {},
    List<String>? deviceIds,
    String? authId,
    String? locale,
    Map<String, dynamic> userAttributes = const {},
  }) : _email = email,
       _firstName = firstName,
       _lastName = lastName,
       _gender = gender,
       _envIds = envIds,
       _deviceIds = deviceIds,
       _authId = authId,
       _locale = locale ?? 'de',
       _userAttributes = userAttributes;

  factory YustUser.fromJson(Map<String, dynamic> json) =>
      _$YustUserFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$YustUserToJson(this);

  /// Returns the envIds the User has access to.
  Iterable<String> getEnvIds() => _envIds.keys.where((e) => _envIds[e] == true);

  /// Checks if the User has access to the given [envId].
  bool hasEnvId(String? envId) => envId != null && _envIds[envId] == true;

  /// Adds an [envId] to list of envIds the User has access to.
  void addEnvId(String envId) {
    if (_envIds[envId] == true) return;
    _envIds[envId] = true;
    updateMask.add('envIds.$envId');
  }

  /// Removes the [envId] from the list of envIds the User has access to.
  void removeEnvId(String envId) {
    if (_envIds[envId] != true) return;
    _envIds[envId] = false;
    updateMask.add('envIds');
  }

  /// Sets the deviceIds of the user.
  void setDeviceIds(List<String> deviceIds) {
    if (UnorderedIterableEquality().equals(this.deviceIds, deviceIds)) return;
    _deviceIds = deviceIds;
    updateMask.add('deviceIds');
  }

  /// Adds a deviceId to the user.
  void addDeviceId(String deviceId) {
    if (deviceIds.contains(deviceId)) return;
    setDeviceIds([...deviceIds, deviceId]);
  }

  /// Removes a deviceId from the user.
  void removeDeviceId(String deviceId) {
    if (!deviceIds.contains(deviceId)) return;
    setDeviceIds(deviceIds.where((e) => e != deviceId).toList());
  }

  /// Saves the current [DateTime] as the last login and the current domain.
  Future<void> setLoginFields({Yust? yust}) async {
    lastLoginDomain = Uri.base.scheme.contains('http')
        ? Uri.base.host
        : lastLoginDomain;
    lastLogin = Yust.helpers.utcNow();
    await (yust?.dbService ?? Yust.databaseService).saveDoc<YustUser>(
      Yust.userSetup,
      this,
    );
  }

  /// Returns the user name.
  String getName() {
    return '$firstName $lastName';
  }

  /// Deletes the user.
  Future<void> delete({
    String? password,
    bool deleteAuth = true,
    Yust? yust,
  }) async {
    await (yust?.dbService ?? Yust.databaseService).deleteDoc<YustUser>(
      YustUser.setup(),
      this,
    );
    if (deleteAuth) await Yust.authService.deleteAccount(password);
  }

  Future<void> linkAuth(
    String uid,
    YustAuthenticationMethod? method, {
    Yust? yust,
  }) async {
    authId = uid;
    authenticationMethod = method;
    await (yust?.dbService ?? Yust.databaseService).saveDoc<YustUser>(
      Yust.userSetup,
      this,
    );
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
  void setAttribute(String key, dynamic value) {
    if (userAttributes[key] == value) return;
    userAttributes[key] = value;
    updateMask.add('userAttributes.$key');
  }
}

/// The gender of the user.
enum YustGender { male, female }

/// The authentication method of the user.
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
