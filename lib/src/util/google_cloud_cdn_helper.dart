import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../yust.dart';
import 'file_access/yust_cdn_configuration.dart';

/// Helper for creating Cloud CDN Signed URLs (file + prefix).
class GoogleCloudCdnHelper {
  GoogleCloudCdnHelper({
    required this.baseUrl,
    required this.keyName,
    required this.keyBase64,
  }) : _keyBytes = base64Url.decode(keyBase64);

  /// Creates a GoogleCloudCdnHelper from a YustCdnConfiguration.
  factory GoogleCloudCdnHelper.fromCdnConfiguration(
    YustCdnConfiguration cdnConfiguration,
  ) {
    return GoogleCloudCdnHelper(
      baseUrl: cdnConfiguration.baseUrl,
      keyName: cdnConfiguration.keyName,
      keyBase64: cdnConfiguration.keyBase64,
    );
  }

  /// The base URL of the CDN.
  final String baseUrl;

  /// The key name of the CDN.
  final String keyName;

  /// The key base64 of the CDN.
  final String keyBase64;

  /// Decoded key bytes
  final Uint8List _keyBytes;

  /// Creates a signed URL for a file at the given [path].
  ///
  /// [additionalQueryParams] are additional query parameters to be added to the URL.
  /// These will be signed and must exist in the same order in the signed URL.
  String signFilePath({
    required String path,
    required Duration validFor,
    Map<String, String>? additionalQueryParams,
  }) {
    final fullUrl = _join(baseUrl, path);
    var uri = Uri.parse(fullUrl);
    final expires = _unix(validFor);

    uri = uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        ...?additionalQueryParams,
        'Expires': expires.toString(),
        'KeyName': keyName,
      },
    );

    final url = uri.toString();
    final signature = _sign(url);

    return '$url&Signature=$signature';
  }

  /// Returns only the query string
  ///
  /// "URLPrefix=...&Expires=...&KeyName=...&Signature=..."
  String signPrefix({required String path, required Duration validFor}) {
    final normalized = _normalizePrefix(path);
    final fullPrefix = _join(baseUrl, normalized);
    final expires = _unix(validFor);

    final urlPrefixEncoded = base64UrlEncode(utf8.encode(fullPrefix));
    final urlPartToSign =
        'URLPrefix=$urlPrefixEncoded&Expires=$expires&KeyName=$keyName';

    final signature = _sign(urlPartToSign);

    return 'URLPrefix=$urlPrefixEncoded'
        '&Expires=$expires'
        '&KeyName=${Uri.encodeQueryComponent(keyName)}'
        '&Signature=$signature';
  }

  /// Returns the Unix timestamp for the given [validFor] duration.
  int _unix(Duration validFor) =>
      (Yust.helpers.utcNow().millisecondsSinceEpoch ~/ 1000) +
      validFor.inSeconds;

  String _sign(String value) {
    const sha1BlockSize = 64;
    final hmac = HMac(SHA1Digest(), sha1BlockSize)
      ..init(KeyParameter(_keyBytes));

    final bytes = hmac.process(Uint8List.fromList(utf8.encode(value)));
    return base64UrlEncode(bytes);
  }

  /// Normalize the given [path] e.g. remove leading and trailing slashes.
  String _normalizePrefix(String path) {
    var normalized = path;
    if (normalized.startsWith('/')) normalized = normalized.substring(1);
    if (!normalized.endsWith('/')) normalized = '$normalized/';

    return normalized;
  }

  String _join(String base, String rel) {
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (rel.startsWith('/')) rel = rel.substring(1);
    return '$base/$rel';
  }
}
