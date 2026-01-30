import 'package:meta/meta.dart';

import '../yust_exception.dart';

@immutable
/// Configuration for a CDN.
///
/// This configuration is only relevant for the backend which should
/// use it to create signed URLs for files for the frontend.
///
/// The base URL and key name are public but the key base64 has to be kept secret.
class YustCdnConfiguration {
  YustCdnConfiguration({
    required this.baseUrl,
    required this.keyName,
    required this.keyBase64,
  }) {
    if (!baseUrl.endsWith('/')) {
      throw YustException('Base URL must end with a trailing slash: $baseUrl');
    }
  }

  /// The base URL of the CDN.
  final String baseUrl;

  /// The public key name of the CDN.
  final String keyName;

  /// The private key base64 of the CDN.
  final String keyBase64;

  @override
  bool operator ==(Object other) =>
      other is YustCdnConfiguration &&
      baseUrl == other.baseUrl &&
      keyName == other.keyName &&
      keyBase64 == other.keyBase64;

  @override
  int get hashCode => Object.hash(baseUrl, keyName, keyBase64);

  @override
  String toString() => '$baseUrl (keyName: $keyName)';
}
