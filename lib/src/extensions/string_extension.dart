extension StringExtension on String {
  /// Returns true if the string is representing an ISO 8601 Datetime.
  bool get isIso8601String {
    final iso8601Regex = RegExp(
        r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?(?:Z|[+-]\d{2}:?\d{2})?$');
    return iso8601Regex.hasMatch(this);
  }

  String toCapitalized() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}
