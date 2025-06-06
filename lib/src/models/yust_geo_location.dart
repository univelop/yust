import 'package:coordinate_converter/coordinate_converter.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import '../util/yust_cardinal_direction.dart';
import '../util/yust_dms_coordinates.dart';
import '../util/yust_exception.dart';
import '../util/yust_location_appearance.dart';
import 'yust_address.dart';
part 'yust_geo_location.g.dart';

@JsonSerializable()
@immutable
class YustGeoLocation {
  /// Creates a new instance of [YustGeoLocation].
  ///
  /// [latitude] must be between -90 and 90.
  /// [longitude] must be between -180 and 180.
  YustGeoLocation({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.address,
  }) {
    if (latitude != null && (latitude! < -90 || latitude! > 90)) {
      throw YustInvalidCoordinatesException(
          'Latitude must be between -90 and 90', latitude, longitude);
    }
    if (longitude != null && (longitude! < -180 || longitude! > 180)) {
      throw YustInvalidCoordinatesException(
          'Longitude must be between -180 and 180', latitude, longitude);
    }
  }

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
      (address?.hasValue() ?? false) == true;

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

  /// Returns a user readable string representation of the current instance.
  ///
  /// Use [appearance] to set the appearance of the coordinates.
  String? toReadableString({
    YustLocationAppearance appearance = YustLocationAppearance.decimalDegree,
    String? degreeSymbol,
    String? northAbbreviation = 'N',
    String? southAbbreviation = 'S',
    String? westAbbreviation = 'W',
    String? eastAbbreviation = 'E',
  }) {
    final lat = formatLatitude(
        appearance: appearance,
        degreeSymbol: degreeSymbol,
        northAbbreviation: northAbbreviation,
        southAbbreviation: southAbbreviation);
    final long = formatLongitude(
      appearance: appearance,
      degreeSymbol: degreeSymbol,
      westAbbreviation: westAbbreviation,
      eastAbbreviation: eastAbbreviation,
    );

    return lat == null && long == null ? null : '$lat, $long';
  }

  /// Returns a user readable string of the latitude.
  String? formatLatitude({
    YustLocationAppearance appearance = YustLocationAppearance.decimalDegree,
    String? degreeSymbol,
    String? northAbbreviation = 'N',
    String? southAbbreviation = 'S',
  }) {
    if (latitude == null) return null;
    if (appearance == YustLocationAppearance.decimalDegree) {
      return NumberFormat('0.#######', 'en_US').format(latitude ?? 0);
    }

    final dmsCoordinates = toYustDmsCoordinates();
    final direction = {
          YustCardinalDirection.north: northAbbreviation,
          YustCardinalDirection.south: southAbbreviation,
        }[dmsCoordinates.latDirection] ??
        '';

    return "${dmsCoordinates.latDegrees}${degreeSymbol ?? '°'} ${dmsCoordinates.latMinutes}' ${dmsCoordinates.latSeconds?.toStringAsFixed(2)}"
        '" '
        '$direction';
  }

  /// Returns a user readable string of the longitude.
  String? formatLongitude({
    YustLocationAppearance appearance = YustLocationAppearance.decimalDegree,
    String? degreeSymbol,
    String? westAbbreviation = 'W',
    String? eastAbbreviation = 'E',
  }) {
    if (longitude == null) return null;
    if (appearance == YustLocationAppearance.decimalDegree) {
      return NumberFormat('0.######', 'en_US').format(longitude ?? 0);
    }

    final dmsCoordinates = toYustDmsCoordinates();
    final direction = {
          YustCardinalDirection.west: westAbbreviation,
          YustCardinalDirection.east: eastAbbreviation,
        }[dmsCoordinates.longDirection] ??
        '';

    return "${dmsCoordinates.longDegrees}${degreeSymbol ?? '°'} ${dmsCoordinates.longMinutes}' ${dmsCoordinates.longSeconds?.toStringAsFixed(2)}"
        '" '
        '$direction';
  }

  /// Creates a [YustDmsCoordinates] from a [YustGeoLocation].
  YustDmsCoordinates toYustDmsCoordinates() {
    try {
      final ddCoords = DDCoordinates(
        latitude: latitude ?? 0,
        longitude: longitude ?? 0,
      );
      final dmsCoords = ddCoords.toDMS();

      return YustDmsCoordinates(
        latDegrees: latitude != null ? dmsCoords.latDegrees : null,
        latMinutes: latitude != null ? dmsCoords.latMinutes : null,
        latSeconds: latitude != null ? dmsCoords.latSeconds : null,
        latDirection: latitude != null
            ? YustCardinalDirection.fromDirectionY(dmsCoords.latDirection)
            : null,
        longDegrees: longitude != null ? dmsCoords.longDegrees : null,
        longMinutes: longitude != null ? dmsCoords.longMinutes : null,
        longSeconds: longitude != null ? dmsCoords.longSeconds : null,
        longDirection: longitude != null
            ? YustCardinalDirection.fromDirectionX(dmsCoords.longDirection)
            : null,
      );
    } catch (_) {
      return YustDmsCoordinates();
    }
  }
}
