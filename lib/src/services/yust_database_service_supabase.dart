import 'package:supabase/supabase.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';
import '../models/yust_order_by.dart';
import '../util/object_helper.dart';
import '../util/yust_database_statistics.dart';
import '../util/yust_exception.dart';
import '../util/yust_field_transform.dart';
import '../yust.dart';
import 'yust_database_service.dart';
import 'yust_database_service_shared.dart';

class YustDatabaseServiceSupabase extends YustDatabaseService {
  late final SupabaseClient _supabase;
  DatabaseLogCallback? dbLogCallback;
  YustDatabaseStatistics statistics = YustDatabaseStatistics();

  DateTime? readTime;

  // ignore: unused_field
  final Yust _yust;

  YustDatabaseServiceSupabase({
    required super.yust,
    String? emulatorAddress,
  })  : _yust = yust,
        _supabase = SupabaseClient(
          Yust.supabaseUrl ?? '',
          Yust.supabaseKey ?? '',
        ),
        envCollectionName = yust.envCollectionName,
        useSubcollections = yust.useSubcollections;

  /// Represents the collection name for the tenants.
  final String envCollectionName;

  /// If [useSubcollections] is set to true (default), Yust is creating Subcollections for each tenant automatically.
  final bool useSubcollections;

  @override
  T initDoc<T extends YustDoc>(YustDocSetup<T> docSetup, [T? doc]) {
    final id = Yust.helpers.randomString(length: 20);
    return doInitDoc(docSetup, id, doc);
  }

  @override
  Future<T?> get<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    final result = await _supabase
        .from(docSetup.collectionName)
        .select()
        .eq('id', id)
        .single();
    try {
      return _transformDoc<T>(docSetup, result);
    } catch (e) {
      print('[[WARNING]] Error Transforming JSON $e');
      return null;
    }
  }

  @override
  Future<T?> getFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    return get(docSetup, id);
  }

  @override
  Future<T?> getFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id, {
    String? transaction,
  }) async {
    return get(docSetup, id);
  }

  @override
  Stream<T?> getStream<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) {
    return _supabase
        .from(docSetup.collectionName)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((docSnapshot) {
          return _transformDoc<T>(docSetup, docSnapshot.first);
        });
  }

  @override
  Future<T?> getFirst<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    final result = await _supabase
        .from(docSetup.collectionName)
        .select()
        // TODO: Add filters and orderBy
        .single();
    try {
      return _transformDoc<T>(docSetup, result);
    } catch (e) {
      print('[[WARNING]] Error Transforming JSON $e');
      return null;
    }
  }

  @override
  Future<T?> getFirstFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    return getFirst(docSetup, filters: filters, orderBy: orderBy);
  }

  @override
  Future<T?> getFirstFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    return getFirst(docSetup, filters: filters, orderBy: orderBy);
  }

  Stream<T?> getFirstStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) {
    return _supabase.from(docSetup.collectionName).stream(primaryKey: ['id'])
        // TODO: Add filters and orderBy
        .map((docSnapshot) {
      return _transformDoc<T>(docSetup, docSnapshot.first);
    });
  }

  @override
  Future<List<T>> getList<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) async {
    final result = await _supabase.from(docSetup.collectionName).select();
    // TODO: Add filters and orderBy

    return result
        .map((docSnapshot) => _transformDoc<T>(docSetup, docSnapshot))
        .whereType<T>()
        .toList();
  }

  @override
  Future<List<T>> getListFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) async {
    return getList(docSetup, filters: filters, orderBy: orderBy, limit: limit);
  }

  @override
  Future<List<T>> getListFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) async {
    return getList(docSetup, filters: filters, orderBy: orderBy, limit: limit);
  }

  Stream<List<T>> getListStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    final tableName = docSetup.collectionName.split('/')[1];
    final result = _supabase.from(tableName).stream(primaryKey: ['id']);
    // TODO: Add filters and orderBy

    return result.map((docSnapshots) {
      return docSnapshots
          .map((docSnapshot) {
            print(docSnapshot);
            return _transformDoc<T>(docSetup, docSnapshot);
          })
          .whereType<T>()
          .toList();
    });
  }

  @override
  Future<int> count<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    return await _supabase.from(docSetup.collectionName).count();
  }

  @override
  Future<AggregationResult> sum<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String fieldPath, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    throw YustException('Not implemented');
  }

  @override
  Future<AggregationResult> avg<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String fieldPath, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    throw YustException('Not implemented');
  }

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
    await doc.onSave();
    await prepareSaveDoc(docSetup, doc,
        trackModification: trackModification, skipOnSave: skipOnSave);
    final yustUpdateMask = doc.updateMask;
    if (updateMask != null) {
      updateMask.addAll(yustUpdateMask);
      merge = null;
    }

    final jsonDoc = doc.toJson();

    final modifiedDoc = _prepareJsonForSupabase(
      jsonDoc,
      removeNullValues: removeNullValues ?? docSetup.removeNullValues,
    );
    if (doNotCreate) {
      await _supabase.from(docSetup.collectionName).update(modifiedDoc);
      // TODO: Add updateMask
      // TODO: Error handling
    } else {
      await _supabase.from(docSetup.collectionName).upsert(modifiedDoc);
      // TODO: Add updateMask
    }
    if (!skipLog) {
      dbLogCallback?.call(
          DatabaseLogAction.save, _getCollectionPath(docSetup), 1,
          id: doc.id, updateMask: updateMask ?? []);
    }
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
    throw YustException('Not implemented');
  }

  Map<String, dynamic> _prepareJsonForSupabase(
    Map<String, dynamic> obj, {
    bool removeNullValues = true,
  }) {
    final modifiedObj = TraverseObject.traverseObject(obj, (currentNode) {
      // Round double values
      if (currentNode.value is double) {
        return Yust.helpers.roundToDecimalPlaces(currentNode.value);
      }
      return currentNode.value;
    });
    return modifiedObj;
  }

  @override
  Stream<T> getListChunked<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int pageSize = 300,
  }) async* {
    throw YustException('Not implemented');
  }

  @override
  Future<void> deleteDocs<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
  }) async {
    final docs = await getListFromDB<T>(docSetup, filters: filters);
    for (var doc in docs) {
      await deleteDoc<T>(docSetup, doc);
    }
  }

  @override
  Future<int> deleteDocsAsBatch<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) async {
    // var query =
    //     getQuery(docSetup, filters: filters, orderBy: orderBy, limit: limit);
    // final snapshot = await query.get(GetOptions(source: Source.server));
    // final batch = _fireStore.batch();
    // for (final doc in snapshot.docs) {
    //   batch.delete(doc.reference);
    // }
    // await batch.commit();
    // dbLogCallback?.call(DatabaseLogAction.delete, _getCollectionPath(docSetup),
    //     snapshot.docs.length);
    // return snapshot.docs.length;
    throw YustException('Not implemented');
  }

  @override
  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    // await doc.onDelete();
    // final docRef =
    //     _fireStore.collection(_getCollectionPath(docSetup)).doc(doc.id);
    // await docRef.delete();
    // dbLogCallback?.call(
    //     DatabaseLogAction.delete, _getCollectionPath(docSetup), 1,
    //     id: doc.id);
    throw YustException('Not implemented');
  }

  @override
  Future<void> deleteDocById<T extends YustDoc>(
      YustDocSetup<T> docSetup, String docId) async {
    // await (await get(docSetup, docId))?.onDelete();
    // final docRef =
    //     _fireStore.collection(_getCollectionPath(docSetup)).doc(docId);
    // await docRef.delete();
    // dbLogCallback?.call(
    //     DatabaseLogAction.delete, _getCollectionPath(docSetup), 1,
    //     id: docId);
    throw YustException('Not implemented');
  }

  @override
  Future<T> saveNewDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    required T doc,
    Future<void> Function(T)? onInitialised,
    bool? removeNullValues,
  }) async {
    await saveDoc<T>(
      docSetup,
      doc,
      removeNullValues: removeNullValues ?? docSetup.removeNullValues,
      skipLog: true,
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

  String _getCollectionPath(YustDocSetup docSetup) {
    var collectionPath = '';
    if (useSubcollections && docSetup.forEnvironment) {
      collectionPath += '$envCollectionName/${docSetup.envId}/';
    }
    collectionPath += docSetup.collectionName;

    return collectionPath;
  }

  T? _transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    Map<String, dynamic> data,
  ) {
    // Convert Timestamps to ISOStrings
    final modifiedData = TraverseObject.traverseObject(data, (currentNode) {
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
}
