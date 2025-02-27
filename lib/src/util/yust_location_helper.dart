import 'package:intl/intl.dart';

class YustLocationHelper {
  String _formatCoordinateToDMS(double decimalDegree, String degreeSymbol) {
    int degrees = decimalDegree.truncate();
    double decimalMinutes = (decimalDegree - degrees) * 60;
    int minutes = decimalMinutes.truncate();
    double seconds = (decimalMinutes - minutes) * 60;

    return '$degrees$degreeSymbol $minutes\' ${seconds.toStringAsFixed(2)}"';
  }

  /// Formats the given latitude to a string in DMS format
  ///
  /// Example: 48.858844 -> 48° 51' 31.84" N
  String formatLatitudeToDMS(double latitude, {String degreeSymbol = '°'}) {
    String latitudeDirection = latitude >= 0 ? 'N' : 'S';

    String latitudeDMS = _formatCoordinateToDMS(latitude.abs(), degreeSymbol);

    return '$latitudeDMS $latitudeDirection';
  }

  /// Formats the given longitude to a string in DMS format
  ///
  /// Example: 2.2943506 -> 2° 17' 39.67" E
  String formatLongitudeToDMS(double longitude, {String degreeSymbol = '°'}) {
    String longitudeDirection = longitude >= 0 ? 'E' : 'W';

    String longitudeDMS = _formatCoordinateToDMS(longitude.abs(), degreeSymbol);

    return '$longitudeDMS $longitudeDirection';
  }

  /// Formats the given coordinate to a string in decimal format
  String formatDecimalCoordinate(double coordinate) =>
      NumberFormat('0.######', 'en_US').format(coordinate);
}
