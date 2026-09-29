import 'dart:convert';

class YustFileMetadata {
  int size;
  String token;
  Map<String, String>? customMetadata;

  /// The hex encoded md5 hash of the file, as [YustFile.hash] stores it.
  ///
  /// Null when storage reports none, e.g. for composite objects.
  String? md5Hash;

  YustFileMetadata({
    required this.size,
    required this.token,
    this.customMetadata,
    this.md5Hash,
  });

  /// Converts the base64 encoded md5 hash storage reports into the hex
  /// encoding of [YustFile.hash].
  static String? md5HexFromBase64(String? base64Md5) {
    if (base64Md5 == null || base64Md5.isEmpty) return null;
    return base64Decode(
      base64Md5,
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
