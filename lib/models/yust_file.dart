import 'dart:io';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

part 'yust_file.g.dart';

typedef YustFileJson = Map<String, dynamic>;
typedef YustFilesJson = List<YustFileJson>;

@JsonSerializable()
class YustFile {
  String? name;
  String? url;

  @JsonKey(ignore: true)
  File? file;
  @JsonKey(ignore: true)
  Uint8List? bytes;
  @JsonKey(ignore: true)
  bool processing;

  YustFile({
    this.name,
    this.url,
    this.file,
    this.bytes,
    this.processing = false,
  });

  factory YustFile.fromJson(Map<String, dynamic> json) =>
      _$YustFileFromJson(json);

  Map<String, dynamic> toJson() => _$YustFileToJson(this);
}
