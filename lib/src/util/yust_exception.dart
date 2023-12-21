class YustException implements Exception {
  String message;
  YustException(this.message);

  @override
  String toString() {
    return message;
  }
}

class YustTransactionFailedException extends YustException {
  YustTransactionFailedException(String message) : super(message);
}

class YustDocumentLockedException extends YustException {
  YustDocumentLockedException(String message) : super(message);
}
