class YustLocationHelper {
  String _formatCoordinateToDMS(double decimalDegree) {
    int degrees = decimalDegree.truncate();
    double decimalMinutes = (decimalDegree - degrees) * 60;
    int minutes = decimalMinutes.truncate();
    double seconds = (decimalMinutes - minutes) * 60;

    return '$degrees° $minutes\' ${seconds.toStringAsFixed(2)}"';
  }

  /// Formats the given latitude to a string in DMS format
  ///
  /// Example: 48.858844 -> 48° 51' 31.84" N
  String formatLatitudeToDMS(double latitude) {
    String latitudeDirection = latitude >= 0 ? 'N' : 'S';

    String latitudeDMS = _formatCoordinateToDMS(latitude.abs());

    return '$latitudeDMS $latitudeDirection';
  }

  /// Formats the given longitude to a string in DMS format
  ///
  /// Example: 2.2943506 -> 2° 17' 39.67" E
  String formatLongitudeToDMS(double longitude) {
    String longitudeDirection = longitude >= 0 ? 'E' : 'W';

    String longitudeDMS = _formatCoordinateToDMS(longitude.abs());

    return '$longitudeDMS $longitudeDirection';
  }
}
