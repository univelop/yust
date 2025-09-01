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

  String _email;

  /// The email of the user.
  String get email => _email;
  set email(String s) {
    if (s == _email) return;
    updateMask.add('email');
    _email = s;
  }

  String _firstName;

  /// The first name of the user.
  String get firstName => _firstName;
  set firstName(String s) {
    if (s == _firstName) return;
    updateMask.add('firstName');
    _firstName = s;
  }

  String _lastName;

  /// The last name of the user.
  String get lastName => _lastName;
  set lastName(String s) {
    if (s == _lastName) return;
    updateMask.add('lastName');
    _lastName = s;
  }

  YustGender? _gender;

  /// The gender of the user.
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  YustGender? get gender => _gender;
  set gender(YustGender? s) {
    if (s == _gender) return;
    updateMask.add('gender');
    _gender = s;
  }

  @JsonKey(
    includeFromJson: true,
    includeToJson: true,
    name: 'envIds',
    defaultValue: {},
  )
  Map<String, bool?> _envIds;

  /// The tenant the user has access to.
  /// We have a Map instead of a list to be able to filter for active envIds.
  /// This should not be used directly,
  /// but rather use [getActiveEnvIds], [hasEnvId], [addEnvId], [removeEnvId] instead.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, bool?> get envIds => Map.unmodifiable(_envIds);

  String? _currEnvId;

  /// The current tenant the user is using.
  String? get currEnvId => _currEnvId;
  set currEnvId(String? s) {
    if (s == _currEnvId) return;
    updateMask.add('currEnvId');
    _currEnvId = s;
  }

  @JsonKey(
    includeFromJson: true,
    includeToJson: true,
    name: 'deviceIds',
    defaultValue: [],
  )
  List<String>? _deviceIds;

  /// ID of devices the user is using.
  /// This should not be used directly to change the deviceIds,
  /// but rather use [setDeviceIds], [addDeviceId], [removeDeviceId] instead.
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<String> get deviceIds => List.unmodifiable(_deviceIds ?? []);

  DateTime? _lastLogin;

  /// The timestamp of the last login.
  DateTime? get lastLogin => _lastLogin;
  set lastLogin(DateTime? s) {
    if (s == _lastLogin) return;
    updateMask.add('lastLogin');
    _lastLogin = s;
  }

  String? _lastLoginDomain;

  /// The domain of the last login.
  String? get lastLoginDomain => _lastLoginDomain;
  set lastLoginDomain(String? s) {
    if (s == _lastLoginDomain) return;
    updateMask.add('lastLoginDomain');
    _lastLoginDomain = s;
  }

  YustAuthenticationMethod? _authenticationMethod;

  /// The authentication method.
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  YustAuthenticationMethod? get authenticationMethod => _authenticationMethod;
  set authenticationMethod(YustAuthenticationMethod? s) {
    if (s == _authenticationMethod) return;
    updateMask.add('authenticationMethod');
    _authenticationMethod = s;
  }

  String? _domain;

  /// The domain of the user mail.
  String? get domain => _domain;
  set domain(String? s) {
    if (s == _domain) return;
    updateMask.add('domain');
    _domain = s;
  }

  String? _authId;

  /// The link to the authentication user uid.
  String? get authId => _authId;
  set authId(String? s) {
    if (s == _authId) return;
    updateMask.add('authId');
    _authId = s;
  }

  YustImage? _profilePicture;

  /// Profile picture.
  YustImage? get profilePicture => _profilePicture;
  set profilePicture(YustImage? s) {
    if (s == _profilePicture) return;
    updateMask.add('profilePicture');
    _profilePicture = s;
  }

  String _locale;

  /// Locale
  String get locale => _locale;
  set locale(String s) {
    if (s == _locale) return;
    updateMask.add('locale');
    _locale = s;
  }

  @JsonKey(
    includeFromJson: true,
    includeToJson: true,
    name: 'userAttributes',
    defaultValue: {},
  )
  Map<String, dynamic> _userAttributes;

  /// The attributes for a user.
  /// This should not be used directly to change the userAttributes,
  /// but rather use [setAttribute] instead.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
  Iterable<String> getActiveEnvIds() =>
      _envIds.keys.where((e) => _envIds[e] == true);

  /// Checks if the User has access to the given [envId].
  bool hasEnvId(String? envId) => envId != null && _envIds[envId] == true;

  /// Adds an [envId] to list of envIds the User has access to.
  void addEnvId(String envId) {
    if (_envIds[envId] == true) return;
    updateMask.add('envIds.$envId');
    _envIds[envId] = true;
  }

  /// Removes the [envId] from the list of envIds the User has access to.
  void removeEnvId(String envId) {
    if (!_envIds.containsKey(envId)) return;
    updateMask.add('envIds');
    _envIds.remove(envId);
  }

  /// Sets the deviceIds of the user.
  void setDeviceIds(List<String> deviceIds) {
    if (UnorderedIterableEquality().equals(this.deviceIds, deviceIds)) return;
    updateMask.add('deviceIds');
    _deviceIds = deviceIds;
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
    updateMask.add('userAttributes.$key');
    userAttributes[key] = value;
  }

  void removeAttribute(String key) {
    if (!userAttributes.containsKey(key)) return;
    updateMask.add('userAttributes');
    userAttributes.remove(key);
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
