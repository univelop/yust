import 'package:http/http.dart' as http;

/// An HTTP client wrapper that sets a custom User-Agent header
/// on every outgoing request.
///
/// This makes the User-Agent visible in Google Cloud Audit Logs
/// via `requestMetadata.callerSuppliedUserAgent`.
class UserAgentClient extends http.BaseClient {
  UserAgentClient(this._inner, {required String userAgent})
    : _userAgent = userAgent;

  final http.Client _inner;
  final String _userAgent;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['User-Agent'] = _userAgent;
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
