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
    final tzDateTime = TZDateTime.from(dateTime, UTC);

    var formatter = DateFormat(format ?? 'dd.MM.yyyy');
    return formatter.format(tzDateTime.toLocal());
  }

  /// Return a string representing [dateTime] in the German time format or another given [format].
  String formatTime(DateTime? dateTime, {String? format}) {
    if (dateTime == null) return '';
    final tzDateTime = TZDateTime.from(dateTime, UTC);

    var formatter = DateFormat(format ?? 'HH:mm');
    return formatter.format(tzDateTime.toLocal());
  }

  /// Convert a DateTime in a Timezone-aware TZDateTime
  /// We usually interpret parsed dates as local dates. But, if it was specifically set as UTC,
  /// we respect that as well
  TZDateTime? localDateToUtc(DateTime? dateTime) {
    if (dateTime == null) return null;
    return TZDateTime.from(dateTime, dateTime.isUtc ? UTC : local).toUtc();
  }

  TZDateTime? utcDateToLocal(DateTime? dateTime) {
    if (dateTime == null) return null;
    return TZDateTime.from(dateTime, UTC).toLocal();
  }

  TZDateTime nowLocal() {
    return TZDateTime.now(local);
  }

  TZDateTime createLocalDate(
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0]) {
    return TZDateTime.local(
        month, day, hour, minute, second, millisecond, microsecond);
  }
}
