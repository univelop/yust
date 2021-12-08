import 'dart:io';
import 'dart:typed_data';

import 'package:yust/util/yust_serializable.dart';

/// A binary file handled by database and file storage.
/// A file is stored in Firebase Storeage and linked to a document in the database.
/// For offline caching a file can also be stored on the device.
class YustFile with YustSerializable {
  /// The name of the file with extension.
  String name;

  /// The URL to download the file.
  String? url;

  /// The binary file. This attibute is used for iOS and Android. For web [bytes] is used instead.
  File? file;

  /// The binary file for web. For iOS and Android [file] is used instead.
  Uint8List? bytes;

  /// Path to the storage folder. Used for offline caching.
  String? storageFolderPath;

  /// Path to the file on the device. Used for offline caching.
  String? devicePath;

  /// Path to the Firebase document. Used for offline caching.
  String? linkedDocPath;

  /// Attribute of the Firebase document. Used for offline caching.
  String? linkedDocAttribute;

  /// stores the last error. Used in offline caching
  String? lastError;

  /// Is true while uploading the file.
  bool processing;

  /// True if image can be stored in cache.
  bool get cacheable => linkedDocPath != null && linkedDocAttribute != null;

  /// True if image is cached locally.
  bool get cached => devicePath != null;

  YustFile({
    required this.name,
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
  factory YustFile.fromJson(Map<String, dynamic> json) {
    return YustFile(
      name: json['name'] as String,
      url: json['url'] as String?,
    );
  }

  /// Converts JSON from Firebase to a file. Only relevant attributs are included.
  Map<String, String?> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }

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

  static Map<String, String?>? fileToJson(YustFile? file) {
    return file?.toJson();
  }
}
