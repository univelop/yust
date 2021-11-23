/// A local file for profiding offline compatibility.
class YustLocalFile {
// TODO: delete

  String name;

  /// Path to the file on the local device.
  String devicePath;

  /// Path to the storage folder.
  String storageFolderPath;

  /// Path to the Firebase document.
  String linkedDocPath;

  /// Attribute of the Firebase document.
  String linkedDocAttribute;

  YustLocalFile({
    required this.name,
    file,
    required this.storageFolderPath,
    required this.linkedDocPath,
    required this.linkedDocAttribute,
    required this.devicePath,
  });

  factory YustLocalFile.fromJson(Map<String, dynamic> json) {
    return YustLocalFile(
      name: json['name'] as String,
      storageFolderPath: json['folderPath'] as String,
      linkedDocPath: json['pathToDoc'] as String,
      linkedDocAttribute: json['docAttribute'] as String,
      devicePath: json['localPath'] as String,
    );
  }

  Map<String, String> toJson() {
    return <String, String>{
      'name': name,
      'folderPath': storageFolderPath,
      'pathToDoc': linkedDocPath,
      'docAttribute': linkedDocAttribute,
      'localPath': devicePath,
    };
  }
}
