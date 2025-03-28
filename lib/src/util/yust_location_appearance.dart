/// The appearance of a geo location
enum YustLocationAppearance {
  decimalDegree('decimal_degree'),
  degreeMinutesSeconds('degree_minutes_seconds');

  const YustLocationAppearance(this._jsonKey);
  final String _jsonKey;

  /// Converts a JSON string to the appearance
  ///
  /// Defaults to [YustLocationAppearance.decimalDegree]
  static YustLocationAppearance fromJson(String? value) =>
      YustLocationAppearance.values.firstWhere(
        (e) => e._jsonKey == value,
        orElse: () => YustLocationAppearance.decimalDegree,
      );

  /// Converts the appearance to a JSON string
  String toJson() => _jsonKey;
}
