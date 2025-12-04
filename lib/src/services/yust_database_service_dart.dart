import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:googleapis/firestore/v1.dart' hide AggregationResult;
import 'package:http/http.dart';

import '../extensions/date_time_extension.dart';
import '../extensions/server_now.dart';
import '../extensions/string_extension.dart';
import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';
import '../models/yust_order_by.dart';
import '../util/yust_database_statistics.dart';
import '../util/yust_exception.dart';
import '../util/yust_field_transform.dart';
import '../util/yust_helpers.dart';
import '../util/yust_retry_helper.dart';
import '../yust.dart';
import 'yust_database_service_interface.dart';
import 'yust_database_service_shared.dart';

const firestoreApiUrl = 'https://firestore.googleapis.com/';

/// Handles database requests for Cloud Firestore.
///
/// Using FlutterFire for Flutter Platforms (Android, iOS, Web) and GoogleAPIs for Dart-only environments.
class YustDatabaseService implements IYustDatabaseService {
  late final FirestoreApi _api;
  @override
  DatabaseLogCallback? dbLogCallback;
  @override
  YustDatabaseStatistics statistics = YustDatabaseStatistics();

  final Yust _yust;

  /// Represents the collection name for the tenants.
  @override
  final String envCollectionName;

  /// If [useSubcollections] is set to true (default), Yust is creating Subcollections for each tenant automatically.
  @override
  final bool useSubcollections;

  final Client _authClient;

  /// Root (aka base) URL for the Firestore REST/GRPC API.
  final String _rootUrl;

  /// Which version of documents to read.
  ///
  /// A timestamp in the past will return the document at that time.
  /// Null will return the most recent version.
  @override
  DateTime? readTime;

  YustDatabaseService({required Yust yust, String? emulatorAddress})
    : _yust = yust,
      _authClient = Yust.authClient!,
      envCollectionName = yust.envCollectionName,
      useSubcollections = yust.useSubcollections,
      _rootUrl = emulatorAddress != null
          ? 'http://$emulatorAddress:8080/'
          : firestoreApiUrl {
    _api = FirestoreApi(_authClient, rootUrl: _rootUrl);

    dbLogCallback =
        (
          DatabaseLogAction action,
          String documentPath,
          int count, {
          String? id,
          List<String>? updateMask,
          num? aggregationResult,
        }) {
          statistics.dbStatisticsCallback(
            action,
            documentPath,
            count,
            id: id,
            updateMask: updateMask,
            aggregationResult: aggregationResult,
          );
          _yust.dbLogCallback?.call(
            action,
            documentPath,
            count,
            id: id,
            updateMask: updateMask,
            aggregationResult: aggregationResult,
          );
        };
  }

  YustDatabaseService.mocked({required Yust yust})
    : _yust = yust,
      envCollectionName = yust.envCollectionName,
      useSubcollections = yust.useSubcollections,
      dbLogCallback = yust.dbLogCallback,
      _rootUrl = '',
      _authClient = Client();

  /// Initializes a document with an id and the time it was created.
  ///
  /// Optionally an existing document can be given, which will still be
  /// assigned a new id becoming a new document if it had an id previously.
  @override
  T initDoc<T extends YustDoc>(YustDocSetup<T> docSetup, [T? doc]) {
    final id = _createDocumentId();
    return doInitDoc(docSetup, id, doc);
  }

  /// Returns a [YustDoc] from the server, if available, otherwise from the cache.
  /// The cached documents may not be up to date!
  ///
  /// Be careful with offline functionality.
  @override
  Future<T?> get<T extends YustDoc>(YustDocSetup<T> docSetup, String id) async {
    return getFromDB(docSetup, id);
  }

  /// Returns a [YustDoc] from the cache, if available, otherwise from the server.
  /// Be careful: The cached documents may not be up to date!
  ///
  /// Be careful with offline functionality.
  @override
  Future<T?> getFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    return getFromDB(docSetup, id);
  }

  /// Returns a [YustDoc] directly from the server.
  ///
  /// Be careful with offline functionality.
  @override
  Future<T?> getFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id, {
    String? transaction,
  }) async {
    try {
      final response = await _retryOnException<Document>(
        'getFromDB',
        _getDocumentPath(docSetup, id),
        () => _api.projects.databases.documents.get(
          _getDocumentPath(docSetup, id),
          readTime: readTime?.toUtc().toIso8601String(),
          transaction: transaction,
        ),
      );

      dbLogCallback?.call(DatabaseLogAction.get, _getDocumentPath(docSetup), 1);
      return _transformDoc<T>(docSetup, response);
    } on YustNotFoundException {
      dbLogCallback?.call(DatabaseLogAction.get, _getDocumentPath(docSetup), 0);
      return null;
    }
  }

  /// Returns a stream of a [YustDoc].
  ///
  /// Whenever another user makes a change, a new version of the document is returned.
  @override
  Stream<T?> getStream<T extends YustDoc>(YustDocSetup<T> docSetup, String id) {
    return Stream.fromFuture(getFromDB<T>(docSetup, id));
  }

  /// Returns the first [YustDoc] in a list from the server, if available, otherwise from the cache.
  /// The cached documents may not be up to date!
  ///
  /// Be careful with offline functionality.
  /// The result is null if no document was found.
  @override
  Future<T?> getFirst<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    return getFirstFromDB(docSetup, filters: filters, orderBy: orderBy);
  }

  /// Returns the first [YustDoc] in a list from the cache, if available, otherwise from the server.
  /// Be careful: The cached documents may not be up to date!
  ///
  /// Be careful with offline functionality.
  /// The result is null if no document was found.
  @override
  Future<T?> getFirstFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    return getFirstFromDB(docSetup, filters: filters, orderBy: orderBy);
  }

  /// Returns the first [YustDoc] in a list directly from the server.
  ///
  /// Be careful with offline functionality.
  /// The result is null if no document was found.
  @override
  Future<T?> getFirstFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    final response = await _retryOnException<List<RunQueryResponseElement>>(
      'getFirstFromDB',
      _getDocumentPath(docSetup),
      () => _api.projects.databases.documents.runQuery(
        getQuery(docSetup, filters: filters, orderBy: orderBy, limit: 1),
        _getParentPath(docSetup),
      ),
    );

    if (response.isEmpty || response.first.document == null) {
      dbLogCallback?.call(DatabaseLogAction.get, _getDocumentPath(docSetup), 0);
      return null;
    }
    dbLogCallback?.call(DatabaseLogAction.get, _getDocumentPath(docSetup), 1);
    return _transformDoc<T>(docSetup, response.first.document!);
  }

  /// Returns a stream of the first [YustDoc] in a list.
  ///
  /// Whenever another user make a change, a new version of the document is returned.
  /// The result is null if no document was found.
  @override
  Stream<T?> getFirstStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) {
    return Stream.fromFuture(
      getFirstFromDB<T>(docSetup, filters: filters, orderBy: orderBy),
    );
  }

  /// Returns [YustDoc]s from the server, if available, otherwise from the cache.
  /// The cached documents may not be up to date!
  ///
  /// [docSetup] is used to read the collection path.
  ///
  /// [filters] each entry represents a condition that has to be met.
  /// All of those conditions must be true for each returned entry.
  ///
  /// [orderBy] orders the returned records.
  /// Multiple of those entries can be repeated.
  ///
  /// [limit] can be passed to only get at most n documents.
  @override
  Future<List<T>> getList<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    T? startAfterDocument,
  }) {
    return getListFromDB(
      docSetup,
      filters: filters,
      orderBy: orderBy,
      limit: limit,
      startAfterDocument: startAfterDocument,
    );
  }

  /// Returns [YustDoc]s from the cache, if available, otherwise from the server.
  /// Be careful: The cached documents may not be up to date!
  ///
  /// [docSetup] is used to read the collection path.
  ///
  /// [filters] each entry represents a condition that has to be met.
  /// All of those conditions must be true for each returned entry.
  ///
  /// [orderBy] orders the returned records.
  /// Multiple of those entries can be repeated.
  ///
  /// [limit] can be passed to only get at most n documents.
  @override
  Future<List<T>> getListFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    T? startAfterDocument,
  }) {
    return getListFromDB(
      docSetup,
      filters: filters,
      orderBy: orderBy,
      limit: limit,
      startAfterDocument: startAfterDocument,
    );
  }

  /// Returns [YustDoc]s directly from the database.
  ///
  /// Be careful with offline functionality.
  ///
  /// [docSetup] is used to read the collection path.
  ///
  /// [filters] each entry represents a condition that has to be met.
  /// All of those conditions must be true for each returned entry.
  ///
  /// [orderBy] orders the returned records.
  /// Multiple of those entries can be repeated.
  ///
  /// [limit] can be passed to only get at most n documents.
  @override
  Future<List<T>> getListFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    T? startAfterDocument,
  }) async {
    final response = await _retryOnException<List<RunQueryResponseElement>>(
      'getListFromDB',
      _getDocumentPath(docSetup),
      () => _api.projects.databases.documents.runQuery(
        getQuery(
          docSetup,
          filters: filters,
          orderBy: orderBy,
          limit: limit,
          startAfterDocument: startAfterDocument,
        ),
        _getParentPath(docSetup),
      ),
    );
    dbLogCallback?.call(
      DatabaseLogAction.get,
      _getDocumentPath(docSetup),
      response.length,
    );

    return response
        .map((e) {
          if (e.document == null) {
            return null;
          }
          return _transformDoc<T>(docSetup, e.document!);
        })
        .whereType<T>()
        .toList();
  }

  /// Returns [YustDoc]s as a lazy, chunked Stream from the database.
  ///
  /// This is much more memory efficient in comparison to other methods,
  /// because of three reasons:
  /// 1. It gets the data in multiple requests ([pageSize] each); the raw json
  ///    strings and raw maps are only in memory while one chunk is processed.
  /// 2. It loads the records *lazily*, meaning only one chunk is in memory while
  ///    the records worked with (e.g. via a `await for(...)`)
  /// 3. It doesn't use the google_apis package for the request, because that
  ///    has a huge memory leak
  ///
  /// NOTE: Because this is a Stream you may only iterate over it once,
  /// listening to it multiple times will result in a runtime-exception!
  ///
  /// [docSetup] is used to read the collection path.
  ///
  /// [filters] each entry represents a condition that has to be met.
  /// All of those conditions must be true for each returned entry.
  ///
  /// [orderBy] orders the returned records.
  /// Multiple of those entries can be repeated.
  ///
  @override
  Stream<T> getListChunked<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int pageSize = 300,
    T? startAfterDocument,
  }) => _getDocumentsListChunked(
    docSetup: docSetup,
    parent: _getParentPath(docSetup),
    fnName: 'getListChunked',
    filters: filters,
    orderBy: orderBy,
    pageSize: pageSize,
    startAfterDocument: startAfterDocument,
  );

  @override
  Future<List<String>> getDocumentIds<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    int? limit,
    String? startAfterDocumentId,
  }) async {
    T? startAfterDocument;
    if (startAfterDocumentId != null) {
      // Create a minimal document object for pagination using doInitDoc
      startAfterDocument = doInitDoc(docSetup, startAfterDocumentId);
    }

    final response = await _retryOnException<List<RunQueryResponseElement>>(
      'getDocumentIds',
      _getDocumentPath(docSetup),
      () => _api.projects.databases.documents.runQuery(
        getQuery(
          docSetup,
          filters: filters,
          limit: limit,
          startAfterDocument: startAfterDocument,
          fields: ['id'],
        ),
        _getParentPath(docSetup),
      ),
    );
    dbLogCallback?.call(
      DatabaseLogAction.get,
      _getDocumentPath(docSetup),
      response.length,
    );

    return response
        .map((e) => _extractDocumentId(e.document))
        .whereType<String>()
        .toList();
  }

  @override
  Stream<String> getDocumentIdsChunked<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    int pageSize = 300,
    String? startAfterDocumentId,
  }) {
    T? startAfterDocument;
    if (startAfterDocumentId != null) {
      // Create a minimal document object for pagination using doInitDoc
      startAfterDocument = doInitDoc(docSetup, startAfterDocumentId);
    }

    return _getDocumentsListChunked(
      docSetup: docSetup,
      parent: _getParentPath(docSetup),
      fnName: 'getDocumentIdsChunked',
      filters: filters,
      pageSize: pageSize,
      startAfterDocument: startAfterDocument,
      idsOnly: true,
      orderBy: null,
    ).cast<String>();
  }

  /// Returns a stream of a [YustDoc]s.
  ///
  /// Asking the cache and the database for documents. If documents are stored in the cache, the documents are returned instantly and then refreshed by the documents from the server.
  ///
  /// [docSetup] is used to read the collection path.
  ///
  /// [filters] Each entry represents a condition that has to be met.
  /// All of those conditions must be true for each returned entry.
  ///
  /// [orderBy] orders the returned records.
  /// Multiple of those entries can be repeated.
  ///
  /// [limit] can be passed to only get at most n documents.
  @override
  Stream<List<T>> getListStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    T? startAfterDocument,
  }) {
    return Stream.fromFuture(
      getListFromDB<T>(
        docSetup,
        filters: filters,
        orderBy: orderBy,
        limit: limit,
        startAfterDocument: startAfterDocument,
      ),
    );
  }

  @override
  Future<List<T>> getListForCollectionGroup<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    T? startAfterDocument,
  }) async {
    final response = await _retryOnException<List<RunQueryResponseElement>>(
      'getListForAllEnvironments',
      docSetup.collectionName,
      () => _api.projects.databases.documents.runQuery(
        getQuery(
          docSetup,
          filters: filters,
          orderBy: orderBy,
          limit: limit,
          startAfterDocument: startAfterDocument,
          forCollectionGroup: true,
        ),
        '${_getDatabasePath()}/documents',
      ),
    );
    dbLogCallback?.call(
      DatabaseLogAction.get,
      _getDocumentPath(docSetup),
      response.length,
    );

    return response
        .map((e) {
          if (e.document == null) {
            return null;
          }
          return _transformDoc<T>(docSetup, e.document!);
        })
        .whereType<T>()
        .toList();
  }

  @override
  Stream<T> getListChunkedForCollectionGroup<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int pageSize = 300,
    T? startAfterDocument,
  }) => _getDocumentsListChunked(
    docSetup: docSetup,
    parent: '${_getDatabasePath()}/documents',
    fnName: 'getListChunkedForAllEnvironments',
    filters: filters,
    orderBy: orderBy,
    pageSize: pageSize,
    startAfterDocument: startAfterDocument,
    forCollectionGroup: true,
  );

  Stream<T> _getDocumentsListChunked<T extends YustDoc>({
    required YustDocSetup<T> docSetup,
    required String parent,
    required String fnName,
    required List<YustFilter>? filters,
    required List<YustOrderBy>? orderBy,
    required int pageSize,
    required T? startAfterDocument,
    bool forCollectionGroup = false,
    bool idsOnly = false,
  }) {
    assert(
      orderBy == null || idsOnly == false,
      'If idsOnly is set to true, orderBy is not supported and must be null.',
    );

    final url = '${_rootUrl}v1/${Uri.encodeFull(parent)}:runQuery';

    final unequalFilters = (filters ?? [])
        .whereNot(
          (filter) =>
              YustFilterComparator.equalityFilters.contains(filter.comparator),
        )
        .toSet()
        .toList();

    assert(
      !((unequalFilters.isNotEmpty) && (orderBy?.isNotEmpty ?? false)),
      'You can\'t use orderBy and unequal filters at the same time',
    );

    // Calculate orderBy from all unequal filters
    if (unequalFilters.isNotEmpty) {
      orderBy = unequalFilters
          .map((e) => YustOrderBy(field: e.field))
          .toSet()
          .toList();
    }

    Stream<Map<dynamic, dynamic>> lazyPaginationGenerator() async* {
      var isDone = false;
      T? lastDocument = startAfterDocument;

      while (!isDone) {
        final request = getQuery(
          docSetup,
          filters: filters,
          // For ID-only mode, only use __name__ ordering for pagination
          // For full documents, use provided orderBy + __name__
          orderBy: idsOnly
              ? [YustOrderBy(field: '__name__')]
              : [...?orderBy, YustOrderBy(field: '__name__')],
          limit: pageSize,
          startAfterDocument: lastDocument,
          forCollectionGroup: forCollectionGroup,
          fields: idsOnly ? ['id'] : null,
        );
        final body = jsonEncode(request);

        final result = await _retryOnException(fnName, parent, () async {
          final response = await _authClient.post(Uri.parse(url), body: body);
          if (response.statusCode < 200 || response.statusCode >= 400) {
            var json = {'error': response.body};
            try {
              json = jsonDecode(response.body);
            } catch (e) {
              // the response body could not be parsed as json
            }
            throw DetailedApiRequestError(
              response.statusCode,
              'No error details. HTTP status was: $response.statusCode',
              jsonResponse: json,
            );
          }
          return response;
        });

        final response = List<Map<dynamic, dynamic>>.from(
          jsonDecode(result.body),
        );

        dbLogCallback?.call(
          DatabaseLogAction.get,
          _getDocumentPath(docSetup),
          response.length,
        );

        isDone = response.length < pageSize;
        if (!isDone) {
          T? lastNotCorruptDocument;

          for (var i = response.length - 1; i >= 0; i--) {
            final documentJson = response[i]['document'];
            if (documentJson == null) continue;

            if (idsOnly) {
              final documentId = _extractDocumentId(
                Document.fromJson(documentJson),
              );
              if (documentId != null) {
                lastNotCorruptDocument = doInitDoc(docSetup, documentId);
                break;
              }
            } else {
              final transformedDoc = _transformDoc<T>(
                docSetup,
                Document.fromJson(documentJson),
              );
              if (transformedDoc != null) {
                lastNotCorruptDocument = transformedDoc;
                break;
              }
            }
          }

          if (lastNotCorruptDocument == null) {
            throw YustException(
              'No valid document found in chunk of $pageSize documents.',
            );
          }

          lastDocument = lastNotCorruptDocument;
        }

        yield* Stream.fromIterable(response);
      }
    }

    if (idsOnly) {
      return lazyPaginationGenerator()
              .map<String?>((e) {
                if (e['document'] == null) return null;
                return _extractDocumentId(Document.fromJson(e['document']));
              })
              .where((e) => e is String)
              .cast<String>()
          as Stream<T>;
    } else {
      return lazyPaginationGenerator()
          .map<T?>((e) {
            if (e['document'] == null) return null;
            return _transformDoc<T>(docSetup, Document.fromJson(e['document']));
          })
          .where((e) => e is T)
          .cast<T>();
    }
  }

  /// Counts the number of documents in a collection.
  ///
  /// [docSetup] is used to read the collection path.
  ///
  /// [filters] Each entry represents a condition that has to be met.
  /// All of those conditions must be true for each returned entry.
  @override
  Future<int> count<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    final type = AggregationType.count;
    final response =
        await _retryOnException<List<RunAggregationQueryResponseElement>>(
          'count',
          _getDocumentPath(docSetup),
          () => _api.projects.databases.documents.runAggregationQuery(
            _getAggregationQuery(type, docSetup, filters: filters, upTo: limit),
            _getParentPath(docSetup),
          ),
        );

    final result = int.parse(
      response[0].result?.aggregateFields?[type.name]?.integerValue ?? '0',
    );
    dbLogCallback?.call(
      DatabaseLogAction.aggregate,
      _getDocumentPath(docSetup),
      result,
    );
    return result;
  }

  /// Returns the sum over a field of multiple documents in a collection.
  ///
  /// [docSetup] is used to read the collection path.
  ///
  /// [field] is the field over which to sum.
  ///
  /// [filters] Each entry represents a condition that has to be met.
  /// All of those conditions must be true for each returned entry.
  @override
  Future<AggregationResult> sum<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String fieldPath, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    return _performAggregation(
      AggregationType.sum,
      docSetup,
      fieldPath,
      filters: filters,
      limit: limit,
    );
  }

  /// Returns the sum over a field of multiple documents in a collection.
  ///
  /// [docSetup] is used to read the collection path.
  ///
  /// [fieldPath] is the field over which to sum.
  ///
  /// [filters] Each entry represents a condition that has to be met.
  /// All of those conditions must be true for each returned entry.
  @override
  Future<AggregationResult> avg<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String fieldPath, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    return _performAggregation(
      AggregationType.avg,
      docSetup,
      fieldPath,
      filters: filters,
      limit: limit,
    );
  }

  Future<AggregationResult> _performAggregation<T extends YustDoc>(
    AggregationType type,
    YustDocSetup<T> docSetup,
    String fieldPath, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    final response =
        await _retryOnException<List<RunAggregationQueryResponseElement>>(
          'performAggregation:${type.name.split('.').last}',
          _getDocumentPath(docSetup),
          () => _api.projects.databases.documents.runAggregationQuery(
            _getAggregationQuery(
              type,
              docSetup,
              fieldPath: fieldPath,
              filters: filters,
              upTo: limit,
            ),
            _getParentPath(docSetup),
          ),
        );
    final resultValue = response[0].result?.aggregateFields?[type.name];
    final result =
        resultValue?.doubleValue ??
        double.tryParse(resultValue?.integerValue ?? '');

    final count = int.parse(
      response[0]
              .result
              ?.aggregateFields?[AggregationType.count.name]
              ?.integerValue ??
          '0',
    );
    dbLogCallback?.call(
      DatabaseLogAction.aggregate,
      _getDocumentPath(docSetup),
      count,
      aggregationResult: result,
    );
    return (count: count, result: result);
  }

  /// Saves a document.
  ///
  /// If [merge] is false a document with the same name
  /// will be overwritten instead of trying to merge the data.
  /// Use [doNotCreate] to ensure that no new record is created
  @override
  Future<void> saveDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc, {
    bool? merge = true,
    bool? trackModification,
    bool skipOnSave = false,
    bool? removeNullValues,
    List<String>? updateMask,
    bool skipLog = false,
    bool doNotCreate = false,
  }) async {
    await prepareSaveDoc(
      docSetup,
      doc,
      trackModification: trackModification,
      skipOnSave: skipOnSave,
    );
    final yustUpdateMask = doc.updateMask;
    if (updateMask != null) updateMask.addAll(yustUpdateMask);

    final jsonDoc = doc.toJson();
    final dbDoc = Document(
      fields: jsonDoc.map(
        (key, value) => MapEntry(key, _valueToDbValue(value)),
      ),
    );

    // Because the Firestore REST-Api (used in the background) can't handle attributes starting with numbers,
    // e.g. 'foo.0bar', we need to escape the path-parts by using '´': '`foo`.`0bar`'
    final quotedUpdateMask = updateMask
        ?.toSet()
        .map((path) => YustHelpers().toQuotedFieldPath(path)!)
        .toList();
    final docPath = _getDocumentPath(docSetup, doc.id);

    // The updateMask will be part of the URL, in the save request.
    // Since there is is a limit on the URL length, we need to ignore the updateMask
    // if it would make the URL too big.
    // Additionally there is a limit on the length of each element in the updateMask.
    // The [maxUrlCharacterLength] was determined by testing the length of the URL with different updateMasks.
    final maxUrlCharacterLength = 16416;
    final estimatedUrlLength = _calcEstimatedUrlLength(
      quotedUpdateMask,
      docPath,
    );
    final characterTolerance = 500;
    final ignoreUpdateMask =
        maxUrlCharacterLength - characterTolerance < estimatedUrlLength;
    if (ignoreUpdateMask) {
      print(
        '[[WARNING]] saveDoc: Estimated URL length ($estimatedUrlLength) is greater than max URL length '
        '($maxUrlCharacterLength) - tolerance ($characterTolerance). Saving without updateMask!',
      );
    }

    await _retryOnException('saveDoc', _getDocumentPath(docSetup), () async {
      await _api.projects.databases.documents.patch(
        dbDoc,
        docPath,
        mask_fieldPaths: ['id'], // to reduce the size of the request
        updateMask_fieldPaths: ignoreUpdateMask ? null : quotedUpdateMask,
        currentDocument_exists: doNotCreate ? true : null,
      );
      if (!skipLog) {
        dbLogCallback?.call(
          DatabaseLogAction.save,
          _getDocumentPath(docSetup),
          1,
          id: doc.id,
          updateMask: ignoreUpdateMask ? [] : updateMask ?? [],
        );
      }
    }, shouldIgnoreNotFound: doNotCreate);
  }

  /// Calculates the estimated length of the URL for a saveDoc request.
  int _calcEstimatedUrlLength(List<String>? updateMask, String docPath) {
    final url =
        'https://firestore.googleapis.com/v1/$docPath?${updateMask?.map((item) => 'updateMask.fieldPaths=``$item``').join('&')}&alt=json';
    return url.length;
  }

  /// Transforms (e.g. increment, decrement) a documents fields.
  @override
  Future<void> updateDocByTransform<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
    List<YustFieldTransform> fieldTransforms, {
    bool skipOnSave = false,
    bool? removeNullValues,
  }) async {
    final firebaseFieldTransforms = fieldTransforms
        .map((t) => t.toNativeTransform())
        .cast<FieldTransform>()
        .toList();
    final docPath = _getDocumentPath(docSetup, id);
    final documentTransform = DocumentTransform(
      fieldTransforms: firebaseFieldTransforms,
      document: docPath,
    );
    final write = Write(
      transform: documentTransform,
      currentDocument: Precondition(exists: true),
    );
    final commitRequest = CommitRequest(writes: [write]);
    await _retryOnException(
      'updateDocByTransform',
      _getDocumentPath(docSetup, id),
      () async {
        await _api.projects.databases.documents.commit(
          commitRequest,
          _getDatabasePath(),
        );
        dbLogCallback?.call(
          DatabaseLogAction.transform,
          _getDocumentPath(docSetup),
          1,
          id: id,
          updateMask: fieldTransforms.map((e) => e.fieldPath).toList(),
        );
      },
    );
  }

  /// Delete all [YustDoc]s in the filter.
  @override
  Future<int> deleteDocs<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
  }) async {
    // (No logs here, because getListFromDB, and deleteDoc already log)
    final docs = await getListFromDB<T>(docSetup, filters: filters);
    final count = docs.length;
    for (var doc in docs) {
      await deleteDoc<T>(docSetup, doc);
    }
    return count;
  }

  /// Delete all [YustDoc]s in the filter as a batch.
  @override
  Future<int> deleteDocsAsBatch<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) async {
    final response = await _api.projects.databases.documents.runQuery(
      getQuery(docSetup, filters: filters, orderBy: orderBy, limit: limit),
      _getParentPath(docSetup),
    );

    final noOfDocs = response
        .where((element) => element.document != null)
        .length;

    await _retryOnException(
      'deleteDocsAsBatch',
      _getDocumentPath(docSetup),
      () async {
        await _api.projects.databases.documents.batchWrite(
          BatchWriteRequest(
            writes: response
                .where((element) => element.document != null)
                .map((element) => Write(delete: element.document?.name))
                .toList(),
          ),
          _getDatabasePath(),
        );
      },
    );
    dbLogCallback?.call(
      DatabaseLogAction.delete,
      _getDocumentPath(docSetup),
      noOfDocs,
    );
    return noOfDocs;
  }

  /// Delete a [YustDoc].
  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    final docPath = _getDocumentPath(docSetup, doc.id);
    await _retryOnException('deleteDoc', _getDocumentPath(docSetup), () async {
      await _api.projects.databases.documents.delete(docPath);
      dbLogCallback?.call(
        DatabaseLogAction.delete,
        _getDocumentPath(docSetup),
        1,
      );
    });
  }

  /// Delete a [YustDoc] by the ID.
  @override
  Future<void> deleteDocById<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    final docPath = _getDocumentPath(docSetup, id);
    await _retryOnException(
      'deleteDocById',
      _getDocumentPath(docSetup, id),
      () async {
        await _api.projects.databases.documents.delete(docPath);
        dbLogCallback?.call(
          DatabaseLogAction.delete,
          _getDocumentPath(docSetup),
          1,
          id: id,
        );
      },
    );
  }

  /// Initializes a [YustDoc] and saves it.
  ///
  /// If [onInitialised] is provided, it will be called and
  /// waited for after the document is initialized.
  ///
  /// An existing document can be given which will instead be initialized.
  @override
  Future<T> saveNewDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    required T doc,
    Future<void> Function(T)? onInitialised,
    bool? removeNullValues,
  }) async {
    doc = initDoc<T>(docSetup, doc);

    if (onInitialised != null) {
      await onInitialised(doc);
    }

    await saveDoc<T>(
      docSetup,
      doc,
      removeNullValues: removeNullValues ?? docSetup.removeNullValues,
      skipLog: true,
    );
    dbLogCallback?.call(
      DatabaseLogAction.saveNew,
      _getDocumentPath(docSetup),
      1,
      id: doc.id,
    );
    return doc;
  }

  /// Reads a document, executes a function and saves the document as a transaction.
  /// Returns true if the transaction was successful.
  ///
  /// If the transaction fails, it will be retried up to [maxTries] - 1 times.
  /// [transaction] should return the updated document, if it returns null, nothing will be saved to the db.
  ///
  /// Some general Notes on Transactions:
  /// - Transactions are only auto-retried by the google client libraries, so we need to do it manually
  /// - Transactions will only fail if a document was changed by a other transaction.
  ///   _Not_ if the document was changed by a normal save
  @override
  Future<(bool, T?)> runTransactionForDocument<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String docId,
    Future<T?> Function(T doc) transaction, {
    int maxTries = 200,
    bool ignoreTransactionErrors = false,
    bool useUpdateMask = false,
  }) => _retryOnException(
    'runTransactionForDocument',
    _getDocumentPath(docSetup, docId),
    () async {
      const retryDelayFactor = 10000;
      const retryMinDelay = 100;

      var numberRetries = 0;
      T? updatedDoc;

      while (numberRetries < maxTries) {
        final transactionId = await beginTransaction();
        final doc = await getFromDB<T>(
          docSetup,
          docId,
          transaction: transactionId,
        );
        if (doc == null) {
          throw YustNotFoundException('Can not find document $docId.');
        }

        try {
          updatedDoc = await transaction(doc);
          if (updatedDoc == null) {
            dbLogCallback?.call(
              DatabaseLogAction.save,
              _getDocumentPath(docSetup),
              0,
              id: doc.id,
            );
            await commitEmptyTransaction(transactionId);
            return (false, null);
          } else {
            await commitTransaction(
              transactionId,
              docSetup,
              updatedDoc,
              useUpdateMask: useUpdateMask,
            );
          }
          dbLogCallback?.call(
            DatabaseLogAction.save,
            _getDocumentPath(docSetup),
            1,
            id: doc.id,
            updateMask: [if (useUpdateMask) ...updatedDoc.updateMask],
          );
          break;
        }
        // We are catching DetailedApiRequestError(409) and YustTransactionFailedException here
        catch (e) {
          var exception = e;
          // Should there be an error in our transaction code, that needs to be
          // transformed to an YustException as well
          if (e is DetailedApiRequestError) {
            exception = YustException.fromDetailedApiRequestError(
              docSetup.collectionName,
              e,
            );
          }
          if (exception is YustTransactionFailedException ||
              exception is YustDocumentLockedException) {
            if (ignoreTransactionErrors) return (false, null);

            numberRetries++;
            await Future.delayed(
              Duration(
                milliseconds:
                    (Random().nextDouble() * retryDelayFactor).toInt() +
                    retryMinDelay,
              ),
            );
          } else {
            rethrow;
          }
        }
      }
      if (numberRetries == maxTries) {
        throw YustException(
          'Retried transaction $numberRetries times (no more retries): Collection ${docSetup.collectionName}, Workspace ${docSetup.envId}',
        );
      } else if (numberRetries > 1) {
        print(
          'Retried transaction $numberRetries times (of $maxTries): Collection ${docSetup.collectionName}, Workspace ${docSetup.envId}',
        );
      }
      return (true, updatedDoc);
    },
    shouldRetryOnTransactionErrors: false,
  );

  /// Begins a transaction.
  @override
  Future<String> beginTransaction() async {
    final response = await _retryOnException<BeginTransactionResponse>(
      'beginTransaction',
      'N.A.',
      () => _api.projects.databases.documents.beginTransaction(
        BeginTransactionRequest(),
        _getDatabasePath(),
      ),
      shouldRetryOnTransactionErrors: false,
    );
    if (response.transaction == null) {
      throw YustException('Can not begin transaction.');
    }
    return response.transaction!;
  }

  /// Saves a YustDoc and finishes a transaction.
  @override
  Future<void> commitTransaction(
    String transaction,
    YustDocSetup docSetup,
    YustDoc doc, {
    bool useUpdateMask = false,
  }) async {
    final jsonDoc = doc.toJson();
    final dbDoc = Document(
      fields: jsonDoc.map(
        (key, value) => MapEntry(key, _valueToDbValue(value)),
      ),
      name: _getDocumentPath(docSetup, doc.id),
    );
    final write = Write(
      update: dbDoc,
      currentDocument: Precondition(exists: true),
    );
    if (useUpdateMask) {
      write.updateMask = DocumentMask(
        fieldPaths: doc.updateMask
            .map((e) => YustHelpers().toQuotedFieldPath(e)!)
            .toList(),
      );
    }
    final commitRequest = CommitRequest(
      transaction: transaction,
      writes: [write],
    );
    await _retryOnException<void>(
      'commitTransaction',
      'N.A.',
      () => _api.projects.databases.documents.commit(
        commitRequest,
        _getDatabasePath(),
      ),
      shouldRetryOnTransactionErrors: false,
    );
  }

  // Makes an empty commit, thereby releasing the lock on the document.
  @override
  Future<void> commitEmptyTransaction(String transaction) async {
    final commitRequest = CommitRequest(transaction: transaction);
    await _retryOnException<void>(
      'commitEmptyTransaction',
      'N.A.',
      () => _api.projects.databases.documents.commit(
        commitRequest,
        _getDatabasePath(),
      ),
      shouldRetryOnTransactionErrors: false,
    );
  }

  /// Transforms a json to a [YustDoc]
  @override
  T? transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    dynamic document,
  ) {
    return _transformDoc(docSetup, document as Document);
  }

  String _getDatabasePath() => 'projects/${Yust.projectId}/databases/(default)';

  String _getParentPath(YustDocSetup docSetup) {
    var parentPath = '${_getDatabasePath()}/documents';
    if (useSubcollections && docSetup.forEnvironment) {
      parentPath += '/$envCollectionName/${docSetup.envId}';
    }
    if (docSetup.collectionName.contains('/')) {
      final nameParts = docSetup.collectionName.split('/');
      nameParts.removeLast();
      parentPath += '/${nameParts.join('/')}';
    }
    return parentPath;
  }

  String _getCollection(YustDocSetup docSetup) {
    if (docSetup.collectionName.contains('/')) {
      return docSetup.collectionName.split('/').last;
    } else {
      return docSetup.collectionName;
    }
  }

  String _getDocumentPath(YustDocSetup docSetup, [String? id = '']) {
    return '${_getParentPath(docSetup)}/${_getCollection(docSetup)}/$id';
  }

  RunQueryRequest getQuery<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    T? startAfterDocument,
    bool forCollectionGroup = false,
    List<String>? fields,
  }) {
    final startAfterDocumentJson = startAfterDocument?.toJson();

    return RunQueryRequest(
      structuredQuery: StructuredQuery(
        from: [
          CollectionSelector(
            collectionId: _getCollection(docSetup),
            allDescendants: forCollectionGroup == true ? true : null,
          ),
        ],
        where: Filter(
          compositeFilter: CompositeFilter(
            filters:
                (forCollectionGroup
                    ? <Filter>[]
                    : _executeStaticFilters(docSetup)) +
                _executeFilters(filters),
            op: 'AND',
          ),
        ),
        orderBy: _executeOrderByList(orderBy),
        limit: limit,
        startAt: startAfterDocumentJson == null
            ? null
            : Cursor(
                // The cursor is a list of values, which are used to order the documents.
                // It needs to contain the value of every ordered field.
                values:
                    orderBy
                        ?.map(
                          (e) => e.field == '__name__'
                              ? Value(
                                  referenceValue: _getDocumentPath(
                                    docSetup,
                                    startAfterDocument?.id,
                                  ),
                                )
                              : _valueToDbValue(
                                  YustHelpers().getValueByPath(
                                    startAfterDocumentJson,
                                    e.field,
                                  ),
                                ),
                        )
                        .toList() ??
                    [],
                before: false,
              ),
        select: fields != null
            ? Projection(
                fields: fields
                    .map((field) => FieldReference(fieldPath: field))
                    .toList(),
              )
            : null,
      ),
      readTime: readTime?.toUtc().toIso8601String(),
    );
  }

  /// Extracts the id field from a document.
  String? _extractDocumentId(Document? document) {
    if (document == null) return null;

    final idValue = document.fields?['id'];
    if (idValue?.stringValue != null) {
      return idValue!.stringValue!;
    }

    throw YustException('Document has no id field: ${document.name}');
  }

  RunAggregationQueryRequest _getAggregationQuery<T extends YustDoc>(
    AggregationType type,
    YustDocSetup<T> docSetup, {
    String? fieldPath,
    List<YustFilter>? filters,
    int? upTo,
  }) {
    final countAggregation = Aggregation(
      alias: AggregationType.count.name,
      count: Count(upTo: upTo?.toString()),
    );
    final quotedFieldPath = YustHelpers().toQuotedFieldPath(fieldPath);
    return RunAggregationQueryRequest(
      structuredAggregationQuery: StructuredAggregationQuery(
        aggregations: [
          // We always include count to get the number of aggregated documents
          countAggregation,
          if (type == AggregationType.sum)
            Aggregation(
              alias: type.name,
              sum: Sum(field: FieldReference(fieldPath: quotedFieldPath)),
            ),
          if (type == AggregationType.avg)
            Aggregation(
              alias: type.name,
              avg: Avg(field: FieldReference(fieldPath: quotedFieldPath)),
            ),
        ],
        structuredQuery: StructuredQuery(
          from: [CollectionSelector(collectionId: _getCollection(docSetup))],
          where: Filter(
            compositeFilter: CompositeFilter(
              filters:
                  _executeStaticFilters(docSetup) + _executeFilters(filters),
              op: 'AND',
            ),
          ),
        ),
      ),
      readTime: readTime?.toUtc().toIso8601String(),
    );
  }

  List<Filter> _executeStaticFilters<T extends YustDoc>(
    YustDocSetup<T> docSetup,
  ) {
    final result = <Filter>[];
    if (!useSubcollections && docSetup.forEnvironment) {
      result.add(
        Filter(
          fieldFilter: FieldFilter(
            field: FieldReference(fieldPath: 'envId'),
            op: 'EQUAL',
            value: _valueToDbValue(docSetup.envId),
          ),
        ),
      );
    }
    return result;
  }

  List<Filter> _executeFilters(List<YustFilter>? filters) {
    final result = <Filter>[];
    if (filters != null) {
      for (final filter in filters) {
        if (filter.value is List && filter.value.isEmpty) {
          filter.value = null;
        }
        if ((filter.value != null) ||
            ([
              YustFilterComparator.isNull,
              YustFilterComparator.isNotNull,
            ].contains(filter.comparator))) {
          final quotedFieldPath = YustHelpers().toQuotedFieldPath(filter.field);

          final fieldFilter = FieldFilter(
            field: FieldReference(fieldPath: quotedFieldPath),
            op: filter.comparator.firestoreOperatorName,
            value: _valueToDbValue(filter.value),
          );

          if (filter.comparator == YustFilterComparator.isNull ||
              filter.comparator == YustFilterComparator.isNotNull) {
            result.add(
              Filter(
                unaryFilter: UnaryFilter(
                  field: FieldReference(fieldPath: quotedFieldPath),
                  op: filter.comparator.firestoreOperatorName,
                ),
              ),
            );
          } else {
            result.add(Filter(fieldFilter: fieldFilter));
          }
        }
      }
    }
    return result;
  }

  List<Order> _executeOrderByList(List<YustOrderBy>? orderBy) {
    return orderBy
            ?.map(
              (e) => Order(
                field: FieldReference(
                  fieldPath: YustHelpers().toQuotedFieldPath(e.field),
                ),
                direction: e.descending ? 'DESCENDING' : 'ASCENDING',
              ),
            )
            .toList() ??
        <Order>[];
  }

  /// Returns null if no data exists.
  T? _transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    Document document,
  ) {
    final json = document.fields?.map(
      (key, dbValue) => MapEntry(key, _dbValueToValue(dbValue)),
    );

    if (json == null) {
      return null;
    }

    try {
      final doc = docSetup.fromJson(json);
      doc.clearUpdateMask();
      return doc;
    } catch (e) {
      print(
        '[[WARNING]] Error Transforming JSON. Collection ${docSetup.collectionName}, Name ${document.name}: $e ($json)',
      );
      return null;
    }
  }

  Value _valueToDbValue(dynamic value) {
    if (value is List) {
      return Value(
        arrayValue: ArrayValue(
          values: value
              .map((childValue) => _valueToDbValue(childValue))
              .toList(),
        ),
      );
    }
    if (value is Map) {
      return Value(
        mapValue: MapValue(
          fields: value.map(
            (key, childValue) => MapEntry(key, _valueToDbValue(childValue)),
          ),
        ),
      );
    }
    if (value is bool) {
      return Value(booleanValue: value);
    }
    if (value is int) {
      return Value(integerValue: value.toString());
    }
    if (value is double) {
      // Round double values
      return Value(doubleValue: Yust.helpers.roundToDecimalPlaces(value));
    }
    if (value == null) {
      return Value(nullValue: 'NULL_VALUE');
    }
    if (value is ServerNow || (value is String && value.isServerNow)) {
      // server side timestamps do not work with googleapis/firestore/v1, so we use the current time instead
      return Value(timestampValue: DateTime.now().toIso8601StringWithOffset());
    }
    if (value is String && value.isIso8601String) {
      return Value(
        timestampValue: DateTime.parse(value).toIso8601StringWithOffset(),
      );
    }
    if (value is String) {
      return Value(stringValue: value);
    }
    if (value is DateTime) {
      return Value(timestampValue: value.toIso8601StringWithOffset());
    }
    late String output;
    try {
      output = jsonEncode(value);
    } catch (e) {
      output = value.toString();
    }
    throw (YustException(
      'Value can not be transformed for Firestore: $output',
    ));
  }

  dynamic _dbValueToValue(Value dbValue) {
    if (dbValue.arrayValue != null) {
      return (dbValue.arrayValue!.values ?? [])
          .map((childValue) => _dbValueToValue(childValue))
          .toList();
    } else if (dbValue.mapValue != null) {
      final map = dbValue.mapValue!.fields;
      if (map?['_seconds'] != null) {
        final seconds = int.tryParse(map!['_seconds']?.integerValue ?? '');
        final nanoseconds = int.tryParse(
          map['_nanoseconds']?.integerValue ?? '',
        );
        if (seconds == null || nanoseconds == null) return null;
        final microseconds = (seconds * 1000000 + nanoseconds / 1000).round();
        return DateTime.fromMicrosecondsSinceEpoch(
          microseconds,
          isUtc: true,
        ).toIso8601StringWithOffset();
      }
      return map?.map(
        (key, childValue) => MapEntry(key, _dbValueToValue(childValue)),
      );
    } else if (dbValue.booleanValue != null) {
      return dbValue.booleanValue;
    } else if (dbValue.integerValue != null) {
      return int.parse(dbValue.integerValue!);
    } else if (dbValue.doubleValue != null) {
      return Yust.helpers.roundToDecimalPlaces(dbValue.doubleValue!);
    } else if (dbValue.nullValue != null) {
      return null;
    } else if (dbValue.stringValue != null) {
      return dbValue.stringValue;
    } else if (dbValue.timestampValue != null) {
      return dbValue.timestampValue;
    } else {
      throw YustException(
        'Value can not be transformed from Firestore: ${jsonEncode(dbValue.toJson())}',
      );
    }
  }

  String _createDocumentId() {
    return Yust.helpers.randomString(length: 20);
  }

  /// Retries the given function if a TlsException, ClientException or YustBadGatewayException occurs.
  /// Those are network errors that can occur when the firestore is rate-limiting.
  Future<T> _retryOnException<T>(
    String fnName,
    String docPath,
    Future<T> Function() fn, {
    bool shouldRetryOnTransactionErrors = true,
    bool shouldIgnoreNotFound = false,
  }) async {
    return (await YustRetryHelper.retryOnException<T>(
          fnName,
          docPath,
          fn,
          maxTries: 16,
          actionOnExceptionList: [
            YustRetryHelper.actionOnYustException(
              shouldIgnoreNotFound: shouldIgnoreNotFound,
            ),
            YustRetryHelper.actionOnNetworkException,
            YustRetryHelper.actionOnDetailedApiRequestError(
              shouldRetryOnTransactionErrors: shouldRetryOnTransactionErrors,
              shouldIgnoreNotFound: shouldIgnoreNotFound,
            ),
          ],
          onRetriesExceeded: (lastError, fnName, docPath) => print(
            '[[ERROR]] Retried $fnName call 16 times, but still failed: $lastError for $docPath',
          ),
        ))
        as T;
  }
}
