import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart';

import 'yust_exception.dart';

/// The action to take if a exception occurs.
///
/// The Priority is: [retry] > [rethrowException] > [ignore]
/// If multiple functions return different actions, the action with the highest priority is taken.
enum YustActionOnException { retry, rethrowException, ignore }

/// Returns the action to take if a exception occurs.
/// Can also throw to produce a new exception.
typedef YustActionOnExceptionFn =
    YustActionOnException? Function(Object error, YustRecursionMetaInfo meta);

class YustRecursionMetaInfo {
  final String fnName;
  final String docPath;
  final int tryNumber;
  final int maxTries;

  bool get isFirstTry => tryNumber == 1;
  bool get isLastTry => tryNumber >= maxTries;
  bool get hasMoreTries => tryNumber < maxTries;

  YustRecursionMetaInfo(
    this.fnName,
    this.docPath,
    this.tryNumber,
    this.maxTries,
  );

  factory YustRecursionMetaInfo.firstTry(
    String fnName,
    String docPath,
    int maxTries,
  ) => YustRecursionMetaInfo(fnName, docPath, 1, maxTries);

  YustRecursionMetaInfo nextTry() =>
      YustRecursionMetaInfo(fnName, docPath, tryNumber + 1, maxTries);
}

class YustRetryHelper {
  static Future<T?> _retryRecursion<T>({
    required YustRecursionMetaInfo meta,
    required FutureOr<T> Function() fn,
    required List<YustActionOnExceptionFn> actionOnExceptionList,
    required int Function(int tryNumber) backoffMs,
    FutureOr<void> Function(
      Object lastErrorThrown,
      String fnName,
      String docPath,
    )?
    onRetriesExceeded,
    required bool shouldThrowAfterMaxTries,
    required YustActionOnException defaultAction,
  }) async {
    try {
      return await fn();
    } catch (e) {
      final actionOnException =
          actionOnExceptionList
              .map((fn) => fn(e, meta))
              .firstWhereOrNull((action) => action != null) ??
          defaultAction;
      switch (actionOnException) {
        case YustActionOnException.rethrowException:
          rethrow;
        case YustActionOnException.ignore:
          return null;
        case YustActionOnException.retry:
          if (meta.hasMoreTries) {
            return Future.delayed(
              Duration(milliseconds: backoffMs(meta.tryNumber)),
              () => _retryRecursion<T>(
                meta: meta.nextTry(),
                fn: fn,
                actionOnExceptionList: actionOnExceptionList,
                backoffMs: backoffMs,
                shouldThrowAfterMaxTries: shouldThrowAfterMaxTries,
                defaultAction: defaultAction,
              ),
            );
          }
          await onRetriesExceeded?.call(e, meta.fnName, meta.docPath);
          if (shouldThrowAfterMaxTries) {
            rethrow;
          }
          return null;
      }
    }
  }

  /// Retries the given function [fn] on errors.
  ///
  /// The function is tried up to [maxTries] times.
  ///
  /// If a error is thrown, the error is either rethrown,
  /// ignored and null is returned or retried after a backoff
  /// time given by [backoffMs].
  ///
  /// The action to take is determined by the functions in [actionOnExceptionList].
  /// The action with the highest priority is taken. If all functions return null,
  /// the [defaultAction] is taken.
  ///
  /// If [maxTries] is exceeded, the last error is rethrown or
  /// null is returned depending on [shouldThrowAfterMaxTries].
  ///
  /// [onRetriesExceeded] can be used for logging.
  static Future<T?> retryOnException<T>(
    String fnName,
    String docPath,
    FutureOr<T> Function() fn, {
    List<YustActionOnExceptionFn> actionOnExceptionList = const [],
    int maxTries = 16,
    int Function(int tryNumber) backoffMs = randomExponentialCeiledBackoffMs,
    FutureOr<void> Function(
      Object lastErrorThrown,
      String fnName,
      String docPath,
    )?
    onRetriesExceeded,
    bool shouldThrowAfterMaxTries = true,
    YustActionOnException defaultAction = YustActionOnException.retry,
  }) async {
    return _retryRecursion(
      meta: YustRecursionMetaInfo.firstTry(fnName, docPath, maxTries),
      fn: fn,
      actionOnExceptionList: actionOnExceptionList,
      backoffMs: backoffMs,
      onRetriesExceeded: onRetriesExceeded,
      shouldThrowAfterMaxTries: shouldThrowAfterMaxTries,
      defaultAction: defaultAction,
    );
  }

  /// Returns a random but exponential backoff time in milliseconds
  /// depending on [tryNumber].
  ///
  /// [maxExponentialBackoffMs] is the maximum for the exponential part
  /// of the backoff time, this will be multiplied by a random number between
  /// 20 and 40. For 16384 => 16384ms * ~30 = 491520ms (min 5.4min, max 10.9min)
  static int randomExponentialCeiledBackoffMs(
    int tryNumber, {
    int maxExponentialBackoffMs = 16384,
  }) {
    final int maxExponentialBackoffMs = 16384;
    return min(maxExponentialBackoffMs, pow(2, tryNumber + 2).toInt()) *
        (20 + Random().nextInt(20));
  }

  /// Rethrows YustExceptions and ignores YustNotFoundExceptions
  /// based on [shouldIgnoreNotFound].
  static YustActionOnExceptionFn actionOnYustException({
    bool shouldIgnoreNotFound = true,
  }) => (Object error, YustRecursionMetaInfo meta) {
    if (error is YustException) {
      if (error is YustNotFoundException && shouldIgnoreNotFound) {
        print(
          '[[DEBUG]] YustNotFoundException ignored for ${meta.fnName} call for ${meta.docPath}, this usually means the document was deleted before saving.',
        );
        return YustActionOnException.ignore;
      }
      print(
        '[[DEBUG]] NOT Retrying ${meta.fnName} call for the ${meta.tryNumber} time on YustException ($error) for ${meta.docPath}, because we don\'t retry YustExceptions',
      );
      return YustActionOnException.rethrowException;
    }
    return null;
  };

  /// Retries on Tls- and ClientExceptions.
  static YustActionOnException? actionOnNetworkException(
    Object error,
    YustRecursionMetaInfo meta,
  ) {
    if (error is TlsException) {
      print(
        '[[DEBUG]] Retrying ${meta.fnName} call for the ${meta.tryNumber} time on TlsException ($error) for ${meta.docPath}',
      );
      return YustActionOnException.retry;
    }
    if (error is ClientException) {
      print(
        '[[DEBUG]] Retrying ${meta.fnName} call for the ${meta.tryNumber} time on ClientException) ($error) for ${meta.docPath}',
      );
      return YustActionOnException.retry;
    }
    return null;
  }

  /// Retries on 500, 502 an 503 DetailedApiRequestErrors.
  /// 409 is retried if [shouldRetryOnTransactionErrors] is true.
  /// 404 is ignored if [shouldIgnoreNotFound] is true.
  /// (With the exception of expired transactions)
  /// Rethrows on all other DetailedApiRequestErrors.
  static YustActionOnExceptionFn actionOnDetailedApiRequestError({
    bool shouldRetryOnTransactionErrors = true,
    bool shouldIgnoreNotFound = false,
  }) => (Object error, YustRecursionMetaInfo meta) {
    if (error is DetailedApiRequestError) {
      if (error.status == 500) {
        print(
          '[[DEBUG]] Retrying ${meta.fnName} call for the ${meta.tryNumber} time on InternalServerError ($error) for ${meta.docPath}',
        );
        return YustActionOnException.retry;
      }
      if (error.status == 502) {
        print(
          '[[DEBUG]] Retrying ${meta.fnName} call for the ${meta.tryNumber} time on BadGateway ($error) for ${meta.docPath}',
        );
        return YustActionOnException.retry;
      }
      if (error.status == 503) {
        print(
          '[[DEBUG]] Retrying ${meta.fnName} call for the ${meta.tryNumber} time on Unavailable ($error) for ${meta.docPath}',
        );
        return YustActionOnException.retry;
      }
      if (error.status == 409 && shouldRetryOnTransactionErrors) {
        if ((error.message ?? '').contains(
          'The referenced transaction has expired or is no longer valid',
        )) {
          throw YustException.fromDetailedApiRequestError(meta.docPath, error);
        }
        print(
          '[[DEBUG]] Retrying ${meta.fnName} call for the ${meta.tryNumber} time on YustTransactionFailedException ($error) for ${meta.docPath}',
        );
        return YustActionOnException.retry;
      }
      if (error.status == 404 && shouldIgnoreNotFound) {
        print(
          '[[DEBUG]] Ignoring ${meta.fnName} call on NotFound ($error) for ${meta.docPath}',
        );
        return YustActionOnException.ignore;
      }
      throw YustException.fromDetailedApiRequestError(meta.docPath, error);
    }
    return null;
  };
}
