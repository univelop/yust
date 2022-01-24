import 'dart:io';
import 'dart:typed_data';

typedef YustFileJson = Map<String, String?>;
typedef YustFilesJson = List<YustFileJson>;

class YustFile {
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

  factory YustFile.fromJson(YustFileJson json) {
    return YustFile(
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }

  YustFileJson toJson() {
    return <String, String?>{
      'name': name,
      'url': url,
    };
  }
}
