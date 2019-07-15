import 'package:json_annotation/json_annotation.dart';

import 'yust_doc.dart';
import 'yust_doc_setup.dart';

part 'yust_user.g.dart';

@JsonSerializable()
class YustUser extends YustDoc {

  static final setup = YustDocSetup(
    collectionName: 'users',
    fromJson: (json) => YustUser.fromJson(json),
  );

  String email;
  String firstName;
  String lastName;
  List<String> envIds = [];
  String currEnvId;

  YustUser({this.email, this.firstName, this.lastName});

  factory YustUser.fromJson(Map<String, dynamic> json) => _$YustUserFromJson(json);

  Map<String, dynamic> toJson() => _$YustUserToJson(this);

}