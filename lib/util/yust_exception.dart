class YustException implements Exception {
  String message;
  YustException(this.message);

  @override
  String toString() {
    return message;
  }
}
