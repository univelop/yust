import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yust/util/object_helper.dart';

part 'yust_file.g.dart';

typedef YustFileJson = Map<String, dynamic>;
typedef YustFilesJson = List<YustFileJson>;

/// A binary file handled by database and file storage.
/// A file is stored in Firebase Storeage and linked to a document in the database.
/// For offline caching a file can also be stored on the device.

@JsonSerializable()
class YustFile {
  @JsonKey(ignore: true)
  Key? key;

  /// The name of the file with extension.
  String? name;

  /// The URL to download the file.
  String? url;
  String hash;

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

  /// when file uploading these data will be added
  @JsonKey(ignore: true)
  Map<String, dynamic>? additionalDocAttributeData;

  /// stores the last error. Used in offline caching
  @JsonKey(ignore: true)
  String? lastError;

  /// Is true while uploading the file.
  @JsonKey(ignore: true)
  bool processing;

  /// True if image can be stored in cache. Each cached file needs a name
  bool get cacheable =>
      linkedDocPath != null && linkedDocAttribute != null && name != null;

  /// True if image is cached locally.
  bool get cached => devicePath != null;

  YustFile({
    this.key,
    this.name,
    this.url,
    this.hash = '',
    this.file,
    this.bytes,
    this.devicePath,
    this.storageFolderPath,
    this.linkedDocPath,
    this.linkedDocAttribute,
    this.additionalDocAttributeData,
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
      additionalDocAttributeData:
          jsonDecode(json['additionalDocAttributeData']),
      lastError: json['lastError'] as String?,
    );
  }

  /// Converts JSON from device to a file. Only relevant attributs are included.
  Map<String, String?> toLocalJson() {
    if (name == null) {
      throw ('Error: Each cached file needs a name. Should be unique for each adress!');
    }
    if (devicePath == null) {
      throw ('Error: Device Path has to be a String.');
    }
    if (storageFolderPath == null) {
      throw ('Error: StorageFolderPath has to be set for a successful upload.');
    }
    if (linkedDocPath == null || linkedDocAttribute == null) {
      throw ('Error: linkedDocPath and linkedDocAttribute have to be set for a successful upload.');
    }
    return {
      'name': name,
      'storageFolderPath': storageFolderPath,
      'linkedDocPath': linkedDocPath,
      'linkedDocAttribute': linkedDocAttribute,
      'additionalDocAttributeData':
          jsonEncode(_DateTimeToString(additionalDocAttributeData)),
      'devicePath': devicePath,
      'lastError': lastError,
    };
  }

  Map<String, dynamic>? _DateTimeToString(Map<String, dynamic>? data) {
    if (data == null) {
      return data;
    }
    return TraverseObject.traverseObject(
      data,
      (currentNode) {
        return currentNode.value is DateTime
            ? currentNode.value.toIso8601String()
            : currentNode.value;
      },
    );
  }
}
