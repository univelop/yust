import 'dart:io';
import 'dart:typed_data';

import 'package:yust/util/yust_serializable.dart';

class YustFile with YustSerializable {
  String name;
  String? url;
  File? file;
  Uint8List? bytes;
  bool processing;

  YustFile({
    required this.name,
    this.url,
    this.file,
    this.bytes,
    this.processing = false,
  });

  factory YustFile.fromJson(Map<String, dynamic> json) {
    return YustFile(
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'url': url,
    };
  }
}

class YustLocalFile extends YustFile {
  String folderPath;
  String pathToDoc;
  String docAttribute;
  String localPath;

  YustLocalFile({
    required name,
    file,
    required this.folderPath,
    required this.pathToDoc,
    required this.docAttribute,
    required this.localPath,
  }) : super(
          name: name,
          file: file,
        );

  factory YustLocalFile.fromJson(Map<String, dynamic> json) {
    return YustLocalFile(
      name: json['name'] as String,
      folderPath: json['folderPath'] as String,
      pathToDoc: json['pathToDoc'] as String,
      docAttribute: json['docAttribute'] as String,
      localPath: json['localPath'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'folderPath': folderPath,
      'pathToDoc': pathToDoc,
      'docAttribute': docAttribute,
      'localPath': localPath,
    };
  }
}
