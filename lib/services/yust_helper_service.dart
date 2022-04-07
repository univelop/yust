import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class YustHelperService {
  /// Does unfocus the current focus node.
  void unfocusCurrent(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  /// Does not return null.
  String formatDate(DateTime? dateTime, {String? format}) {
    if (dateTime == null) return '';

    var formatter = DateFormat(format ?? 'dd.MM.yyyy');
    return formatter.format(dateTime.toLocal());
  }

  /// Does not return null.
  String formatTime(DateTime? dateTime, {String? format}) {
    if (dateTime == null) return '';

    var formatter = DateFormat(format ?? 'HH:mm');
    return formatter.format(dateTime.toLocal());
  }

  /// Creates a string formatted just as the [YustDoc.createdAt] property is.
  String toStandardDateTimeString(DateTime dateTime) =>
      dateTime.toIso8601String();

  /// Returns null if the string cannot be parsed.
  DateTime? fromStandardDateTimeString(String dateTimeString) =>
      DateTime.tryParse(dateTimeString);

  String randomString({int length = 8}) {
    final rnd = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    var result = '';
    for (var i = 0; i < length; i++) {
      result += chars[rnd.nextInt(chars.length)];
    }
    return result;
  }
}
