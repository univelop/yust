import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../yust.dart';

part 'yust_file.g.dart';

typedef YustFileJson = Map<String, dynamic>;
typedef YustFilesJson = List<YustFileJson>;

/// The size of the thumbnail.
enum YustFileThumbnailSize {
  normal;

  /// Converts a JSON string to a [YustFileThumbnailSize].
  ///
  /// If the size is not found, [YustFileThumbnailSize.normal] is returned.
  static YustFileThumbnailSize fromJson(String size) =>
      YustFileThumbnailSize.values.firstWhereOrNull((e) => e.name == size) ??
      YustFileThumbnailSize.normal;

  /// Converts a [YustFileThumbnailSize] to a JSON string.
  String toJson() => name;
}

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

  @Deprecated(
    'Url is deprecated and will soon be null for valid files.'
    'Specify a path instead and use getOriginalUrl() or getThumbnailUrl() to get temporary URLs.',
  )
  /// The URL to download the file.
  String? url;

  /// The md5 hash of the file.
  String hash;

  /// Date and time when the file was created in univelop.
  ///
  /// On mobile devices, this can also be the time the file was uploaded into device cache.
  DateTime? createdAt;

  /// The path to the file in the storage.
  String? path;

  /// The thumbnails of the file.
  ///
  /// Map of thumbnail size to path in the storage.
  ///
  /// e.g. {[YustFileThumbnailSize.normal]: 'thumbnails/small/image.webp'}
  Map<YustFileThumbnailSize, String>? thumbnails;

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

  /// True if a thumbnail should be created.
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool? createThumbnail;

  /// True if the files should be stored as a Map of hash and file
  /// inside the linked document.
  ///
  /// By default, files will be stored as a list (simple array)
  /// or individual files sometimes directly as a map
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool? linkedDocStoresFilesAsMap;

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
    this.createThumbnail,
    this.linkedDocStoresFilesAsMap,
    this.createdAt,
    this.path,
    this.thumbnails,
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
      path: json['path'] as String?,
      thumbnails: (json['thumbnails'] as Map?)?.map(
        (key, value) =>
            MapEntry(YustFileThumbnailSize.fromJson(key), value as String),
      ),
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
    // ignore: deprecated_member_use_from_same_package
    url = file.url;
    name = file.name;
    hash = file.hash;
    createdAt = file.createdAt;
    path = file.path;
    thumbnails = file.thumbnails;
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
      createThumbnail: json['createThumbnail'] == 'true',
      linkedDocStoresFilesAsMap: json['linkedDocStoresFilesAsMap'] == 'true',
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      path: json['path'] as String?,
      thumbnails: json['thumbnails'] != null
          ? (jsonDecode(json['thumbnails'] as String) as Map).map(
              (key, value) => MapEntry(
                YustFileThumbnailSize.fromJson(key),
                value as String,
              ),
            )
          : null,

      setCreatedAtToNow: false,
    );
  }

  /// Converts JSON from device to a file. Only relevant attributes are included.
  ///
  /// This is used for offline file handling only (Caching on mobile devices)
  Map<String, String?> toLocalJson() {
    if (name == null) {
      throw YustException(
        'Error: Each cached file needs a name. Should be unique for each path!',
      );
    }
    if (devicePath == null) {
      throw YustException('Error: Device Path has to be a String.');
    }
    if (storageFolderPath == null) {
      throw YustException(
        'Error: StorageFolderPath has to be set for a successful upload.',
      );
    }
    if (linkedDocPath == null || linkedDocAttribute == null) {
      throw YustException(
        'Error: linkedDocPath and linkedDocAttribute have to be set for a successful upload.',
      );
    }
    return {
      'name': name,
      'storageFolderPath': storageFolderPath,
      'linkedDocPath': linkedDocPath,
      'linkedDocAttribute': linkedDocAttribute,
      'devicePath': devicePath,
      'lastError': lastError,
      'createThumbnail': (createThumbnail ?? false).toString(),
      'linkedDocStoresFilesAsMap': (linkedDocStoresFilesAsMap ?? false)
          .toString(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'type': type,
      'path': path,
      'thumbnails': thumbnails != null ? jsonEncode(thumbnails) : null,
    };
  }

  /// Creates a new file with the same properties but with a new URL.
  YustFile copyWithUrl(String? url) => YustFile(
    key: key,
    name: name,
    modifiedAt: modifiedAt,
    url: url,
    hash: hash,
    file: file,
    bytes: bytes,
    devicePath: devicePath,
    storageFolderPath: storageFolderPath,
    linkedDocPath: linkedDocPath,
    linkedDocAttribute: linkedDocAttribute,
    processing: processing,
    lastError: lastError,
    createThumbnail: createThumbnail,
    createdAt: createdAt,
    path: path,
    thumbnails: thumbnails,
    setCreatedAtToNow: false,
  );

  dynamic operator [](String key) {
    switch (key) {
      case 'name':
        return name;
      case 'hash':
        return hash;
      case 'url':
        // ignore: deprecated_member_use_from_same_package
        return url;
      case 'createdAt':
        return createdAt;
      case 'path': // Path and thumbnails should not be accessible
      case 'thumbnails':
      default:
        throw ArgumentError();
    }
  }

  /// Checks if the file has a valid name and url or path.
  bool isValid() =>
      name != null &&
      name != '' &&
      // ignore: deprecated_member_use_from_same_package
      ((url != null && url != '') || (path != null && path != ''));

  /// Returns the file name without the extension.
  ///
  /// e.g. "image.png" -> "image"
  /// Returns an empty string if the file name is null.
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

  /// Returns the extension of the file.
  ///
  /// e.g. "image.png" -> "png"
  /// Returns an empty string if the file name is null or has no extension.
  String getFilenameExtension() {
    if (name == null) {
      return '';
    }

    return name!.contains('.') ? name!.split('.').last : '';
  }

  /// Returns true if this file has a thumbnail
  bool get hasThumbnail => thumbnails?.isNotEmpty ?? false;

  /// Returns the original URL of the file.
  ///
  /// Tries to build the URL with the signed URL part.
  // ignore: deprecated_member_use_from_same_package
  /// Falls back to the [url] if thats not possible.
  String? getOriginalUrl() {
    final baseUrl = Yust.fileAccessService.originalCdnBaseUrl;
    final grant = Yust.fileAccessService.getGrantForFile(this);

    // ignore: deprecated_member_use_from_same_package
    if (baseUrl == null || grant == null || path == null) return url;

    return '$baseUrl$path?${grant.originalSignedUrlPart}';
  }

  /// Returns the thumbnail URL of the file.
  ///
  /// Returns null if any configuration is missing
  /// and the url cannot be built.
  ///
  /// Optionally override [size] to get a different thumbnail size.
  String? getThumbnailUrl({
    YustFileThumbnailSize size = YustFileThumbnailSize.normal,
  }) {
    final baseUrl = Yust.fileAccessService.thumbnailCdnBaseUrl;
    final grant = Yust.fileAccessService.getGrantForFile(this);

    if (baseUrl == null || grant == null || !hasThumbnail) return null;
    final thumbnailPath = thumbnails![size];

    return '$baseUrl$thumbnailPath?${grant.thumbnailSignedUrlPart}';
  }
}
