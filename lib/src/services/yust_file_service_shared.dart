class YustFileMetadata {
  int size;
  String token;
  Map<String, String>? customMetadata;

  YustFileMetadata({
    required this.size,
    required this.token,
    this.customMetadata,
  });
}
