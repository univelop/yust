import 'dart:io';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

part 'yust_file.g.dart';

typedef YustFileJson = Map<String, dynamic>;
typedef YustFilesJson = List<YustFileJson>;

/// A binary file handled by database and file storage.
/// A file is stored in Firebase Storeage and linked to a document in the database.
/// For offline caching a file can also be stored on the device.

@JsonSerializable()
class YustFile {
  /// The name of the file with extension.
  String? name;

  /// The URL to download the file.
  String? url;

  /// The binary file. This attibute is used for iOS and Android. For web [bytes] is used instead.
  @JsonKey(ignore: true)
  File? file;

  /// The binary file for web. For iOS and Android [file] is used instead.
  @JsonKey(ignore: true)
  Uint8List? bytes;

  /// Path to the storage folder. Used for offline caching.
  @JsonKey(ignore: true)
  String? storageFolderPath;

  /// Path to the file on the device. Used for offline caching.
  @JsonKey(ignore: true)
  String? devicePath;

  /// Path to the Firebase document. Used for offline caching.
  @JsonKey(ignore: true)
  String? linkedDocPath;

  /// Attribute of the Firebase document. Used for offline caching.
  @JsonKey(ignore: true)
  String? linkedDocAttribute;

  /// stores the last error. Used in offline caching
  @JsonKey(ignore: true)
  String? lastError;

  /// Is true while uploading the file.
  @JsonKey(ignore: true)
  bool processing;

  /// True if image can be stored in cache.
  bool get cacheable => linkedDocPath != null && linkedDocAttribute != null;

  /// True if image is cached locally.
  bool get cached => devicePath != null;

  YustFile({
    this.name,
    this.url,
    this.file,
    this.bytes,
    this.devicePath,
    this.storageFolderPath,
    this.linkedDocPath,
    this.linkedDocAttribute,
    this.processing = false,
    this.lastError,
  });

  /// Converts the file to JSON for Firebase. Only relevant attributs are converted.
  factory YustFile.fromJson(Map<String, dynamic> json) =>
      _$YustFileFromJson(json);

  /// Converts JSON from Firebase to a file. Only relevant attributs are included.
  Map<String, dynamic> toJson() => _$YustFileToJson(this);

  /// Converts the file to JSON for local device. Only relevant attributs are converted.
  factory YustFile.fromLocalJson(Map<String, dynamic> json) {
    return YustFile(
      name: json['name'] as String,
      storageFolderPath: json['storageFolderPath'] as String,
      devicePath: json['devicePath'] as String,
      linkedDocPath: json['linkedDocPath'] as String,
      linkedDocAttribute: json['linkedDocAttribute'] as String,
      lastError: json['lastError'] as String?,
    );
  }

  /// Converts JSON from device to a file. Only relevant attributs are included.
  Map<String, String?> toLocalJson() {
    return {
      'name': name,
      'storageFolderPath': storageFolderPath,
      'linkedDocPath': linkedDocPath,
      'linkedDocAttribute': linkedDocAttribute,
      'devicePath': devicePath,
      'lastError': lastError,
    };
  }
}
