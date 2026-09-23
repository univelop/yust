/// Reads a date out of a JSON map, whichever form it arrived in.
///
/// A document read straight from Firestore hands back a `DateTime`, while the
/// same document coming from the REST API, a cache or a test fixture carries
/// an ISO 8601 string. Every model that deserializes a date has to cope with
/// both, and each one used to spell the same three-way ternary out again.
DateTime? dateTimeFromJson(dynamic value) => switch (value) {
  null => null,
  final DateTime dateTime => dateTime,
  final String string => DateTime.parse(string),
  _ => throw FormatException('Cannot read a date from $value'),
};
