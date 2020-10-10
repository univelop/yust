import 'dart:io';
import 'dart:typed_data';

class YustFile {
  String name;
  String url;
  File file;
  Uint8List bytes;
  bool processing;

  YustFile({
    this.name,
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
