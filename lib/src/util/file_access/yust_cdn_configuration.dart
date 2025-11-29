/// Configuration for a CDN.
class YustCdnConfiguration {
  YustCdnConfiguration({
    required this.baseUrl,
    required this.keyName,
    required this.keyBase64,
  });

  /// The base URL of the CDN.
  final String baseUrl;

  /// The public key name of the CDN.
  final String keyName;

  /// The private key base64 of the CDN.
  final String keyBase64;
}
