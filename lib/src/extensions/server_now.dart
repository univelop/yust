/// ServerNow is a DateTime extension that returns the current date and time
/// and uses a FieldValue.serverTimestamp() for the server.
class ServerNow extends DateTime {
  ServerNow() : super.now();
}
