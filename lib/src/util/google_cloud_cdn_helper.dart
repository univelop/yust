import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

/// Helper for creating Cloud CDN Signed URLs (file + prefix).
class GoogleCloudCdnHelper {
  GoogleCloudCdnHelper({
    required this.baseUrl,
    required this.keyName,
    required this.keyBase64,
  }) : _keyBytes = base64Url.decode(keyBase64);

  /// The base URL of the CDN.
  final String baseUrl;

  /// The key name of the CDN.
  final String keyName;

  /// The key base64 of the CDN.
  final String keyBase64;

  /// Decoded key bytes
  final List<int> _keyBytes;

  /// Creates a signed URL for a file at the given [objectPath].
  ///
  /// [additionalQueryParams] are additional query parameters to be added to the URL.
  /// These will be signed and must exist in the same order in the signed URL.
  String signFilePath({
    required String objectPath,
    required Duration validFor,
    Map<String, String>? additionalQueryParams,
  }) {
    final fullUrlWithPort = _join(baseUrl, objectPath);
    var uriWithPort = Uri.parse(fullUrlWithPort);

    // Add optional query parameters to the url that will be signed
    final queryParams = Map<String, String>.from(uriWithPort.queryParameters);
    if (additionalQueryParams != null) {
      queryParams.addAll(additionalQueryParams);
    }
    uriWithPort = uriWithPort.replace(queryParameters: queryParams);

    // Strip the port because cdn otherwise rejects it
    final fullUrl = _stripPort(uriWithPort.toString());
    final expires = _unix(validFor);

    final uri = Uri.parse(fullUrl);
    final separator = uri.hasQuery ? '&' : '?';
    final keyNameEncoded = Uri.encodeQueryComponent(keyName);
    final stringToSign =
        '$fullUrl${separator}Expires=$expires&KeyName=$keyNameEncoded';

    final signature = _sign(stringToSign);

    return '$stringToSign&Signature=$signature';
  }

  /// Returns only the query string
  ///
  /// "URLPrefix=...&Expires=...&KeyName=...&Signature=..."
  String signPrefix({required String prefixPath, required Duration validFor}) {
    final normalized = _normalizePrefix(prefixPath);
    final fullPrefix = _join(baseUrl, normalized);

    final expires = _unix(validFor);

    final urlPrefixEncoded = base64UrlEncode(utf8.encode(fullPrefix));

    final signedValue =
        'URLPrefix=$urlPrefixEncoded&Expires=$expires&KeyName=$keyName';

    final signature = _sign(signedValue);

    return 'URLPrefix=$urlPrefixEncoded'
        '&Expires=$expires'
        '&KeyName=${Uri.encodeQueryComponent(keyName)}'
        '&Signature=$signature';
  }

  String _stripPort(String url) {
    final uri = Uri.parse(url);
    if (uri.hasPort == false) return url;

    final normalizedUri = uri.replace(port: null);
    return normalizedUri.toString();
  }

  int _unix(Duration validFor) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return now + validFor.inSeconds;
  }

  String _sign(String value) {
    final hmac = crypto.Hmac(crypto.sha1, _keyBytes);
    final digest = hmac.convert(utf8.encode(value));
    return base64UrlEncode(digest.bytes);
  }

  String _normalizePrefix(String p) {
    p = p.trim();
    if (p.startsWith('/')) p = p.substring(1);
    if (!p.endsWith('/')) p = '$p/';
    return p;
  }

  String _join(String base, String rel) {
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (rel.startsWith('/')) rel = rel.substring(1);
    return '$base/$rel';
  }
}
