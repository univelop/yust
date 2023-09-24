import 'dart:convert';
import '../extensions/string_extension.dart';
import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';
import '../models/yust_order_by.dart';
import '../util/yust_field_transform.dart';
import '../yust.dart';
import 'yust_database_service.dart';
import 'yust_database_service_shared.dart';

/// A mock database service for storing docs.
class YustDatabaseServiceMocked extends YustDatabaseService {
  final Future<void> Function(String docPath, Map<String, dynamic>? oldDocument,
      Map<String, dynamic>? newDocument)? onChange;

  YustDatabaseServiceMocked.mocked({this.onChange}) : super.mocked();

  final _db = <String, List<Map<String, dynamic>>>{};

  @override
  T initDoc<T extends YustDoc>(YustDocSetup<T> docSetup, [T? doc]) {
    final id = _createDocumentId();
    return doInitDoc(docSetup, id, doc);
  }

  @override
  Future<T?> get<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
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
    String id,
  ) async {
    final docs = _getCollection<T>(docSetup);
    try {
      return docs.firstWhere((doc) => doc.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<T?> getStream<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) {
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
        getFirstFromDB<T>(docSetup, filters: filters, orderBy: orderBy));
  }

  @override
  Future<List<T>> getList<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    return getListFromDB(docSetup, filters: filters, orderBy: orderBy);
  }

  @override
  Future<List<T>> getListFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    return getListFromDB(docSetup, filters: filters, orderBy: orderBy);
  }

  @override
  Future<List<T>> getListFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) async {
    var jsonDocs = _getJSONCollection(docSetup.collectionName);
    jsonDocs = _filter(jsonDocs, filters);
    jsonDocs = _orderBy(jsonDocs, orderBy);
    final docs = _jsonListToDocList(jsonDocs, docSetup);
    return docs.sublist(0, limit);
  }

  @override
  Stream<T> getListChunked<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int pageSize = 5000,
  }) {
    return Stream.fromFuture(
            getList(docSetup, filters: filters, orderBy: orderBy))
        .expand((e) => e);
  }

  @override
  Stream<List<T>> getListStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    return Stream.fromFuture(getListFromDB<T>(docSetup,
        filters: filters, orderBy: orderBy, limit: limit));
  }

  @override
  Future<int> count<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
  }) async =>
      (await getList(docSetup, filters: filters)).length;

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
    final jsonDocs = _getJSONCollection(docSetup.collectionName);
    final index = jsonDocs.indexWhere((d) => d['id'] == doc.id);
    final docJsonClone = jsonDecode(jsonEncode(doc.toJson()));
    if (index == -1 && !doNotCreate) {
      jsonDocs.add(docJsonClone);
      await onChange?.call(
        _getParentPath(docSetup, doc: doc),
        null,
        docJsonClone,
      );
    } else {
      final oldDoc = jsonDecode(jsonEncode(jsonDocs[index]));
      if (updateMask == null) {
        jsonDocs[index] = docJsonClone;
        await onChange?.call(
          _getParentPath(docSetup, doc: doc),
          oldDoc,
          docJsonClone,
        );
      } else {
        var jsonDoc = jsonDocs[index];
        final newJsonDoc = docJsonClone;
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
          jsonDocClone, oldValue + (t.increment ?? 0), unescapedPath);
      jsonDocs[index] = jsonDocClone;
      await onChange?.call(
        _getParentPath(docSetup, id: id),
        oldDoc,
        jsonDocClone,
      );
    }
  }

  @override
  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    await doc.onDelete();
    final jsonDocs = _getJSONCollection(docSetup.collectionName);
    jsonDocs.removeWhere((d) => d['id'] == doc.id);
    await onChange?.call(
      _getParentPath(docSetup, doc: doc),
      doc.toJson(),
      null,
    );
  }

  @override
  Future<void> deleteDocById<T extends YustDoc>(
      YustDocSetup<T> docSetup, String docId) async {
    final doc = await get(docSetup, docId);
    if (doc == null) return;
    await doc.onDelete();
    final jsonDocs = _getJSONCollection(docSetup.collectionName);
    jsonDocs.removeWhere((d) => d['id'] == docId);
    await onChange?.call(
      _getParentPath(docSetup, doc: doc),
      doc.toJson(),
      null,
    );
  }

  List<Map<String, dynamic>> _getJSONCollection(String collectionName) {
    if (_db[collectionName] == null) {
      _db[collectionName] = [];
    }
    return _db[collectionName]!;
  }

  List<T> _getCollection<T extends YustDoc>(
    YustDocSetup<T> docSetup,
  ) {
    return _jsonListToDocList(
        _getJSONCollection(docSetup.collectionName), docSetup);
  }

  List<T> _jsonListToDocList<T extends YustDoc>(
      List<Map<String, dynamic>> collection, YustDocSetup<T> docSetup) {
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
    var subDoc = jsonDoc;
    for (final segment in segments.sublist(0, segments.length - 1)) {
      subDoc = subDoc[segment];
    }
    subDoc[segments.last] = newValue;
  }

  dynamic _readValueInJsonDoc(Map<String, dynamic> jsonDoc, String path) {
    final segments = path.split('.');
    var subDoc = jsonDoc;
    for (final segment in segments.sublist(0, segments.length - 1)) {
      subDoc = subDoc[segment];
    }
    return subDoc[segments.last];
  }

  String _createDocumentId() {
    return Yust.helpers.randomString(length: 20);
  }

  String _getParentPath(YustDocSetup docSetup, {YustDoc? doc, String? id}) {
    var parentPath = '/documents';
    if (Yust.useSubcollections && docSetup.forEnvironment) {
      parentPath += '/${Yust.envCollectionName}/${docSetup.envId}';
    }

    return '$parentPath/${docSetup.collectionName}/${doc?.id ?? id ?? ''}';
  }
}
