import 'dart:convert';

import 'package:googleapis/firestore/v1.dart';

class YustException implements Exception {
  String message;
  YustException(this.message);

  @override
  String toString() {
    return '$runtimeType: $message';
  }

  factory YustException.fromDetailedApiRequestError(
      String docPath, DetailedApiRequestError e) {
    if (e.message != null &&
        (e.message!.contains('Too much contention on these documents') ||
            e.message!
                .contains('Aborted due to cross-transaction contention.'))) {
      return YustDocumentLockedException(
          'Can not save the document $docPath. ${_detailedApiRequestErrorToString(e)}');
    }
    if (e.status == 404) {
      return YustNotFoundException(
          'The document $docPath was not found. ${_detailedApiRequestErrorToString(e)}');
    }
    if (e.status == 409) {
      return YustTransactionFailedException(
          'Failed save transaction for the document $docPath. ${_detailedApiRequestErrorToString(e)}');
    }
    return YustException(
        'Something went wrong with $docPath. ${_detailedApiRequestErrorToString(e)}');
  }

  static String _detailedApiRequestErrorToString(DetailedApiRequestError e) {
    return 'Message: ${e.message}, Status: ${e.status}, '
        'Response: ${jsonEncode(e.jsonResponse)}';
  }
}

class YustTransactionFailedException extends YustException {
  YustTransactionFailedException(super.message);
}

class YustDocumentLockedException extends YustException {
  YustDocumentLockedException(super.message);
}

class YustJsonParseException extends YustException {
  YustJsonParseException(super.message, this.json);

  final Map<String, dynamic> json;
}

class YustBadGatewayException extends YustException {
  YustBadGatewayException(super.message);
}

class YustNotFoundException extends YustException {
  YustNotFoundException(super.message);
}
