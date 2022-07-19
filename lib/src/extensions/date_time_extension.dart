extension DateTimeExtension on DateTime {
  /// Returns an ISO-8601 full-precision extended format representation with an offset.
  String toIso8601StringWithOffset() {
    var isoDate = toIso8601String();
    if (isUtc) {
      return isoDate;
    } else {
      final hours = timeZoneOffset.inHours;
      var offset = hours < 0 ? '-' : '+';
      offset +=
          '${_twoDigits(hours)}:${_twoDigits(timeZoneOffset.inMinutes % hours)}';
      return isoDate + offset;
    }
  }

  static String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }
}
