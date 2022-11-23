import 'dart:math';

import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

/// Yust helpers
class YustHelpers {
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
}
