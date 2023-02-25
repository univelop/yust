import 'package:json_annotation/json_annotation.dart';

import '../yust.dart';
import 'yust_doc.dart';
import 'yust_doc_setup.dart';

part 'yust_user.g.dart';

/// The user model.
@JsonSerializable()
class YustUser extends YustDoc {
  static YustDocSetup<YustUser> setup() => YustDocSetup<YustUser>(
        collectionName: 'users',
        newDoc: () => YustUser(email: '', firstName: '', lastName: ''),
        fromJson: (json) => YustUser.fromJson(json),
      );

  /// The email of the user.
  String email;

  /// The first name of the user.
  String firstName;

  /// The last name of the user.
  String lastName;

  /// The gender of the user.
  YustGender? gender;

  /// The tannants the user has access to.
  @JsonKey(defaultValue: {})
  Map<String, bool?> envIds = {};

  /// The current tannant the user is using.
  String? currEnvId;

  /// ID of devices the user is using.
  List<String>? deviceIds = [];

  /// The timestamp of the last login.
  DateTime? lastLogin;

  /// The authentication method.
  YustAuthenticationMethod? authenticationMethod;

  /// The domain of the user mail.
  String? domain;

  YustUser({
    required this.email,
    required this.firstName,
    required this.lastName,
    this.gender,
  });

  factory YustUser.fromJson(Map<String, dynamic> json) =>
      _$YustUserFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$YustUserToJson(this);

  /// Saves the current [DateTime] as the last login.
  void setLoginTime() async {
    lastLogin = Yust.helpers.utcNow();
    await Yust.databaseService.saveDoc<YustUser>(Yust.userSetup, this);
  }

  /// Returns the user name.
  String getName() {
    return '$firstName $lastName';
  }

  /// Deletes the user.
  Future<void> delete({String? password, bool deleteAuth = true}) async {
    await Yust.databaseService.deleteDoc<YustUser>(YustUser.setup(), this);
    if (deleteAuth) await Yust.authService.deleteAccount(password);
  }
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
  ;

  const YustAuthenticationMethod(this.label);

  final String label;
}
