extension DateTimeExtension on DateTime {
  /// Returns an ISO-8601 full-precision extended format representation with an offset.
  String toIso8601StringWithOffset() {
    var isoDate = toIso8601String();
    if (isUtc) {
      return isoDate;
    } else {
      // Because dart only knows the utc timezone and the local timezone,
      // we convert the date to UTC. The toIso8601String will automatically append a 'Z',
      // to signify the date string is a UTC date.
      // We can't use something like timeZoneOffset, because this doesn't get populated
      // for parsed dates (only locally created dates). And because we don't know if
      // other clients like the backend are in the same local time,
      // UTC is the only option.
      return toUtc().toIso8601String();
    }
  }

  static String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }
}
