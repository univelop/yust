import 'package:timezone/timezone.dart';

/// An UTC-first TZDateTime-Superclass with a few helper methods.
/// It ignores the timezone of the device and just uses the timezone.local & timezone.UTC Timezones.
///
/// This isn't an extension, because extensions don't support static/constructor methods
class YustDateTime extends TZDateTime {
  /// Create an UTC date with the given values
  YustDateTime(int year,
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0])
      : super(UTC, year, month, day, hour, minute, second, millisecond,
            microsecond);

  /// Create an local date with the given values
  YustDateTime.local(int year,
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0])
      : super(local, year, month, day, hour, minute, second, millisecond,
            microsecond);

  /// Creates a YustDateTime with the current DateTime in local time
  /// You may pass additional overrides
  factory YustDateTime.localNow({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    final now = TZDateTime.now(local);
    return YustDateTime.local(
      year ?? now.year,
      month ?? now.month,
      day ?? now.day,
      hour ?? now.hour,
      minute ?? now.minute,
      second ?? now.second,
      millisecond ?? now.millisecond,
      microsecond ?? now.microsecond,
    );
  }

  /// Creates a YustDateTime with the current DateTime in UTC
  /// You may pass additional overrides
  factory YustDateTime.now({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    final now = TZDateTime.now(UTC);
    return YustDateTime(
      year ?? now.year,
      month ?? now.month,
      day ?? now.day,
      hour ?? now.hour,
      minute ?? now.minute,
      second ?? now.second,
      millisecond ?? now.millisecond,
      microsecond ?? now.microsecond,
    );
  }

  YustDateTime.fromUtc(DateTime other) : super.from(other, UTC);
  YustDateTime.fromLocal(DateTime other)
      : super.from(other, other.isUtc ? UTC : local);

  static YustDateTime? tryFromUtc(DateTime? other) =>
      other == null ? null : YustDateTime.fromUtc(other);
  static YustDateTime? tryFromLocal(DateTime? other) =>
      other == null ? null : YustDateTime.fromLocal(other);
}
