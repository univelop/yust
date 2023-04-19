import 'dart:convert';

import 'package:googleapis/firestore/v1.dart';
import 'package:stream_transform/stream_transform.dart';

import '../extensions/date_time_extension.dart';
import '../extensions/string_extension.dart';
import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';
import '../models/yust_order_by.dart';
import '../util/yust_exception.dart';
import '../util/yust_field_transform.dart';
import '../util/yust_firestore_api.dart';
import '../util/yust_helpers.dart';
import '../yust.dart';
import 'yust_database_service_shared.dart';

/// Handels database requests for Cloud Firestore.
///
/// Using FlutterFire for Flutter Platforms (Android, iOS, Web) and GoogleAPIs for Dart-only environments.
class YustDatabaseService {
  late final FirestoreApi _api;
  late final String _projectId;
  DatabaseLogCallback? dbLogCallback;

  YustDatabaseService({this.dbLogCallback}) {
    if (YustFirestoreApi.instance != null) {
      _api = YustFirestoreApi.instance!;
    }
    if (YustFirestoreApi.projectId != null) {
      _projectId = YustFirestoreApi.projectId!;
    }
  }

  YustDatabaseService.mocked({this.dbLogCallback});

  /// Initialises a document with an id and the time it was created.
  ///
  /// Optionally an existing document can be given, which will still be
  /// assigned a new id becoming a new document if it had an id previously.
  T initDoc<T extends YustDoc>(YustDocSetup<T> docSetup, [T? doc]) {
    final id = _createDocumentId();
    return doInitDoc(docSetup, id, doc);
  }

  /// Returns a [YustDoc] from the server, if available, otherwise from the cache.
  /// The cached documents may not be up to date!
  ///
  /// Be careful with offline fuctionality.
  Future<T?> get<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    return getFromDB(docSetup, id);
  }

  /// Returns a [YustDoc] from the cache, if available, otherwise from the server.
  /// Be careful: The cached documents may not be up to date!
  ///
  /// Be careful with offline fuctionality.
  Future<T?> getFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    return getFromDB(docSetup, id);
  }

  /// Returns a [YustDoc] directly from the server.
  ///
  /// Be careful with offline fuctionality.
  Future<T?> getFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    dbLogCallback?.call(DatabaseLogAction.get, docSetup, 1);
    try {
      final response = await _api.projects.databases.documents
          .get(_getDocumentPath(docSetup, id));
      dbLogCallback?.call(DatabaseLogAction.get, docSetup, 1);
      return _transformDoc<T>(docSetup, response);
    } on ApiRequestError {
      return null;
    }
  }

  /// Returns a stream of a [YustDoc].
  ///
  /// Whenever another user makes a change, a new version of the document is returned.
  Stream<T?> getStream<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) {
    return Stream.fromFuture(getFromDB<T>(docSetup, id));
  }

  /// Returns the first [YustDoc] in a list from the server, if available, otherwise from the cache.
  /// The cached documents may not be up to date!
  ///
  /// Be careful with offline fuctionality.
  /// The result is null if no document was found.
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
  /// Be careful with offline fuctionality.
  /// The result is null if no document was found.
  Future<T?> getFirstFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    return getFirstFromDB(docSetup, filters: filters, orderBy: orderBy);
  }

  /// Returns the first [YustDoc] in a list directly from the server.
  ///
  /// Be careful with offline fuctionality.
  /// The result is null if no document was found.
  Future<T?> getFirstFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    final response = await _api.projects.databases.documents.runQuery(
        _getQuery(docSetup, filters: filters, orderBy: orderBy, limit: 1),
        _getParentPath(docSetup));

    if (response.isEmpty || response.first.document == null) {
      return null;
    }
    dbLogCallback?.call(DatabaseLogAction.get, docSetup, 1);
    return _transformDoc<T>(docSetup, response.first.document!);
  }

  /// Returns a stream of the first [YustDoc] in a list.
  ///
  /// Whenever another user make a change, a new version of the document is returned.
  /// The result is null if no document was found.
  Stream<T?> getFirstStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) {
    return Stream.fromFuture(
        getFirstFromDB<T>(docSetup, filters: filters, orderBy: orderBy));
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
  Future<List<T>> getList<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    return getListFromDB(docSetup,
        filters: filters, orderBy: orderBy, limit: limit);
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
  Future<List<T>> getListFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    return getListFromDB(docSetup,
        filters: filters, orderBy: orderBy, limit: limit);
  }

  /// Returns [YustDoc]s directly from the database.
  ///
  /// Be careful with offline fuctionality.
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
  Future<List<T>> getListFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) async {
    final response = await _api.projects.databases.documents.runQuery(
        _getQuery(docSetup, filters: filters, orderBy: orderBy, limit: limit),
        _getParentPath(docSetup));
    dbLogCallback?.call(DatabaseLogAction.get, docSetup, response.length);

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
  Stream<T> getListChunked<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int pageSize = 5000,
  }) {
    final parent = _getParentPath(docSetup);
    final url =
        '${YustFirestoreApi.rootUrl}v1/${Uri.encodeFull(parent)}:runQuery';

    Stream<Map<dynamic, dynamic>> lazyPaginationGenerator() async* {
      var isDone = false;
      var lastOffset = 0;
      while (!isDone) {
        final request = _getQuery(docSetup,
            filters: filters,
            orderBy: orderBy,
            limit: pageSize,
            offset: lastOffset);
        final body = jsonEncode(request);
        final result = await YustFirestoreApi.httpClient?.post(
          Uri.parse(url),
          body: body,
        );
        if (result == null) return;

        final response =
            List<Map<dynamic, dynamic>>.from(jsonDecode(result.body));

        dbLogCallback?.call(DatabaseLogAction.get, docSetup, response.length);

        isDone = response.length < pageSize;
        if (!isDone) lastOffset += pageSize;

        yield* Stream.fromIterable(response);
      }
    }

    return lazyPaginationGenerator().map<T?>((e) {
      if (e['document'] == null) return null;
      return _transformDoc<T>(docSetup, Document.fromJson(e['document']));
    }).whereType<T>();
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
  Stream<List<T>> getListStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    return Stream.fromFuture(getListFromDB<T>(docSetup,
        filters: filters, orderBy: orderBy, limit: limit));
  }

  /// Saves a document.
  ///
  /// If [merge] is false a document with the same name
  /// will be overwritten instead of trying to merge the data.
  /// Use [doNotCreate] to ensure that no new record is created
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
    await doc.onSave();
    await prepareSaveDoc(docSetup, doc,
        trackModification: trackModification, skipOnSave: skipOnSave);
    final yustUpdateMask = doc.updateMask;
    if (updateMask != null) updateMask.addAll(yustUpdateMask);

    if (!skipLog) {
      dbLogCallback?.call(DatabaseLogAction.save, docSetup, 1,
          id: doc.id, updateMask: updateMask ?? []);
    }
    final jsonDoc = doc.toJson();
    final dbDoc = Document(
        fields:
            jsonDoc.map((key, value) => MapEntry(key, _valueToDbValue(value))));

    // Because the Firestore REST-Api (used in the background) can't handle attributes starting with numbers,
    // e.g. 'foo.0bar', we need to escape the path-parts by using '´': '`foo`.`0bar`'
    final quotedUpdateMask = updateMask
        ?.map((path) => YustHelpers().toQuotedFieldPath(path))
        .toList();

    await _api.projects.databases.documents.patch(
      dbDoc,
      _getDocumentPath(docSetup, doc.id),
      updateMask_fieldPaths: quotedUpdateMask,
      currentDocument_exists: doNotCreate ? true : null,
    );
  }

  /// Transforms (e.g. increment, decrement) a documents fields.
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
    final documentTransform = DocumentTransform(
      fieldTransforms: firebaseFieldTransforms,
      document: _getDocumentPath(docSetup, id),
    );
    final write = Write(
        transform: documentTransform,
        currentDocument: Precondition(exists: true));
    final commitRequest = CommitRequest(writes: [write]);
    dbLogCallback?.call(DatabaseLogAction.transform, docSetup, 1,
        id: id, updateMask: fieldTransforms.map((e) => e.fieldPath).toList());

    await _api.projects.databases.documents.commit(
      commitRequest,
      _getDatabasePath(),
    );
  }

  /// Delete all [YustDoc]s in the filter.
  Future<void> deleteDocs<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
  }) async {
    final docs = await getListFromDB<T>(docSetup, filters: filters);
    dbLogCallback?.call(DatabaseLogAction.get, docSetup, docs.length);
    for (var doc in docs) {
      await deleteDoc<T>(docSetup, doc);
    }
  }

  /// Delete a [YustDoc].
  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    await doc.onDelete();
    dbLogCallback?.call(DatabaseLogAction.delete, docSetup, 1);
    await _api.projects.databases.documents
        .delete(_getDocumentPath(docSetup, doc.id));
  }

  /// Delete a [YustDoc] by the ID.
  Future<void> deleteDocById<T extends YustDoc>(
      YustDocSetup<T> docSetup, String docId) async {
    await (await get(docSetup, docId))?.onDelete();
    dbLogCallback?.call(DatabaseLogAction.delete, docSetup, 1);
    await _api.projects.databases.documents
        .delete(_getDocumentPath(docSetup, docId));
  }

  /// Initialises a [YustDoc] and saves it.
  ///
  /// If [onInitialised] is provided, it will be called and
  /// waited for after the document is initialised.
  ///
  /// An existing document can be given which will instead be initialised.
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
    dbLogCallback?.call(DatabaseLogAction.saveNew, docSetup, 1);
    await saveDoc<T>(
      docSetup,
      doc,
      removeNullValues: removeNullValues ?? docSetup.removeNullValues,
      skipLog: true,
    );

    return doc;
  }

  /// Returns a query for specified filter and order.
  dynamic getQuery<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    return _getQuery<T>(docSetup,
        filters: filters, orderBy: orderBy, limit: limit);
  }

  /// Transforms a json to a [YustDoc]
  T? transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    dynamic document,
  ) {
    return _transformDoc(docSetup, document as Document);
  }

  String _getDatabasePath() => 'projects/$_projectId/databases/(default)';

  String _getParentPath(YustDocSetup docSetup) {
    var parentPath = '${_getDatabasePath()}/documents';
    if (Yust.useSubcollections && docSetup.forEnvironment) {
      parentPath += '/${Yust.envCollectionName}/${docSetup.envId}';
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

  String _getDocumentPath(YustDocSetup docSetup, String id) {
    return '${_getParentPath(docSetup)}/${_getCollection(docSetup)}/$id';
  }

  RunQueryRequest _getQuery<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    int? offset,
  }) {
    return RunQueryRequest(
      structuredQuery: StructuredQuery(
          from: [CollectionSelector(collectionId: _getCollection(docSetup))],
          where: Filter(
              compositeFilter: CompositeFilter(
                  filters: _executeStaticFilters(docSetup) +
                      _executeFilters(filters),
                  op: 'AND')),
          orderBy: _executeOrderByList(orderBy),
          limit: limit,
          offset: offset),
    );
  }

  List<Filter> _executeStaticFilters<T extends YustDoc>(
    YustDocSetup<T> docSetup,
  ) {
    final result = <Filter>[];
    if (!Yust.useSubcollections && docSetup.forEnvironment) {
      result.add(Filter(
          fieldFilter: FieldFilter(
        field: FieldReference(fieldPath: 'envId'),
        op: 'EQUAL',
        value: _valueToDbValue(docSetup.envId),
      )));
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
            (filter.comparator == YustFilterComparator.isNull)) {
          String op;
          switch (filter.comparator) {
            case YustFilterComparator.equal:
              op = 'EQUAL';
              break;
            case YustFilterComparator.notEqual:
              op = 'NOT_EQUAL';
              break;
            case YustFilterComparator.lessThan:
              op = 'LESS_THAN';
              break;
            case YustFilterComparator.lessThanEqual:
              op = 'LESS_THAN_OR_EQUAL';
              break;
            case YustFilterComparator.greaterThan:
              op = 'GREATHER_THAN';
              break;
            case YustFilterComparator.greaterThanEqual:
              op = 'GREATHER_THAN_OR_EQUAL';
              break;
            case YustFilterComparator.arrayContains:
              op = 'ARRAY_CONTAINS';
              break;
            case YustFilterComparator.arrayContainsAny:
              op = 'ARRAY_CONTAINS_ANY';
              break;
            case YustFilterComparator.inList:
              op = 'IN';
              break;
            case YustFilterComparator.notInList:
              op = 'NOT_IN';
              break;
            case YustFilterComparator.isNull:
              op = 'IS_NULL';
              break;
            default:
              throw 'The comparator "${filter.comparator}" is not supported.';
          }
          final quotedFieldPath = YustHelpers().toQuotedFieldPath(filter.field);

          result.add(Filter(
              fieldFilter: FieldFilter(
            field: FieldReference(fieldPath: quotedFieldPath),
            op: op,
            value: _valueToDbValue(filter.value),
          )));
        }
      }
    }
    return result;
  }

  List<Order> _executeOrderByList(List<YustOrderBy>? orderBy) {
    return orderBy
            ?.map((e) => Order(
                field: FieldReference(fieldPath: e.field),
                direction: e.descending ? 'DESCENDING' : 'ASCENDING'))
            .toList() ??
        <Order>[];
  }

  /// Returns null if no data exists.
  T? _transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    Document document,
  ) {
    final json = document.fields
        ?.map((key, dbValue) => MapEntry(key, _dbValueToValue(dbValue)));

    if (json == null) {
      return null;
    }

    try {
      return docSetup.fromJson(json);
    } catch (e) {
      print(
          '[[WARNING]] Error Transforming JSON. Collection ${docSetup.collectionName}, Workspace ${docSetup.envId}: $e ($json)');
      return null;
    }
  }

  Value _valueToDbValue(dynamic value) {
    if (value is List) {
      return Value(
          arrayValue: ArrayValue(
              values: value
                  .map((childValue) => _valueToDbValue(childValue))
                  .toList()));
    } else if (value is Map) {
      return Value(
          mapValue: MapValue(
              fields: value.map((key, childValue) =>
                  MapEntry(key, _valueToDbValue(childValue)))));
    } else if (value is bool) {
      return Value(booleanValue: value);
    } else if (value is int) {
      return Value(integerValue: value.toString());
    } else if (value is double) {
      // Round double values
      return Value(doubleValue: Yust.helpers.roundToDecimalPlaces(value));
    } else if (value == null) {
      return Value(nullValue: 'NULL_VALUE');
    } else if (value is String && value.isIso8601String) {
      value = DateTime.parse(value).toIso8601StringWithOffset();
      return Value(timestampValue: value);
    } else if (value is String) {
      return Value(stringValue: value);
    } else if (value is DateTime) {
      return Value(timestampValue: value.toIso8601StringWithOffset());
    } else {
      throw (YustException('Value can not be transformed for Firestore.'));
    }
  }

  dynamic _dbValueToValue(Value dbValue) {
    if (dbValue.arrayValue != null) {
      return (dbValue.arrayValue!.values ?? []).map((childValue) {
        return _dbValueToValue(childValue);
      }).toList();
    } else if (dbValue.mapValue != null) {
      final map = dbValue.mapValue!.fields;
      if (map?['_seconds'] != null) {
        final seconds = int.tryParse(map!['_seconds']?.integerValue ?? '');
        final nanoseconds =
            int.tryParse(map['_nanoseconds']?.integerValue ?? '');
        if (seconds == null || nanoseconds == null) return null;
        final microseconds = (seconds * 1000000 + nanoseconds / 1000).round();
        return DateTime.fromMicrosecondsSinceEpoch(microseconds, isUtc: true)
            .toIso8601StringWithOffset();
      }
      return map?.map(
          (key, childValue) => MapEntry(key, _dbValueToValue(childValue)));
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
      throw (YustException('Value can not be transformed from Firestore.'));
    }
  }

  String _createDocumentId() {
    return Yust.helpers.randomString(length: 20);
  }
}
