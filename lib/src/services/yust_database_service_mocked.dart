import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';

import '../extensions/date_time_extension.dart';
import '../extensions/server_now.dart';
import '../extensions/string_extension.dart';
import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';
import '../models/yust_order_by.dart';
import '../util/object_helper.dart';
import '../util/yust_field_transform.dart';
import '../yust.dart';
import 'yust_database_service.dart';
import 'yust_database_service_interface.dart';
import 'yust_database_service_shared.dart';

typedef MockDB = Map<String, List<Map<String, dynamic>>>;

/// A mock database service for storing docs.
class YustDatabaseServiceMocked extends YustDatabaseService
    implements IYustDatabaseService {
  static OnChangeCallback? onChange;

  YustDatabaseServiceMocked.mocked({required Yust yust})
    : super.mocked(yust: yust) {
    dbLogCallback =
        (
          DatabaseLogAction action,
          String documentPath,
          int count, {
          String? id,
          List<String>? updateMask,
          num? aggregationResult,
        }) => statistics.dbStatisticsCallback(
          action,
          documentPath,
          count,
          id: id,
          updateMask: updateMask,
          aggregationResult: aggregationResult,
        );

    YustDatabaseServiceMocked.onChange =
        yust.onChange ?? YustDatabaseServiceMocked.onChange;
  }

  static final MockDB _db = {};

  Map<String, List<Map<String, dynamic>>> get db => _db;

  @override
  T initDoc<T extends YustDoc>(YustDocSetup<T> docSetup, [T? doc]) {
    final id = _createDocumentId();
    return doInitDoc(docSetup, id, doc);
  }

  @override
  Future<T?> get<T extends YustDoc>(YustDocSetup<T> docSetup, String id) async {
    return getFromDB(docSetup, id);
  }

  @override
  Future<T?> getFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    return getFromDB(docSetup, id);
  }

  @override
  Future<T?> getFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id, {
    String? transaction,
  }) async {
    final docs = _getCollection<T>(docSetup);
    try {
      final doc = docs.firstWhereOrNull((doc) => doc.id == id);
      dbLogCallback?.call(
        DatabaseLogAction.get,
        _getDocumentPath(docSetup),
        doc != null ? 1 : 0,
      );
      return doc;
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<T?> getStream<T extends YustDoc>(YustDocSetup<T> docSetup, String id) {
    return Stream.fromFuture(getFromDB<T>(docSetup, id));
  }

  @override
  Future<T?> getFirst<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    return getFirstFromDB(docSetup, filters: filters, orderBy: orderBy);
  }

  @override
  Future<T?> getFirstFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    return getFirstFromDB(docSetup, filters: filters, orderBy: orderBy);
  }

  @override
  Future<T?> getFirstFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    var jsonDocs = _getJSONCollection(docSetup.collectionName);
    jsonDocs = _filter(jsonDocs, filters);
    jsonDocs = _orderBy(jsonDocs, orderBy);
    final docs = _jsonListToDocList(jsonDocs, docSetup);
    dbLogCallback?.call(
      DatabaseLogAction.get,
      _getDocumentPath(docSetup),
      docs.isEmpty ? 0 : 1,
    );
    if (docs.isEmpty) {
      return null;
    } else {
      return docs.first;
    }
  }

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

  @override
  Future<List<T>> getListFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    T? startAfterDocument,
  }) async {
    final docs = _getList(
      docSetup,
      filters: filters,
      orderBy: orderBy,
      limit: limit,
      startAfterDocument: startAfterDocument,
    );
    dbLogCallback?.call(
      DatabaseLogAction.get,
      _getDocumentPath(docSetup),
      docs.length,
    );
    return docs;
  }

  @override
  Stream<T> getListChunked<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int pageSize = 300,
    T? startAfterDocument,
  }) {
    return Stream.fromFuture(
      getList(
        docSetup,
        filters: filters,
        orderBy: orderBy,
        limit: pageSize,
        startAfterDocument: startAfterDocument,
      ),
    ).expand((e) => e);
  }

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
  }) {
    return Future.value(
      _getList(
        docSetup,
        filters: filters,
        orderBy: orderBy,
        limit: limit,
        startAfterDocument: startAfterDocument,
        forAllEnvironments: true,
      ),
    );
  }

  @override
  Stream<T> getListChunkedForCollectionGroup<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int pageSize = 300,
    T? startAfterDocument,
  }) {
    return Stream.fromFuture(
      getListForCollectionGroup(
        docSetup,
        filters: filters,
        orderBy: orderBy,
        limit: pageSize,
        startAfterDocument: startAfterDocument,
      ),
    ).expand((e) => e);
  }

  @override
  Future<int> count<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    final result = _getList(docSetup, filters: filters, limit: limit).length;
    dbLogCallback?.call(
      DatabaseLogAction.aggregate,
      _getDocumentPath(docSetup),
      result,
    );
    return result;
  }

  @override
  Future<AggregationResult> sum<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String fieldPath, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    final docs = _getList(docSetup, filters: filters, limit: limit);
    final count = docs.length;
    final result = docs
        .map((e) => _getDoubleValue(e, fieldPath))
        .fold<double>(0.0, (previousValue, element) => previousValue + element);

    dbLogCallback?.call(
      DatabaseLogAction.aggregate,
      _getDocumentPath(docSetup),
      count,
      aggregationResult: result,
    );
    return (count: count, result: result);
  }

  @override
  Future<AggregationResult> avg<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String fieldPath, {
    List<YustFilter>? filters,
    int? limit,
  }) async {
    final docs = _getList(docSetup, filters: filters, limit: limit);
    final count = docs.length;
    final sum = docs
        .map((e) => _getDoubleValue(e, fieldPath))
        .fold<double>(0.0, (previousValue, element) => previousValue + element);
    final result = sum / count;

    dbLogCallback?.call(
      DatabaseLogAction.aggregate,
      _getDocumentPath(docSetup),
      count,
      aggregationResult: result,
    );
    return (count: count, result: result);
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
    await prepareSaveDoc(
      docSetup,
      doc,
      trackModification: trackModification,
      skipOnSave: skipOnSave,
    );
    final jsonDocs = _getJSONCollection(docSetup.collectionName);
    final index = jsonDocs.indexWhere((d) => d['id'] == doc.id);
    final docJsonClone = jsonDecode(jsonEncode(doc.toJson()));
    final docJsonPrepared = _prepareJsonForMockDb(docJsonClone);
    if (index == -1 && !doNotCreate) {
      jsonDocs.add(docJsonPrepared);
      await onChange?.call(
        _getParentPath(docSetup, doc: doc),
        null,
        docJsonPrepared,
      );
      dbLogCallback?.call(
        DatabaseLogAction.save,
        _getDocumentPath(docSetup),
        1,
        id: doc.id,
        updateMask: updateMask ?? [],
      );
    } else {
      final oldDoc = jsonDecode(jsonEncode(jsonDocs[index]));
      if (updateMask == null) {
        jsonDocs[index] = docJsonPrepared;
        await onChange?.call(
          _getParentPath(docSetup, doc: doc),
          oldDoc,
          docJsonPrepared,
        );
      } else {
        var jsonDoc = jsonDocs[index];
        final newJsonDoc = docJsonPrepared;
        for (final path in updateMask) {
          final newValue = _readValueInJsonDoc(newJsonDoc, path);
          _changeValueInJsonDoc(jsonDoc, newValue, path);
        }
        jsonDocs[index] = jsonDoc;
        await onChange?.call(
          _getParentPath(docSetup, doc: doc),
          oldDoc,
          jsonDoc,
        );
      }
      dbLogCallback?.call(
        DatabaseLogAction.save,
        _getDocumentPath(docSetup),
        1,
        id: doc.id,
        updateMask: updateMask ?? [],
      );
    }
  }

  @override
  Future<void> updateDocByTransform<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
    List<YustFieldTransform> fieldTransforms, {
    bool skipOnSave = false,
    bool? removeNullValues,
  }) async {
    final jsonDocs = _getJSONCollection(docSetup.collectionName);
    final index = jsonDocs.indexWhere((doc) => doc['id'] == id);
    final jsonDocClone = jsonDecode(jsonEncode(jsonDocs[index]));
    final oldDoc = jsonDecode(jsonEncode(jsonDocs[index]));

    for (final t in fieldTransforms) {
      final unescapedPath = t.fieldPath.replaceAll('`', '');
      final oldValue =
          (_readValueInJsonDoc(jsonDocClone, unescapedPath) ?? 0) as num;
      _changeValueInJsonDoc(
        jsonDocClone,
        oldValue + (t.increment ?? 0),
        unescapedPath,
      );
      jsonDocs[index] = jsonDocClone;
      await onChange?.call(
        _getParentPath(docSetup, id: id),
        oldDoc,
        jsonDocClone,
      );
    }
    dbLogCallback?.call(
      DatabaseLogAction.transform,
      _getDocumentPath(docSetup),
      1,
      id: id,
      updateMask: fieldTransforms.map((e) => e.fieldPath).toList(),
    );
  }

  @override
  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    final jsonDocs = _getJSONCollection(docSetup.collectionName);
    jsonDocs.removeWhere((d) => d['id'] == doc.id);
    await onChange?.call(
      _getParentPath(docSetup, doc: doc),
      doc.toJson(),
      null,
    );
    dbLogCallback?.call(
      DatabaseLogAction.delete,
      _getDocumentPath(docSetup),
      1,
    );
  }

  @override
  Future<void> deleteDocById<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    final doc = await get(docSetup, id);
    if (doc == null) return;
    final jsonDocs = _getJSONCollection(docSetup.collectionName);
    jsonDocs.removeWhere((d) => d['id'] == id);
    await onChange?.call(
      _getParentPath(docSetup, doc: doc),
      doc.toJson(),
      null,
    );
    dbLogCallback?.call(
      DatabaseLogAction.delete,
      _getDocumentPath(docSetup),
      1,
    );
  }

  @override
  Future<(bool, T?)> runTransactionForDocument<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String docId,
    Future<T?> Function(T doc) transaction, {
    int maxTries = 20,
    bool ignoreTransactionErrors = false,
    bool useUpdateMask = false,
  }) async {
    final doc = await get(docSetup, docId);
    if (doc == null) {
      if (ignoreTransactionErrors) {
        return (false, null);
      } else {
        throw Exception('Document not found');
      }
    }
    final newDoc = await transaction(doc);
    if (newDoc != null) {
      await saveDoc(
        docSetup,
        newDoc,
        skipOnSave: true,
        updateMask: useUpdateMask ? newDoc.updateMask.toList() : null,
      );
    }
    return (true, doc);
  }

  List<Map<String, dynamic>> _getJSONCollection(String collectionName) {
    if (_db[collectionName] == null) {
      _db[collectionName] = [];
    }
    return _db[collectionName]!;
  }

  List<T> _getCollection<T extends YustDoc>(YustDocSetup<T> docSetup) {
    return _jsonListToDocList(
      _getJSONCollection(docSetup.collectionName),
      docSetup,
    );
  }

  List<T> _jsonListToDocList<T extends YustDoc>(
    List<Map<String, dynamic>> collection,
    YustDocSetup<T> docSetup,
  ) {
    return collection
        // We clone the maps here by using jsonDecode/jsonEncode
        .map<T>((e) => docSetup.fromJson(jsonDecode(jsonEncode(e))))
        .toList();
  }

  List<Map<String, dynamic>> _filter(
    List<Map<String, dynamic>> collection,
    List<YustFilter>? filters,
  ) {
    for (final f in filters ?? []) {
      collection = collection.where((e) {
        var value = _readValueInJsonDoc(e, f.field);

        // As we are filtering the raw json, we need to make a special case for
        // DateTime fields
        if (value is String && value.isIso8601String) {
          value = DateTime.parse(value);
        }
        return f.isFieldMatching(value);
      }).toList();
    }
    return collection;
  }

  List<Map<String, dynamic>> _orderBy(
    List<Map<String, dynamic>> collection,
    List<YustOrderBy>? orderBy,
  ) {
    for (final o in (orderBy ?? []).reversed) {
      collection.sort((a, b) {
        final compare = (_readValueInJsonDoc(a, o.field) as Comparable)
            .compareTo(_readValueInJsonDoc(b, o.field) as Comparable);
        final order = o.descending ? -1 : 1;
        return order * compare;
      });
    }
    return collection;
  }

  void _changeValueInJsonDoc(
    Map<String, dynamic> jsonDoc,
    dynamic newValue,
    String path,
  ) {
    final segments = path.split('.');
    Map subDoc = jsonDoc;
    for (final segment in segments.sublist(0, segments.length - 1)) {
      if (subDoc[segment] == null) {
        subDoc[segment] = <String, dynamic>{};
      }

      subDoc = subDoc[segment];
    }
    subDoc[segments.last] = newValue;
  }

  dynamic _readValueInJsonDoc(Map<String, dynamic> jsonDoc, String path) {
    final segments = path.split('.');
    Map subDoc = jsonDoc;
    for (final segment in segments.sublist(0, segments.length - 1)) {
      if (subDoc[segment] == null) {
        return null;
      }
      subDoc = subDoc[segment];
    }
    return subDoc[segments.last];
  }

  String _createDocumentId() {
    return Yust.helpers.randomString(length: 20);
  }

  String _getParentPath(YustDocSetup docSetup, {YustDoc? doc, String? id}) {
    var parentPath = '/documents';
    if (useSubcollections && docSetup.forEnvironment) {
      parentPath += '/$envCollectionName/${docSetup.envId}';
    }

    return '$parentPath/${docSetup.collectionName}/${doc?.id ?? id ?? ''}';
  }

  double _getDoubleValue<T extends YustDoc>(T doc, String fieldPath) {
    final value = _readValueInJsonDoc(doc.toJson(), fieldPath);
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else {
      return 0.0;
    }
  }

  void clearDb() => _db.clear();

  String _getCollectionName(YustDocSetup docSetup) {
    if (docSetup.collectionName.contains('/')) {
      return docSetup.collectionName.split('/').last;
    } else {
      return docSetup.collectionName;
    }
  }

  String _getDocumentPath(YustDocSetup docSetup, [String? id = '']) {
    return '${_getParentPath(docSetup)}/${_getCollectionName(docSetup)}/$id';
  }

  List<T> _getList<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    T? startAfterDocument,
    bool forAllEnvironments = false,
  }) {
    var jsonDocs = _getJSONCollection(docSetup.collectionName);

    // Apply static filters (envId) only if not querying all environments
    if (!forAllEnvironments) {
      jsonDocs = _applyStaticFilters(jsonDocs, docSetup);
    }

    jsonDocs = _filter(jsonDocs, filters);
    jsonDocs = _orderBy(jsonDocs, orderBy);
    final docs = _jsonListToDocList(jsonDocs, docSetup);

    int startIndex = 0;
    if (startAfterDocument != null) {
      final startAfterIndex = max(
        docs.indexWhere((doc) => doc.id == startAfterDocument.id),
        0,
      );
      startIndex = startAfterIndex + 1;
    }

    final limitedDocs = docs.sublist(
      min(startIndex, docs.length),
      min((limit ?? docs.length) + startIndex, docs.length),
    );

    return limitedDocs;
  }

  List<Map<String, dynamic>> _applyStaticFilters(
    List<Map<String, dynamic>> collection,
    YustDocSetup docSetup,
  ) {
    // Apply envId filter when not using subcollections and for environment-specific collections
    if (!useSubcollections && docSetup.forEnvironment) {
      collection = collection.where((e) {
        final envId = _readValueInJsonDoc(e, 'envId');
        return envId == docSetup.envId;
      }).toList();
    }
    return collection;
  }

  Map<String, dynamic> _prepareJsonForMockDb(Map<String, dynamic> obj) {
    final modifiedObj = TraverseObject.traverseObject(obj, (currentNode) {
      final value = currentNode.value;
      // Parse ServerNow
      if (value is ServerNow || (value is String && value.isServerNow)) {
        return Yust.helpers.utcNow().toIso8601StringWithOffset();
      }
      // Parse dart DateTimes
      if (value is DateTime) {
        return value.toIso8601StringWithOffset();
      }
      // Parse ISO Timestamp Strings
      if (value is String && value.isIso8601String) {
        return DateTime.parse(value).toIso8601StringWithOffset();
      }
      // Round double values
      if (value is double) {
        return Yust.helpers.roundToDecimalPlaces(value);
      }
      return value;
    });
    return modifiedObj;
  }
}
