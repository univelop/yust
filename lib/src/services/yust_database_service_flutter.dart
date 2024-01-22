import 'package:cloud_firestore/cloud_firestore.dart';

import '../extensions/string_extension.dart';
import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';
import '../models/yust_order_by.dart';
import '../util/object_helper.dart';
import '../util/yust_exception.dart';
import '../util/yust_field_transform.dart';
import '../yust.dart';
import 'yust_database_service_shared.dart';

class YustDatabaseService {
  // The _fireStore is late because we don't want to init if, if initialized mocked.
  // (in this case the _firsStore is not used in in the mocked service and a
  // exception is a good indicator for the developer )
  late final FirebaseFirestore _fireStore;
  DatabaseLogCallback? dbLogCallback;

  YustDatabaseService({this.dbLogCallback})
      : _fireStore = FirebaseFirestore.instance;

  YustDatabaseService.mocked({this.dbLogCallback});

  T initDoc<T extends YustDoc>(YustDocSetup<T> docSetup, [T? doc]) {
    final id = _fireStore.collection(_getCollectionPath(docSetup)).doc().id;
    return doInitDoc(docSetup, id, doc);
  }

  Future<T?> get<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) {
    return _fireStore
        .collection(_getCollectionPath(docSetup))
        .doc(id)
        .get(GetOptions(source: Source.serverAndCache))
        .then((docSnapshot) => _transformDoc<T>(docSetup, docSnapshot));
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
    return _transformDoc<T>(docSetup, docSnapshot);
  }

  Future<T?> getFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id, {
    String? transaction,
  }) {
    return _fireStore
        .collection(_getCollectionPath(docSetup))
        .doc(id)
        .get(GetOptions(source: Source.server))
        .then((docSnapshot) => _transformDoc<T>(docSetup, docSnapshot));
  }

  Stream<T?> getStream<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) {
    return _fireStore
        .collection(_getCollectionPath(docSetup))
        .doc(id)
        .snapshots()
        .map((docSnapshot) => _transformDoc(docSetup, docSnapshot));
  }

  Future<T?> getFirst<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    var query =
        _getQuery(docSetup, filters: filters, orderBy: orderBy, limit: 1);
    final snapshot = await query.get(GetOptions(source: Source.serverAndCache));
    T? doc;

    if (snapshot.docs.isNotEmpty) {
      doc = _transformDoc(docSetup, snapshot.docs[0]);
    }
    return doc;
  }

  Future<T?> getFirstFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    var query =
        _getQuery(docSetup, filters: filters, orderBy: orderBy, limit: 1);

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
        _getQuery(docSetup, filters: filters, orderBy: orderBy, limit: 1);
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
        _getQuery(docSetup, filters: filters, orderBy: orderBy, limit: 1);

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
        _getQuery(docSetup, orderBy: orderBy, filters: filters, limit: limit);

    return query
        .get(GetOptions(source: Source.serverAndCache))
        .then((snapshot) {
      // print('Get docs once: ${docSetup.collectionName}');
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
        _getQuery(docSetup, orderBy: orderBy, filters: filters, limit: limit);

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
  }) {
    var query =
        _getQuery(docSetup, orderBy: orderBy, filters: filters, limit: limit);

    return query.get(GetOptions(source: Source.server)).then((snapshot) {
      return snapshot.docs
          .map((docSnapshot) => _transformDoc(docSetup, docSnapshot))
          .whereType<T>()
          .toList();
    });
  }

  Stream<List<T>> getListStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    var query =
        _getQuery(docSetup, orderBy: orderBy, filters: filters, limit: limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((docSnapshot) => _transformDoc(docSetup, docSnapshot))
          .whereType<T>()
          .toList();
    });
  }

  Future<int?> count<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
  }) async {
    var query = _getQuery(docSetup, filters: filters);
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<double> sum<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String fieldPath, {
    List<YustFilter>? filters,
  }) async {
    throw YustException('Not implemented for flutter');
    // Wait for https://github.com/firebase/flutterfire/pull/11757 to be merged
    // var query = _getQuery(docSetup, filters: filters);
    // final snapshot = await query.sum(fieldPath).get();
    // return snapshot.count;
  }

  Future<double> avg<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String fieldPath, {
    List<YustFilter>? filters,
  }) async {
    throw YustException('Not implemented for flutter');
    // Wait for https://github.com/firebase/flutterfire/pull/11757 to be merged
    // var query = _getQuery(docSetup, filters: filters);
    // final snapshot = await query.average(fieldPath).get();
    // return snapshot.count;
  }

  Future<void> saveDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc, {
    bool? merge = true,
    bool? trackModification,
    bool skipOnSave = false,
    bool? removeNullValues,
    List<String>? updateMask,
    bool doNotCreate = false,
  }) async {
    await doc.onSave();
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
    if (doNotCreate && (await get(docSetup, doc.id)) == null) return;
    await collection
        .doc(doc.id)
        .set(modifiedDoc, SetOptions(merge: merge, mergeFields: updateMask));
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
    int pageSize = 5000,
  }) async* {
    var isDone = false;
    DocumentSnapshot? lastDoc;
    while (!isDone) {
      var query = _getQuery(docSetup,
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
        _getQuery(docSetup, filters: filters, orderBy: orderBy, limit: limit);
    final snapshot = await query.get(GetOptions(source: Source.server));
    final batch = _fireStore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snapshot.docs.length;
  }

  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    await doc.onDelete();
    final docRef =
        _fireStore.collection(_getCollectionPath(docSetup)).doc(doc.id);
    await docRef.delete();
  }

  Future<void> deleteDocById<T extends YustDoc>(
      YustDocSetup<T> docSetup, String docId) async {
    await (await get(docSetup, docId))?.onDelete();
    final docRef =
        _fireStore.collection(_getCollectionPath(docSetup)).doc(docId);
    await docRef.delete();
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
    );

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

  dynamic getQuery<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    return _getQuery<T>(docSetup,
        filters: filters, orderBy: orderBy, limit: limit);
  }

  T? transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    dynamic document,
  ) {
    return _transformDoc(docSetup, document as DocumentSnapshot);
  }

  String _getCollectionPath(YustDocSetup docSetup) {
    var collectionPath = '';
    if (Yust.useSubcollections && docSetup.forEnvironment) {
      collectionPath += '${Yust.envCollectionName}/${docSetup.envId}/';
    }
    collectionPath += docSetup.collectionName;
    return collectionPath;
  }

  Query<Object?> _getQuery<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    Query query = _fireStore.collection(_getCollectionPath(docSetup));
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
    if (!Yust.useSubcollections && docSetup.forEnvironment) {
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
            default:
              throw 'The comparator "${filter.comparator}" is not supported.';
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
