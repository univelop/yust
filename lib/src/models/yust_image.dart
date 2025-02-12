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
    this.location,
  });

  factory YustImage.fromJson(Map<String, dynamic> json) =>
      _$YustImageFromJson(json);

  YustGeoLocation? location;

  @override
  Map<String, String?> toJson() =>
      Map<String, String?>.from(_$YustImageToJson(this));
}
