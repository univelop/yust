import 'dart:math';

import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

import 'google_cloud_cdn_helper.dart';

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
        'abcdefghijklmnopqrstuvwxyz0123456789${includeCapitalLetters ? 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' : ''}';
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
  String formatDate(
    DateTime? dateTime, {
    String locale = 'de',
    String? format,
  }) {
    if (dateTime == null) return '';

    switch (locale) {
      case 'en':
        return DateFormat(
          format ?? 'MM/dd/yyyy',
          locale,
        ).format(utcToLocal(dateTime));
      case 'de':
      default:
        return DateFormat(
          format ?? 'dd.MM.yyyy',
          locale,
        ).format(utcToLocal(dateTime));
    }
  }

  /// Return a string representing [dateTime] in the German time format or another given [format].
  String formatTime(DateTime? dateTime, {String? format}) {
    if (dateTime == null) return '';

    var formatter = DateFormat(format ?? 'HH:mm');
    return formatter.format(utcToLocal(dateTime));
  }

  /// Returns the current date and time in the local timezone.
  ///
  /// Set [minuteGranularity] to true to return the current date and time with
  /// minute granularity. If set, you cannot specify a value for [second],
  /// [millisecond] or [microsecond].
  DateTime localNow({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
    bool minuteGranularity = false,
  }) {
    assert(
      minuteGranularity == false ||
          (second == null && millisecond == null && microsecond == null),
      'minuteGranularity is only allowed if second, millisecond and microsecond are null',
    );

    final now = mockNowUTC != null
        ? utcToLocal(mockNowUTC!)
        : TZDateTime.now(local);
    return TZDateTime.local(
      year ?? now.year,
      month ?? now.month,
      day ?? now.day,
      hour ?? now.hour,
      minute ?? now.minute,
      minuteGranularity ? 0 : (second ?? now.second),
      minuteGranularity ? 0 : (millisecond ?? now.millisecond),
      minuteGranularity ? 0 : (microsecond ?? now.microsecond),
    );
  }

  /// Returns the current date in the local timezone.
  DateTime localToday() =>
      localNow(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

  /// Returns the current date and time in UTC.
  DateTime utcNow({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
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

  /// Removes any local time from the given [dateTime] by converting the given utc date time to local,
  /// removing the time part and converting back to utc.
  DateTime clearTime(DateTime dateTime) {
    final localDateTime = dateTime.isUtc ? utcToLocal(dateTime) : dateTime;

    return localToUtc(
      DateTime(localDateTime.year, localDateTime.month, localDateTime.day),
    );
  }

  /// adds a Duration that is more that 24 hours
  /// this works with time shifts like daylight saving time
  DateTime addDaysOrMore(
    DateTime dateTime, {
    int days = 0,
    int months = 0,
    int years = 0,
  }) {
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
          dateTime.microsecond,
        ).toUtc();

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
    milliseconds:
        (first?.millisecondsSinceEpoch ?? 0) -
        (second?.millisecondsSinceEpoch ?? 0),
  );

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
      month.microsecond,
    );
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
      date.microsecond,
    );
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
  List<int> searchString({
    required List<String> strings,
    required String searchString,
    bool ignoreCase = true,
    bool reorder = true,
  }) {
    final indices = List.generate(strings.length, (i) => i);
    if (searchString.isEmpty) return indices;

    final stringsToBeSearched = ignoreCase
        ? strings.map((s) => s.toLowerCase()).toList()
        : strings;
    final searchFor = ignoreCase ? searchString.toLowerCase() : searchString;

    final searchResult = indices
        .where((index) => stringsToBeSearched[index].contains(searchFor))
        .toList();

    if (!reorder) return searchResult;
    return searchResult..sort((a, b) {
      final aString = stringsToBeSearched[a];
      final bString = stringsToBeSearched[b];
      final aStartsWith = aString.startsWith(searchFor);
      final bStartsWith = bString.startsWith(searchFor);
      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;
      return aString.compareTo(bString);
    });
  }

  /// Formats a number to a string.
  /// The number is rounded to [decimalDigitCount] decimal places
  /// and optionally padded with zeros if [padDecimalDigits] is true.
  /// If [thousandsSeparator] is true, the number is formatted with a thousands separator.
  /// Use [locale] to specify the thousands separator and decimal separator.
  /// The number is padded with zeros to the left to reach at least [wholeDigitCount] whole digits.
  String numToString(
    num number, {
    bool thousandsSeparator = false,
    int wholeDigitCount = 1,
    int decimalDigitCount = 2,
    bool padDecimalDigits = false,
    String locale = 'de-DE',
    String? unit,
  }) {
    final formatter = NumberFormat.decimalPattern(locale)
      ..significantDigitsInUse
      ..minimumIntegerDigits = wholeDigitCount
      ..maximumFractionDigits = decimalDigitCount;
    if (padDecimalDigits) {
      formatter.minimumFractionDigits = decimalDigitCount;
    }
    if (!thousandsSeparator) {
      formatter.turnOffGrouping();
    }
    return unit == null || unit.isEmpty
        ? formatter.format(number)
        : '${formatter.format(number)} $unit';
  }

  /// Parse a string to a number.
  /// If [precision] is null, the number is parsed as is.
  /// If [precision] is 0, the number is rounded to the nearest integer.
  /// If [precision] is given, the number is rounded to exactly [precision] decimal places.
  /// Use [locale] to specify the thousands separator and decimal separator.
  num? stringToNumber(String text, {int? precision, String locale = 'de-DE'}) {
    if (text.isEmpty) return null;
    final format = NumberFormat.decimalPattern(locale);
    try {
      final number = format.parse(text);
      if (precision == null) {
        return number;
      }
      if (precision == 0) {
        return number.round();
      }
      num mod = pow(10.0, precision);
      return ((number * mod).round().toDouble() / mod);
    } catch (e) {
      return null;
    }
  }

  /// Creates a proper Content-Disposition header value with UTF-8 encoded filename
  String createContentDisposition(String filename) =>
      'inline; filename*=UTF-8\'\'${Uri.encodeComponent(filename)}';

  /// Creates a signed URL for a file at the given [path] and [name].
  /// The [validFor] parameter limits the validity of the URL.
  /// [cdnBaseUrl] example: "https://cdn.example.com"
  /// [cdnKeyName] is the key name configured on the backend.
  /// [cdnKeyBase64] is the base64-encoded signing key value.
  String createSignedUrlForFile({
    required String path,
    required String name,
    required Duration validFor,
    required String cdnBaseUrl,
    required String cdnKeyName,
    required String cdnKeyBase64,
    Map<String, String>? additionalQueryParams,
  }) {
    final helper = GoogleCloudCdnHelper(
      baseUrl: cdnBaseUrl,
      keyName: cdnKeyName,
      keyBase64: cdnKeyBase64,
    );
    return helper.signFilePath(
      objectPath: '$path/$name',
      validFor: validFor,
      additionalQueryParams: additionalQueryParams,
    );
  }

  /// Creates a signed URL for a folder at the given [path], using URLPrefix signing.
  /// The returned URL can be used (and its query string reused) to access
  /// any file under that folder while it’s valid.
  String createSignedUrlForFolder({
    required String path,
    required Duration validFor,
    required String cdnBaseUrl,
    required String cdnKeyName,
    required String cdnKeyBase64,
  }) {
    final helper = GoogleCloudCdnHelper(
      baseUrl: cdnBaseUrl,
      keyName: cdnKeyName,
      keyBase64: cdnKeyBase64,
    );
    return helper.signPrefix(prefixPath: path, validFor: validFor);
  }
}
