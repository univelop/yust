import 'dart:math';

import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

/// Yust helpers
class YustHelpers {
  /// Mock the current time in UTC. Only use this in tests!!!
  static TZDateTime? mockNowUTC;

  /// Returns a random String with a specific length.
  ///
  /// Will include uppercase letters by default, set [includeCapitalLetters] to false
  /// to only include lowercase letters and numbers.
  String randomString({int length = 8, bool includeCapitalLetters = true}) {
    final rnd = Random();
    final chars =
        'abcdefghijklmnopqrstuvwxyz0123456789${includeCapitalLetters ? 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' : ''}'; // ignore: lines_longer_than_80_chars
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
  String? toQuotedFieldPath(String? fieldPath) =>
      fieldPath?.split('.').map((f) => '`$f`').join('.');

  /// Remove multiple keys from a map.
  void removeKeysFromMap(Map<String, dynamic> object, List<String> keys) {
    object.removeWhere((key, _) => keys.contains(key));
  }

  /// Clean a map, except of some keys.
  void preserveKeysInMap(Map<String, dynamic> object, List<String> keys) {
    object.removeWhere((key, _) => !keys.contains(key));
  }

  /// Get the value of a map by path.
  /// The path is a dot-separated path of keys, which may be escaped with backticks.
  ///
  /// Example:
  /// ```dart
  /// final value = YustHelpers().getValueByPath({'foo': {'bar': 'baz'}}, 'foo.bar');
  /// print(value); // baz
  /// ```
  dynamic getValueByPath(Map<String, dynamic> object, String path) {
    final keys = path.split('.').map((e) => e.replaceAll('`', ''));
    dynamic current = object;
    for (final key in keys) {
      if (current is Map<String, dynamic>) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Return a string representing [dateTime] in the German or English date
  /// format or another given [format].
  String formatDate(DateTime? dateTime,
      {String locale = 'de', String? format}) {
    if (dateTime == null) return '';

    switch (locale) {
      case 'en':
        return DateFormat(format ?? 'MM/dd/yyyy', locale)
            .format(utcToLocal(dateTime));
      case 'de':
      default:
        return DateFormat(format ?? 'dd.MM.yyyy', locale)
            .format(utcToLocal(dateTime));
    }
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
    final now =
        mockNowUTC != null ? utcToLocal(mockNowUTC!) : TZDateTime.now(local);
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
    final now = mockNowUTC ?? TZDateTime.now(UTC);
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
  DateTime addDaysOrMore(DateTime dateTime,
      {int days = 0, int months = 0, int years = 0}) {
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

  /// Returns true if the given [dateTime] includes a time.
  bool dateTimeIncludeTime(DateTime dateTime) {
    final localDateTime = utcToLocal(dateTime);
    return localDateTime.hour != 0 ||
        localDateTime.minute != 0 ||
        localDateTime.second != 0;
  }

  /// Use this function instead of [DateTime.difference]!
  ///
  /// We do this be because there is an issue in the dart js sdk see here:
  /// https://github.com/dart-lang/sdk/blob/main/sdk/lib/_internal/js_dev_runtime/patch/core_patch.dart#L442
  /// and here: https://github.com/srawlins/timezone/issues/57
  Duration dateDifference(DateTime? first, DateTime? second) => Duration(
      milliseconds: (first?.millisecondsSinceEpoch ?? 0) -
          (second?.millisecondsSinceEpoch ?? 0));

  /// Returns the DateTime at the [day] in the [month], with no day overflow.
  DateTime getDateAtDayOfMonth(int day, DateTime month) {
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0).day;
    return DateTime(
        month.year,
        month.month,
        min(day, lastDayOfMonth),
        month.hour,
        month.minute,
        month.second,
        month.millisecond,
        month.microsecond);
  }

  /// Adds [months] to the [date] with no day overflow in the next month.
  DateTime addMonthsWithoutOverflow(int months, DateTime date) {
    final newMonth = date.month + months;
    final newYear = date.year + (newMonth / 12).floor();
    final newMonthInYear = newMonth % 12;
    final lastDayOfMonth = DateTime(newYear, newMonthInYear + 1, 0).day;
    return DateTime(
        newYear,
        newMonthInYear,
        min(date.day, lastDayOfMonth),
        date.hour,
        date.minute,
        date.second,
        date.millisecond,
        date.microsecond);
  }

  /// Returns the DateTime at the day of the current month.
  DateTime getDateAtDayOfCurrentMonth(int day) {
    final now = localNow();
    return getDateAtDayOfMonth(day, now);
  }

  /// Rounds a number to the given amount of decimal places
  ///
  /// NOTE: This does multiply the number by 10^[fractionalDigits], so make sure
  /// the input number is smaller than 2^(53 - [fractionalDigits]) - 1$,
  /// e.g. for the default 8 digits: 35,184,372,088,831.
  /// See https://dart.dev/guides/language/numbers#precision for more details
  double roundToDecimalPlaces(num value, [int fractionalDigits = 8]) =>
      (value * pow(10, fractionalDigits + 1)).roundToDouble() /
      pow(10, fractionalDigits + 1);

  /// Returns a list of indexes of the found strings.
  /// The search looks for strings that **contain** the search [searchString].
  /// - if [ignoreCase] is true, the search is case insensitive
  /// - if [reorder] is false the order is preserved
  /// - if [reorder] is  true the result is sorted as follows:
  ///   0. if the search string is empty, the order is preserved
  ///   1. first exact matches
  ///   2. then matches at the beginning of the string (sorted alphabetically (not case sensitive))
  ///   3. then matches only contain the search string (sorted alphabetically (not case sensitive))
  List<int> searchString(
      {required List<String> strings,
      required String searchString,
      bool ignoreCase = true,
      bool reorder = true}) {
    final indices = List.generate(strings.length, (i) => i);
    if (searchString.isEmpty) return indices;

    final stringsToBeSearched =
        ignoreCase ? strings.map((s) => s.toLowerCase()).toList() : strings;
    final searchFor = ignoreCase ? searchString.toLowerCase() : searchString;

    final searchResult = indices
        .where((index) => stringsToBeSearched[index].contains(searchFor))
        .toList();

    if (!reorder) return searchResult;
    return searchResult
      ..sort((a, b) {
        final aString = stringsToBeSearched[a];
        final bString = stringsToBeSearched[b];
        final aStartsWith = aString.startsWith(searchFor);
        final bStartsWith = bString.startsWith(searchFor);
        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;
        return aString.compareTo(bString);
      });
  }
}
