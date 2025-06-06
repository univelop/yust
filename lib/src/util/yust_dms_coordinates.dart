import 'package:coordinate_converter/coordinate_converter.dart';

import '../../yust.dart';

/// Class to store DMS coordinates as nullable properties.
///
/// This class just stores form data and should not be used for any calculations
/// or further business logic.
class YustDmsCoordinates {
  /// Latitude degrees in [int].
  /// Latitude degrees must be between -90 and 90.
  int? latDegrees;

  /// Latitude minutes in [int].
  /// Latitude minutes must be between 0 and 59.
  int? latMinutes;

  /// Latitude seconds in [double].
  /// Latitude seconds must be between 0 and 59.
  double? latSeconds;

  /// Latitude direction in [YustCardinalDirection] enum.
  YustCardinalDirection? latDirection;

  /// Longitude minutes in [int].
  /// Longitude degrees must be between -180 and 180.
  int? longDegrees;

  /// Longitude minutes in [int].
  /// Longitude minutes must be between 0 and 59.
  int? longMinutes;

  /// Longitude seconds in [double].
  /// Longitude seconds must be between 0 and 59.
  double? longSeconds;

  /// Latitude direction in [YustCardinalDirection] enum.
  YustCardinalDirection? longDirection;

  YustDmsCoordinates({
    this.latDegrees,
    this.latMinutes,
    this.latSeconds,
    this.latDirection,
    this.longDegrees,
    this.longMinutes,
    this.longSeconds,
    this.longDirection,
  });

  /// Returns true if the coordinates are valid.
  ///
  /// Warning: Uses try-catch to determine if the coordinates are valid, should be used with caution.
  bool isValid() {
    try {
      final _ = toDMSCoordinates().toDD();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Converts [YustDmsCoordinates] to [YustGeoLocation].
  YustGeoLocation toYustGeoLocation() {
    try {
      final dmsCoords = toDMSCoordinates();
      final ddCoords = DDCoordinates.fromDMS(dmsCoords);

      return YustGeoLocation(
        latitude: ddCoords.latitude,
        longitude: ddCoords.longitude,
        accuracy: -1,
      );
    } catch (_) {
      return YustGeoLocation();
    }
  }

  /// Converts [YustDmsCoordinates] to [DMSCoordinates].
  DMSCoordinates toDMSCoordinates() {
    return DMSCoordinates(
      latDegrees: latDegrees ?? 0,
      latMinutes: latMinutes ?? 0,
      latSeconds: latSeconds ?? 0,
      latDirection: latDirection?.toDirectionY() ?? DirectionY.north,
      longDegrees: longDegrees ?? 0,
      longMinutes: longMinutes ?? 0,
      longSeconds: longSeconds ?? 0,
      longDirection: longDirection?.toDirectionX() ?? DirectionX.east,
    );
  }
}
