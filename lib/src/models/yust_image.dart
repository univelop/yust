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
    this.location,
  });

  YustGeoLocation? location;

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
        );

  /// Create a list of images from a list of files
  static List<YustImage> fromYustFiles(List<YustFile> files) =>
      files.map((file) => YustImage.fromYustFile(file)).toList();

  factory YustImage.fromJson(Map<String, dynamic> json) =>
      _$YustImageFromJson(json);

  /// Converts JSON from device to a file. Only relevant attributes are included.
  factory YustImage.fromLocalJson(Map<String, dynamic> json) {
    return YustImage.fromYustFile(YustFile.fromLocalJson(json))
      ..location = json['location'] != null
          ? YustGeoLocation.fromJson(
              Map<String, dynamic>.from(json['location']))
          : null;
  }

  /// Converts the file to JSON for local device. Only relevant attributes are converted.
  @override
  Map<String, String?> toLocalJson() {
    return super.toLocalJson()
      ..addAll({
        'location': location?.toJson().toString(),
        'type': 'YustImage',
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
  Map<String, String?> toJson() =>
      Map<String, String?>.from(_$YustImageToJson(this));
}
