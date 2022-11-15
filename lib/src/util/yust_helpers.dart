import 'dart:math';

import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

import '../../yust.dart';

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
    final tzDateTime = YustDateTime.fromUtc(dateTime);

    var formatter = DateFormat(format ?? 'dd.MM.yyyy');
    return formatter.format(tzDateTime.toLocal());
  }

  /// Return a string representing [dateTime] in the German time format or another given [format].
  String formatTime(DateTime? dateTime, {String? format}) {
    if (dateTime == null) return '';
    final tzDateTime = YustDateTime.fromUtc(dateTime);

    var formatter = DateFormat(format ?? 'HH:mm');
    return formatter.format(tzDateTime.toLocal());
  }
}
