import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'yust_address.dart';
part 'yust_geo_location.g.dart';

@JsonSerializable()
@immutable
class YustGeoLocation {
  const YustGeoLocation({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.address = const YustAddress(),
  });
  factory YustGeoLocation.withValueByKey(
    YustGeoLocation location,
    String key,
    dynamic value,
  ) {
    switch (key) {
      case 'latitude':
        return location.copyWithLatitude(value);
      case 'longitude':
        return location.copyWithLongitude(value);
      case 'accuracy':
        return location.copyWithAccuracy(value);
      case 'address':
        return location.copyWithAddress(value);
      case 'address_street':
        return location.copyWithAddress(
          (location.address ?? YustAddress()).copyWithStreet(value),
        );
      case 'address_number':
        return location.copyWithAddress(
          (location.address ?? YustAddress()).copyWithNumber(value),
        );
      case 'address_city':
        return location.copyWithAddress(
          (location.address ?? YustAddress()).copyWithCity(value),
        );
      case 'address_postcode':
        return location.copyWithAddress(
          (location.address ?? YustAddress()).copyWithPostcode(value),
        );
      case 'address_country':
        return location.copyWithAddress(
          (location.address ?? YustAddress()).copyWithCountry(value),
        );
      default:
        return location;
    }
  }
  factory YustGeoLocation.fromJson(Map<String, dynamic> json) =>
      _$YustGeoLocationFromJson(json);

  YustGeoLocation copyWithLatitude(double? value) => YustGeoLocation(
        latitude: value,
        longitude: longitude,
        accuracy: accuracy,
        address: address,
      );

  YustGeoLocation copyWithLongitude(double? value) => YustGeoLocation(
        latitude: latitude,
        longitude: value,
        accuracy: accuracy,
        address: address,
      );

  YustGeoLocation copyWithAccuracy(double? value) => YustGeoLocation(
        latitude: latitude,
        longitude: longitude,
        accuracy: value,
        address: address,
      );

  YustGeoLocation copyWithAddress(YustAddress value) => YustGeoLocation(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        address: value,
      );

  final double? latitude;

  final double? longitude;

  final double? accuracy;

  final YustAddress? address;

  bool hasValue() =>
      latitude != null ||
      longitude != null ||
      accuracy != null ||
      (address?.hasValue() ?? true) == true;

  dynamic operator [](String key) {
    switch (key) {
      case 'latitude':
        return latitude;
      case 'longitude':
        return longitude;
      case 'accuracy':
        return accuracy;
      case 'address':
        return address;
      default:
        throw ArgumentError();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is YustGeoLocation &&
      longitude == other.longitude &&
      latitude == other.latitude &&
      accuracy == other.accuracy &&
      address == other.address;

  @override
  int get hashCode => Object.hash(longitude, latitude, accuracy, address);

  Map<String, dynamic> toJson() => _$YustGeoLocationToJson(this);
}
