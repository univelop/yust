/// ServerNow is a DateTime extension that returns the current date and time
/// and uses a FieldValue.serverTimestamp() for the server.
class ServerNow extends DateTime {
  /// Is used to identify a ServerNow object in a JSON string.
  static const String serverNowString = 'SERVER_NOW_Gr9EpNIetFA3wmC2';

  ServerNow() : super.now();

  @override
  String toIso8601String() {
    return serverNowString;
  }
}

extension ServerNowExtension on String {
  /// Returns true if the string is a ServerNow object.
  bool get isServerNow => this == ServerNow.serverNowString;
}
