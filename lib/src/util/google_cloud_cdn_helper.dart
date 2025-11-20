import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;

/// Helper for creating Cloud CDN Signed URLs (file + prefix).
class GoogleCloudCdnHelper {
  GoogleCloudCdnHelper({
    required this.baseUrl,
    required this.keyName,
    required this.keyBase64,
  }) : _keyBytes = base64Decode(keyBase64);

  final String baseUrl;
  final String keyName;
  final String keyBase64;
  final List<int> _keyBytes;

  String signFilePath({
    required String objectPath,
    required Duration validFor,
  }) {
    final fullUrl = _join(baseUrl, objectPath);
    final expires = _unix(validFor);

    final stringToSign =
        '$fullUrl?Expires=$expires&KeyName=${Uri.encodeQueryComponent(keyName)}';

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
