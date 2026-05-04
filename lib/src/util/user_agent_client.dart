import 'dart:io';

import 'package:http/http.dart' as http;

/// An HTTP client wrapper that sets a custom User-Agent header
/// on every outgoing request.
///
/// This makes the User-Agent visible in Google Cloud Audit Logs
/// via `requestMetadata.callerSuppliedUserAgent`.
class UserAgentClient extends http.BaseClient {
  UserAgentClient(this.inner, {required this.userAgent});

  final http.Client inner;
  final String userAgent;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final existing = request.headers[HttpHeaders.userAgentHeader];
    request.headers[HttpHeaders.userAgentHeader] =
        existing != null && existing.isNotEmpty
        ? '$existing $userAgent'
        : userAgent;
    return inner.send(request);
  }

  @override
  void close() => inner.close();
}
