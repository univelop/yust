import 'package:json_annotation/json_annotation.dart';
import 'package:yust/yust.dart';

import 'yust_doc.dart';
import 'yust_doc_setup.dart';

part 'yust_user.g.dart';

@JsonSerializable()
class YustUser extends YustDoc {
  static final setup = YustDocSetup<YustUser>(
    collectionName: 'users',
    newDoc: () => YustUser(email: '', firstName: '', lastName: ''),
    fromJson: (json) => YustUser.fromJson(json),
  );

  String email;
  String firstName;
  String lastName;
  YustGender? gender;

  Map<String, bool?> envIds = {};
  String? currEnvId;
  List<String>? deviceIds = [];

  DateTime? lastLogin;

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

  void setLoginTime() async {
    lastLogin = DateTime.now();
    await Yust.databaseService.saveDoc<YustUser>(Yust.userSetup, this);
  }

  String getName() {
    return firstName + ' ' + lastName;
  }
}

enum YustGender {
  male,
  female,
}
