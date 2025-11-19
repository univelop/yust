import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'yust_file.dart';
import 'yust_geo_location.dart';

part 'yust_image.g.dart';

@JsonSerializable()
class YustImage extends YustFile {
  YustImage({
    super.key,
    super.name,
    super.modifiedAt,
    super.url,
    super.hash,
    super.file,
    super.bytes,
    super.devicePath,
    super.storageFolderPath,
    super.linkedDocPath,
    super.linkedDocAttribute,
    super.processing = false,
    super.lastError,
    super.createdAt,
    super.path,
    super.thumbnails,
    this.location,
  });

  YustGeoLocation? location;

  /// Creates a new image from a file.
  factory YustImage.fromYustFile(YustFile file) => file is YustImage
      ? file
      : YustImage(
          key: file.key,
          name: file.name,
          modifiedAt: file.modifiedAt,
          url: file.url,
          hash: file.hash,
          file: file.file,
          bytes: file.bytes,
          devicePath: file.devicePath,
          storageFolderPath: file.storageFolderPath,
          linkedDocPath: file.linkedDocPath,
          linkedDocAttribute: file.linkedDocAttribute,
          processing: file.processing,
          lastError: file.lastError,
          createdAt: file.createdAt,
          path: file.path,
          thumbnails: file.thumbnails,
        );

  /// Create a list of images from a list of files
  static List<YustImage> fromYustFiles(List<YustFile> files) =>
      files.map((file) => YustImage.fromYustFile(file)).toList();

  factory YustImage.fromJson(Map<String, dynamic> json) =>
      _$YustImageFromJson(json);

  /// Converts JSON from device to a file. Only relevant attributes are included.
  ///
  /// This is used for offline file handling only (Caching on mobile devices)
  factory YustImage.fromLocalJson(Map<String, dynamic> json) {
    return YustImage.fromYustFile(YustFile.fromLocalJson(json))
      ..location = json['location'] != null
          ? YustGeoLocation.fromJson(
              Map<String, dynamic>.from(jsonDecode(json['location'])),
            )
          : null;
  }

  /// Type identifier for this class
  ///
  /// Used for local caching on mobile devices
  static String type = 'YustImage';

  /// Converts the file to JSON for local device. Only relevant attributes are converted.
  ///
  /// This is used for offline file handling only (Caching on mobile devices)
  @override
  Map<String, String?> toLocalJson() {
    return super.toLocalJson()..addAll({
      'location': location != null ? jsonEncode(location?.toJson()) : null,
      'type': type,
    });
  }

  @override
  dynamic operator [](String key) {
    switch (key) {
      case 'location':
        return location;
      default:
        super[key];
    }
  }

  @override
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.from(_$YustImageToJson(this));
}
