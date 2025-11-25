import 'dart:io';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

part 'yust_file.g.dart';

typedef YustFileJson = Map<String, dynamic>;
typedef YustFilesJson = List<YustFileJson>;

/// A binary file handled by database and file storage.
/// A file is stored in Firebase Storage and linked to a document in the database.
/// For offline caching a file can also be stored on the device.
@JsonSerializable(createFactory: false)
class YustFile {
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? key;

  /// The name of the file with extension.
  String? name;

  /// The last modification time stamp.
  DateTime? modifiedAt;

  /// The URL to download the file.
  String? url;
  String hash;

  /// Date and time when the file was created in univelop.
  ///
  /// On mobile devices, this can also be the time the file was uploaded into device cache.
  DateTime? createdAt;

  /// The binary file. This attribute is used for iOS and Android. For web [bytes] is used instead.
  @JsonKey(includeFromJson: false, includeToJson: false)
  File? file;

  /// The binary file for web. For iOS and Android [file] is used instead.
  @JsonKey(includeFromJson: false, includeToJson: false)
  Uint8List? bytes;

  /// Path to the storage folder. Used for offline caching.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? storageFolderPath;

  /// Path to the file on the device. Used for offline caching.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? devicePath;

  /// Path to the Firebase document. Used for offline caching.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? linkedDocPath;

  /// Attribute of the Firebase document. Used for offline caching.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? linkedDocAttribute;

  /// stores the last error. Used in offline caching
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? lastError;

  /// Is true while uploading the file.
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool processing;

  /// True if image can be stored in cache. Each cached file needs a name
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get cacheable =>
      linkedDocPath != null && linkedDocAttribute != null && name != null;

  /// True if image is cached locally.
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get cached => devicePath != null;

  /// Creates a new file.
  ///
  /// Set [setCreatedAtToNow] to false, if it should not be set automatically.
  /// This is used for json deserializing so that old files do not get a new creation date.
  YustFile({
    this.key,
    this.name,
    this.modifiedAt,
    this.url,
    this.hash = '',
    this.file,
    this.bytes,
    this.devicePath,
    this.storageFolderPath,
    this.linkedDocPath,
    this.linkedDocAttribute,
    this.processing = false,
    this.lastError,
    this.createdAt,
    bool setCreatedAtToNow = true,
  }) {
    if (setCreatedAtToNow) {
      createdAt ??= DateTime.now();
    }
  }

  /// Converts the file to JSON for Firebase. Only relevant attributes are converted.
  factory YustFile.fromJson(Map<String, dynamic> json) {
    // This is implemented as a custom function so that createdAt will not be set for deserialized files.
    return YustFile(
      name: json['name'] as String?,
      modifiedAt: json['modifiedAt'] == null
          ? null
          : json['modifiedAt'] is DateTime
          ? json['modifiedAt'] as DateTime
          : DateTime.parse(json['modifiedAt'] as String),
      url: json['url'] as String?,
      hash: json['hash'] as String? ?? '',
      createdAt: json['createdAt'] == null
          ? null
          : json['createdAt'] is DateTime
          ? json['createdAt'] as DateTime
          : DateTime.parse(json['createdAt'] as String),
      setCreatedAtToNow: false,
    );
  }

  /// Type identifier for this class
  ///
  /// Used for local caching on mobile devices
  static String type = 'YustFile';

  /// Converts JSON from Firebase to a file. Only relevant attributes are included.
  Map<String, dynamic> toJson() => _$YustFileToJson(this);

  void update(YustFile file) {
    url = file.url;
    name = file.name;
    hash = file.hash;
    createdAt = file.createdAt;
  }

  /// Converts the file to JSON for local device. Only relevant attributes are converted.
  ///
  /// This is used for offline file handling only (Caching on mobile devices)
  factory YustFile.fromLocalJson(Map<String, dynamic> json) {
    return YustFile(
      name: json['name'] as String,
      storageFolderPath: json['storageFolderPath'] as String,
      devicePath: json['devicePath'] as String,
      linkedDocPath: json['linkedDocPath'] as String,
      linkedDocAttribute: json['linkedDocAttribute'] as String,
      lastError: json['lastError'] as String?,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      setCreatedAtToNow: false,
    );
  }

  /// Converts JSON from device to a file. Only relevant attributes are included.
  ///
  /// This is used for offline file handling only (Caching on mobile devices)
  Map<String, String?> toLocalJson() {
    if (name == null) {
      throw ('Error: Each cached file needs a name. Should be unique for each path!');
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
      'devicePath': devicePath,
      'lastError': lastError,
      'modifiedAt': modifiedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'type': type,
    };
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'name':
        return name;
      case 'hash':
        return hash;
      case 'url':
        return url;
      case 'createdAt':
        return createdAt;
      default:
        throw ArgumentError();
    }
  }

  bool isValid() {
    return name != null && name != '' && url != null && url != '';
  }

  String getFileNameWithoutExtension() {
    if (name == null) {
      return '';
    }

    final pathParts = name!.split('.');
    if (pathParts.length > 1) {
      pathParts.removeLast();
    }
    return pathParts.join('.');
  }

  String getFilenameExtension() {
    if (name == null) {
      return '';
    }

    return name!.contains('.') ? name!.split('.').last : '';
  }
}
