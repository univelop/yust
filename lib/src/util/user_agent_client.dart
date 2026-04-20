import 'package:http/http.dart' as http;

/// An HTTP client wrapper that sets a custom User-Agent header
/// on every outgoing request.
///
/// This makes the User-Agent visible in Google Cloud Audit Logs
/// via `requestMetadata.callerSuppliedUserAgent`.
class UserAgentClient extends http.BaseClient {
  UserAgentClient(this.inner, {required String userAgent})
    : _userAgent = userAgent;

  final http.Client inner;
  final String _userAgent;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final existing = request.headers['User-Agent'];
    request.headers['User-Agent'] = existing != null && existing.isNotEmpty
        ? '$existing $_userAgent'
        : _userAgent;
    return inner.send(request);
  }

  @override
  void close() => inner.close();
}
