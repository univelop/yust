extension StringExtension on String {
  /// Returns true if the string is representing an ISO 8601 Datetime.
  bool get isIso8601String {
    final iso8601Regex = RegExp(
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?(?:Z|[+-]\d{2}:?\d{2})?$');
    return iso8601Regex.hasMatch(this);
  }

  String toCapitalized() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';

  /// Returns a truncated string.
  /// The max returned length of string is 'size'.
  /// If size is 0 or less or size greater than string length, then returns empty string.
  String truncate({int size = 10}) =>
      (size <= 0) || (size > length) ? '' : substring(0, size);
}
