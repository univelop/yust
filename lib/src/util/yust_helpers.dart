import 'dart:math';

import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

/// Yust helpers
class YustHelpers {
  /// Mock the current time in UTC. Only use this in tests!!!
  static TZDateTime? mockNowUTC;

  /// Returns a random String with a specific length.
  String randomString({int length = 8}) {
    final rnd = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    var result = '';
    for (var i = 0; i < length; i++) {
      result += chars[rnd.nextInt(chars.length)];
    }
    return result;
  }

  /// Returns a quoted field path.
  ///
  /// Because the Firestore REST-Api (used in the background) can't handle
  /// attributes starting with numbers, e.g. 'foo.0bar', we need to escape the
  /// path-parts by using '´': '`foo`.`0bar`'.
  String toQuotedFieldPath(String fieldPath) =>
      fieldPath.split('.').map((f) => '`$f`').join('.');

  /// Remove multiple keys from a map.
  void removeKeysFromMap(Map<String, dynamic> object, List<String> keys) {
    object.removeWhere((key, _) => keys.contains(key));
  }

  /// Clean a map, except of some keys.
  void preserveKeysInMap(Map<String, dynamic> object, List<String> keys) {
    object.removeWhere((key, _) => !keys.contains(key));
  }

  /// Return a string representing [dateTime] in the German date format or another given [format].
  String formatDate(DateTime? dateTime, {String? format}) {
    if (dateTime == null) return '';
    var formatter = DateFormat(format ?? 'dd.MM.yyyy');
    return formatter.format(utcToLocal(dateTime));
  }

  /// Return a string representing [dateTime] in the German time format or another given [format].
  String formatTime(DateTime? dateTime, {String? format}) {
    if (dateTime == null) return '';

    var formatter = DateFormat(format ?? 'HH:mm');
    return formatter.format(utcToLocal(dateTime));
  }

  DateTime localNow(
      {int? year,
      int? month,
      int? day,
      int? hour,
      int? minute,
      int? second,
      int? millisecond,
      int? microsecond}) {
    if (mockNowUTC != null) return utcToLocal(mockNowUTC!);
    final now = TZDateTime.now(local);
    return TZDateTime.local(
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

  DateTime utcNow(
      {int? year,
      int? month,
      int? day,
      int? hour,
      int? minute,
      int? second,
      int? millisecond,
      int? microsecond}) {
    if (mockNowUTC != null) return mockNowUTC!;
    final now = TZDateTime.now(UTC);
    return TZDateTime.utc(
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

  /// adds a Duration that is more that 24 hours
  /// this works with time shifts like daylight saving time
  DateTime addDaysOrMore(DateTime dateTime, {int days = 0, int months = 0, int years = 0}) {
    final localTime = dateTime.isUtc ? utcToLocal(dateTime) : dateTime;
    final newTime = DateTime(
      localTime.year + years,
      localTime.month + months,
      localTime.day + days,
      localTime.hour,
      localTime.minute,
      localTime.second,
      localTime.millisecond,
      localTime.microsecond,
    );
    return dateTime.isUtc ? localToUtc(newTime) : newTime;
  }

  DateTime utcToLocal(DateTime dateTime) =>
      TZDateTime.from(dateTime, UTC).toLocal();
  DateTime localToUtc(DateTime dateTime) => dateTime.isUtc
      ? dateTime
      : TZDateTime.local(
              dateTime.year,
              dateTime.month,
              dateTime.day,
              dateTime.hour,
              dateTime.minute,
              dateTime.second,
              dateTime.millisecond,
              dateTime.microsecond)
          .toUtc();

  DateTime? tryUtcToLocal(DateTime? dateTime) =>
      dateTime == null ? null : utcToLocal(dateTime);
  DateTime? tryLocalToUtc(DateTime? dateTime) =>
      dateTime == null ? null : localToUtc(dateTime);

  /// Use this function instead of [DateTime.difference]!
  ///
  /// We do this be because there is an issue in the dart js sdk see here:
  /// https://github.com/dart-lang/sdk/blob/main/sdk/lib/_internal/js_dev_runtime/patch/core_patch.dart#L442
  /// and here: https://github.com/srawlins/timezone/issues/57
  Duration dateDifference(DateTime? first, DateTime? second) => Duration(
      milliseconds: (first?.millisecondsSinceEpoch ?? 0) -
          (second?.millisecondsSinceEpoch ?? 0));

  /// Rounds a number to the given amount of decimal places
  ///
  /// NOTE: This does multiply the number by 10^[fractionalDigits], so make sure
  /// the input number is smaller than 2^(53 - [fractionalDigits]) - 1$,
  /// e.g. for the default 8 digits: 35,184,372,088,831.
  /// See https://dart.dev/guides/language/numbers#precision for more details
  double roundToDecimalPlaces(num value, [int fractionalDigits = 8]) =>
      (value * pow(10, fractionalDigits + 1)).roundToDouble() /
      pow(10, fractionalDigits + 1);
}
