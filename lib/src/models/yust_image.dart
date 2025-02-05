import 'package:json_annotation/json_annotation.dart';
import 'yust_file.dart';
import 'yust_geo_location.dart';

part 'yust_image.g.dart';

@JsonSerializable()
class YustImage extends YustFile {
  YustImage({super.name, super.url, this.geoLocation, String? hash})
      : super(hash: hash ?? '');
  factory YustImage.fromJson(Map<String, dynamic> json) =>
      _$YustImageFromJson(json);

  YustGeoLocation? geoLocation;

  @override
  Map<String, String?> toJson() =>
      Map<String, String?>.from(_$YustImageToJson(this));
}
