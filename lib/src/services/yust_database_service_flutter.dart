import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'package:collection/collection.dart';

import '../extensions/server_now.dart';
import '../extensions/string_extension.dart';
import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';
import '../models/yust_order_by.dart';
import '../util/object_helper.dart';
import '../util/yust_database_statistics.dart';
import '../util/yust_exception.dart';
import '../util/yust_field_transform.dart';
import '../util/yust_query_with_logging.dart';
import '../yust.dart';
import 'yust_database_service_shared.dart';

class YustDatabaseService {
  // The _fireStore is late because we don't want to init if, if initialized mocked.
  // (in this case the _firsStore is not used in in the mocked service and a
  // exception is a good indicator for the developer )
  late final FirebaseFirestore _fireStore;
  DatabaseLogCallback? dbLogCallback;
  YustDatabaseStatistics statistics = YustDatabaseStatistics();

  DateTime? readTime;

  // ignore: unused_field
  final Yust _yust;

  YustDatabaseService({
    required Yust yust,
    String? emulatorAddress,
  })  : _yust = yust,
        envCollectionName = yust.envCollectionName,
        useSubcollections = yust.useSubcollections,
        _fireStore = FirebaseFirestore.instance {
    dbLogCallback = (DatabaseLogAction action, String documentPath, int count,
        {String? id, List<String>? updateMask, num? aggregationResult}) {
      statistics.dbStatisticsCallback(action, documentPath, count,
          id: id, updateMask: updateMask, aggregationResult: aggregationResult);
      yust.dbLogCallback?.call(action, documentPath, count,
          id: id, updateMask: updateMask, aggregationResult: aggregationResult);
    };
  }

  /// Represents the collection name for the tenants.
  final String envCollectionName;

  /// If [useSubcollections] is set to true (default), Yust is creating Subcollections for each tenant automatically.
  final bool useSubcollections;

  YustDatabaseService.mocked({
    required Yust yust,
    String? emulatorAddress,
  })  : _yust = yust,
        envCollectionName = yust.envCollectionName,
        useSubcollections = yust.useSubcollections,
        dbLogCallback = yust.dbLogCallback {
    throw UnsupportedError('Not supported in Flutter Environment');
  }

  T initDoc<T extends YustDoc>(YustDocSetup<T> docSetup, [T? doc]) {
    final id = _fireStore.collection(_getCollectionPath(docSetup)).doc().id;
    return doInitDoc(docSetup, id, doc);
  }

  Future<T?> get<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    final result = await _fireStore
        .collection(_getCollectionPath(docSetup))
        .doc(id)
        .get(GetOptions(source: Source.serverAndCache))
        .then((docSnapshot) => _transformDoc<T>(docSetup, docSnapshot))
        .catchError((e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        print('Permission denied for doc: ${docSetup.collectionName}/$id');
        return null;
      }
      throw e;
    });
    dbLogCallback?.call(DatabaseLogAction.get, _getCollectionPath(docSetup),
        result != null ? 1 : 0,
        id: id);
    return result;
  }

  Future<T?> getFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    final doc = _fireStore.collection(_getCollectionPath(docSetup)).doc(id);
    DocumentSnapshot<Map<String, dynamic>>? docSnapshot;

    try {
      docSnapshot = await doc.get(GetOptions(source: Source.cache));
      // Check if we got a hit
      if (docSnapshot.data()?.isEmpty ?? true) throw Exception('Not in Cache!');
    }
    // Handle a missing cache entry or other firebase errors by retrying against server
    catch (_) {
      docSnapshot = await doc.get(GetOptions(source: Source.server));
    }

    dbLogCallback?.call(DatabaseLogAction.get, _getCollectionPath(docSetup),
        docSnapshot.exists ? 1 : 0,
        id: id);

    return _transformDoc<T>(docSetup, docSnapshot);
  }

  Future<T?> getFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id, {
    String? transaction,
  }) async {
    final result = await _fireStore
        .collection(_getCollectionPath(docSetup))
        .doc(id)
        .get(GetOptions(source: Source.server))
        .then((docSnapshot) => _transformDoc<T>(docSetup, docSnapshot));
    dbLogCallback?.call(DatabaseLogAction.get, _getCollectionPath(docSetup),
        result != null ? 1 : 0,
        id: id);
    return result;
  }

  Stream<T?> getStream<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) {
    return _fireStore
        .collection(_getCollectionPath(docSetup))
        .doc(id)
        .snapshots()
        .map((docSnapshot) {
      dbLogCallback?.call(
        DatabaseLogActionExtension.fromSnapshot(docSnapshot),
        docSnapshot.reference.parent.path,
        docSnapshot.exists ? 1 : 0,
      );
      return _transformDoc(docSetup, docSnapshot);
    });
  }

  Future<T?> getFirst<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    var query =
        getQuery(docSetup, filters: filters, orderBy: orderBy, limit: 1);
    final snapshot = await query.get(GetOptions(source: Source.serverAndCache));
    T? doc;

    if (snapshot.docs.isNotEmpty) {
      doc = _transformDoc(docSetup, snapshot.docs.first);
    }
    return doc;
  }

  Future<T?> getFirstFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    var query =
        getQuery(docSetup, filters: filters, orderBy: orderBy, limit: 1);

    QuerySnapshot<Object?>? snapshot;
    try {
      snapshot = await query.get(GetOptions(source: Source.cache));
      // Check if we got a hit
      if (snapshot.docs.isEmpty) throw Exception('Not in Cache');
    }
    // Handle a missing cache entry or other firebase errors by retrying against server
    catch (_) {
      snapshot = await query.get(GetOptions(source: Source.server));
    }

    T? doc;

    if (snapshot.docs.isNotEmpty) {
      doc = _transformDoc(docSetup, snapshot.docs[0]);
    }
    return doc;
  }

  Future<T?> getFirstFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    var query =
        getQuery(docSetup, filters: filters, orderBy: orderBy, limit: 1);
    final snapshot = await query.get(GetOptions(source: Source.server));
    T? doc;

    if (snapshot.docs.isNotEmpty) {
      doc = _transformDoc(docSetup, snapshot.docs[0]);
    }
    return doc;
  }

  Stream<T?> getFirstStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) {
    var query =
        getQuery(docSetup, filters: filters, orderBy: orderBy, limit: 1);

    return query.snapshots().map<T?>((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return _transformDoc(docSetup, snapshot.docs[0]);
      } else {
        return null;
      }
    });
  }

  Future<List<T>> getList<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    var query =
        getQuery(docSetup, orderBy: orderBy, filters: filters, limit: limit);

    return query
        .get(GetOptions(source: Source.serverAndCache))
        .then((snapshot) {
      return snapshot.docs
          .map((docSnapshot) => _transformDoc(docSetup, docSnapshot))
          .whereType<T>()
          .toList();
    });
  }

  Future<List<T>> getListFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) async {
    var query =
        getQuery(docSetup, orderBy: orderBy, filters: filters, limit: limit);

    QuerySnapshot<Object?>? snapshot;

    try {
      snapshot = await query.get(GetOptions(source: Source.cache));
      // Check if we got a hit
      if (snapshot.docs.isEmpty) throw Exception('Not in Cache');
    }
    // Handle a missing cache entry or other firebase errors by retrying against server
    catch (_) {
      snapshot = await query.get(GetOptions(source: Source.server));
    }

    return snapshot.docs
        .map((docSnapshot) => _transformDoc(docSetup, docSnapshot))
        .whereType<T>()
        .toList();
  }

  Future<List<T>> getListFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) async {
    var query =
        getQuery(docSetup, orderBy: orderBy, filters: filters, limit: limit);

    final snapshot = await query.get(GetOptions(source: Source.server));
    return snapshot.docs
        .map((docSnapshot) => _transformDoc(docSetup, docSnapshot))
        .whereType<T>()
        .toList();
  }

  Stream<List<T>> getListStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    var query =
        getQuery(docSetup, orderBy: orderBy, filters: filters, limit: limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((docSnapshot) => _transformDoc(docSetup, docSnapshot))
          .whereType<T>()
          .toList();
    });
  }

  Future<List<String>> getDocumentIds<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) async {
    throw UnimplementedError();
  }

  Stream<String> getDocumentIdsChunked<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int pageSize = 300,
  }) {
    throw UnimplementedError();
  }

  Future<int?> count<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    var query = getQuery(docSetup, filters: filters, limit: limit);
    final snapshot = await query.count().get();

    return snapshot.count ?? 0;
  }

  Future<AggregationResult> sum<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String fieldPath, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    var query = getQuery(docSetup, filters: filters, limit: limit);
    final snapshot = await query.aggregate(cf.sum(fieldPath), cf.count()).get();
    return (count: snapshot.count ?? 0, result: snapshot.getSum(fieldPath));
  }

  Future<AggregationResult> avg<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String fieldPath, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    var query = getQuery(docSetup, filters: filters);
    final snapshot =
        await query.aggregate(cf.average(fieldPath), cf.count()).get();
    return (count: snapshot.count ?? 0, result: snapshot.getAverage(fieldPath));
  }

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
    var collection = _fireStore.collection(_getCollectionPath(docSetup));
    await prepareSaveDoc(docSetup, doc,
        trackModification: trackModification, skipOnSave: skipOnSave);
    final yustUpdateMask = doc.updateMask;
    if (updateMask != null) {
      updateMask.addAll(yustUpdateMask);
      merge = null;
    }

    final jsonDoc = doc.toJson();

    final modifiedDoc = _prepareJsonForFirebase(
      jsonDoc,
      removeNullValues: removeNullValues ?? docSetup.removeNullValues,
    );
    if (doNotCreate) {
      try {
        await collection.doc(doc.id).update(modifiedDoc);
      } on FirebaseException catch (e) {
        if (e.code == 'not-found') {
          print(
              'Exception Ignored: doNotCreate was set, but doc does not exist: ${doc.id}');
        } else {
          rethrow;
        }
      }
    } else {
      await collection
          .doc(doc.id)
          .set(modifiedDoc, SetOptions(merge: merge, mergeFields: updateMask));
    }
    if (!skipLog) {
      dbLogCallback?.call(
          DatabaseLogAction.save, _getCollectionPath(docSetup), 1,
          id: doc.id, updateMask: updateMask ?? []);
    }
  }

  /// Transforms (e.g. increment, decrement) a documents fields.
  Future<void> updateDocByTransform<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
    List<YustFieldTransform> fieldTransforms, {
    bool skipOnSave = false,
    bool? removeNullValues,
  }) async {
    var collection = _fireStore.collection(_getCollectionPath(docSetup));

    final update = _transformsToFieldValueMap(fieldTransforms);

    await collection.doc(id).update(update);
    dbLogCallback?.call(
        DatabaseLogAction.transform, _getCollectionPath(docSetup), 1,
        id: id, updateMask: fieldTransforms.map((e) => e.fieldPath).toList());
  }

  Map<String, dynamic> _prepareJsonForFirebase(
    Map<String, dynamic> obj, {
    bool removeNullValues = true,
  }) {
    final modifiedObj = TraverseObject.traverseObject(obj, (currentNode) {
      // Remove null'ed values from map
      if (removeNullValues &&
          !currentNode.info.isInList &&
          currentNode.value == null) {
        return FieldValue.delete();
      }
      // Parse ServerNow
      if (currentNode.value is ServerNow ||
          (currentNode.value is String &&
              (currentNode.value as String).isServerNow)) {
        return FieldValue.serverTimestamp();
      }
      // Parse dart DateTimes
      if (currentNode.value is DateTime) {
        return Timestamp.fromDate(currentNode.value);
      }
      // Parse ISO Timestamp Strings
      if (currentNode.value is String &&
          (currentNode.value as String).isIso8601String) {
        return Timestamp.fromDate(DateTime.parse(currentNode.value));
      }
      // Round double values
      if (currentNode.value is double) {
        return Yust.helpers.roundToDecimalPlaces(currentNode.value);
      }
      return currentNode.value;
    });
    return modifiedObj;
  }

  Stream<T> getListChunked<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int pageSize = 300,
  }) async* {
    final unequalFilters = (filters ?? [])
        .whereNot((filter) =>
            YustFilterComparator.equalityFilters.contains(filter.comparator))
        .toSet()
        .toList();

    assert(!((unequalFilters.isNotEmpty) && (orderBy?.isNotEmpty ?? false)),
        'You can\'t use orderBy and unequal filters at the same time');

    // Calculate orderBy from all unequal filters
    if (unequalFilters.isNotEmpty) {
      orderBy = unequalFilters
          .map((e) => YustOrderBy(field: e.field))
          .toSet()
          .toList();
    }

    var isDone = false;
    DocumentSnapshot? lastDoc;
    while (!isDone) {
      var query = getQuery(docSetup,
          filters: filters, orderBy: orderBy, limit: pageSize);
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot =
          await query.get(GetOptions(source: Source.serverAndCache));

      for (final doc in snapshot.docs) {
        final transformedDoc = _transformDoc<T>(docSetup, doc);
        if (transformedDoc != null) {
          yield transformedDoc;
        }
      }

      lastDoc = snapshot.docs.lastOrNull;
      isDone = snapshot.docs.length < pageSize;
    }
  }

  Future<void> deleteDocs<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
  }) async {
    final docs = await getListFromDB<T>(docSetup, filters: filters);
    for (var doc in docs) {
      await deleteDoc<T>(docSetup, doc);
    }
  }

  Future<int> deleteDocsAsBatch<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) async {
    var query =
        getQuery(docSetup, filters: filters, orderBy: orderBy, limit: limit);
    final snapshot = await query.get(GetOptions(source: Source.server));
    final batch = _fireStore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    dbLogCallback?.call(DatabaseLogAction.delete, _getCollectionPath(docSetup),
        snapshot.docs.length);
    return snapshot.docs.length;
  }

  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    final docRef =
        _fireStore.collection(_getCollectionPath(docSetup)).doc(doc.id);
    await docRef.delete();
    dbLogCallback?.call(
        DatabaseLogAction.delete, _getCollectionPath(docSetup), 1,
        id: doc.id);
  }

  Future<void> deleteDocById<T extends YustDoc>(
      YustDocSetup<T> docSetup, String docId) async {
    final docRef =
        _fireStore.collection(_getCollectionPath(docSetup)).doc(docId);
    await docRef.delete();
    dbLogCallback?.call(
        DatabaseLogAction.delete, _getCollectionPath(docSetup), 1,
        id: docId);
  }

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
        DatabaseLogAction.saveNew, _getCollectionPath(docSetup), 1,
        id: doc.id);

    return doc;
  }

  /// Reads a document, executes a function and saves the document as a transaction.
  Future<(bool, T?)> runTransactionForDocument<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String docId,
    Future<T?> Function(T doc) transaction, {
    int maxTries = 20,
    bool ignoreTransactionErrors = false,
    bool useUpdateMask = false,
  }) async {
    throw YustException('Not implemented for flutter');
  }

  /// Begins a transaction.
  Future<String> beginTransaction() async {
    throw YustException('Not implemented for flutter');
  }

  /// Saves a YustDoc and finishes a transaction.
  Future<void> commitTransaction(
      String transaction, YustDocSetup docSetup, YustDoc doc,
      {bool useUpdateMask = false}) async {
    throw YustException('Not implemented for flutter');
  }

  Future<void> commitEmptyTransaction(String transaction) async {
    throw YustException('Not implemented for flutter');
  }

  T? transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    dynamic document,
  ) {
    return _transformDoc(docSetup, document as DocumentSnapshot);
  }

  String _getCollectionPath(YustDocSetup docSetup) {
    var collectionPath = '';
    if (useSubcollections && docSetup.forEnvironment) {
      collectionPath += '$envCollectionName/${docSetup.envId}/';
    }
    collectionPath += docSetup.collectionName;

    return collectionPath;
  }

  Query getQuery<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    final path = _getCollectionPath(docSetup);
    Query query = _fireStore.collection(path);
    if (dbLogCallback != null) {
      query = YustQueryWithLogging(dbLogCallback!, query, path);
    }
    query = _executeStaticFilters(query, docSetup);
    query = _executeFilters(query, filters);
    query = _executeOrderByList(query, orderBy);
    if (limit != null) {
      query = query.limit(limit);
    }

    return query;
  }

  Query _executeStaticFilters<T extends YustDoc>(
    Query query,
    YustDocSetup<T> docSetup,
  ) {
    if (!useSubcollections && docSetup.forEnvironment) {
      query = _filterForEnvironment(query, docSetup.envId!);
    }

    return query;
  }

  Query _filterForEnvironment(Query query, String envId) =>
      query.where('envId', isEqualTo: envId);

  Query _executeFilters(Query query, List<YustFilter>? filters) {
    if (filters != null) {
      filters = filters.toSet().toList();
      for (final filter in filters) {
        if (filter.value is List && filter.value.isEmpty) {
          filter.value = null;
        }
        if ((filter.value != null) ||
            ([YustFilterComparator.isNull, YustFilterComparator.isNotNull]
                .contains(filter.comparator))) {
          switch (filter.comparator) {
            case YustFilterComparator.equal:
              query = query.where(filter.field, isEqualTo: filter.value);
              break;
            case YustFilterComparator.notEqual:
              query = query.where(filter.field, isNotEqualTo: filter.value);
              break;
            case YustFilterComparator.lessThan:
              query = query.where(filter.field, isLessThan: filter.value);
              break;
            case YustFilterComparator.lessThanEqual:
              query =
                  query.where(filter.field, isLessThanOrEqualTo: filter.value);
              break;
            case YustFilterComparator.greaterThan:
              query = query.where(filter.field, isGreaterThan: filter.value);
              break;
            case YustFilterComparator.greaterThanEqual:
              query = query.where(filter.field,
                  isGreaterThanOrEqualTo: filter.value);
              break;
            case YustFilterComparator.arrayContains:
              query = query.where(filter.field, arrayContains: filter.value);
              break;
            case YustFilterComparator.arrayContainsAny:
              query = query.where(filter.field, arrayContainsAny: filter.value);
              break;
            case YustFilterComparator.inList:
              query = query.where(filter.field, whereIn: filter.value);
              break;
            case YustFilterComparator.notInList:
              query = query.where(filter.field, whereNotIn: filter.value);
              break;
            case YustFilterComparator.isNull:
              query = query.where(filter.field, isNull: true);
              break;
            case YustFilterComparator.isNotNull:
              query = query.where(filter.field, isNull: false);
              break;
          }
        }
      }
    }
    return query;
  }

  Query _executeOrderByList(Query query, List<YustOrderBy>? orderBy) {
    if (orderBy != null) {
      for (final order in orderBy) {
        query = query.orderBy(order.field, descending: order.descending);
      }
    }
    return query;
  }

  T? _transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    DocumentSnapshot snapshot,
  ) {
    if (snapshot.exists == false) {
      return null;
    }
    final data = snapshot.data();
    if (data is Map<String, dynamic>) {
      // Convert Timestamps to ISOStrings
      final modifiedData = TraverseObject.traverseObject(data, (currentNode) {
        // Convert Timestamp to Iso8601-String, as this is the format json_serializable expects
        if (currentNode.value is Timestamp) {
          return (currentNode.value as Timestamp)
              .toDate()
              .toUtc()
              .toIso8601String();
        }

        // Round double values
        if (currentNode.value is double) {
          return Yust.helpers.roundToDecimalPlaces(currentNode.value);
        }
        return currentNode.value;
      });
      try {
        final doc = docSetup.fromJson(modifiedData);
        doc.clearUpdateMask();
        return doc;
      } catch (e) {
        print('[[WARNING]] Error Transforming JSON $e');
        return null;
      }
    }
    return null;
  }

  static Map<String, dynamic> _transformsToFieldValueMap(
      List<YustFieldTransform> transforms) {
    final map = <String, dynamic>{};
    for (final transform in transforms) {
      final fieldValue = transform.toNativeTransform();
      if (fieldValue == null) continue;
      map[transform.fieldPath] = fieldValue;
    }
    return map;
  }
}
