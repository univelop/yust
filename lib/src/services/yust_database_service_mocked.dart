import '../../yust.dart';
import 'yust_database_service.dart';

/// A mock database service for storing docs.
class YustDatabaseServiceMocked extends YustDatabaseService {
  final _db = <String, List<Map<String, dynamic>>>{};

  @override
  Future<T?> getFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    final docs = _getCollection<T>(docSetup);
    if (docs.isEmpty) {
      return null;
    } else {
      return docs.firstWhere((doc) => doc.id == id);
    }
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
    final jsonDocs = _getJSONCollection(docSetup.collectionName);
    final index = jsonDocs.indexWhere((d) => d['id'] == doc.id);
    if (index == -1 && !doNotCreate) {
      jsonDocs.add(doc.toJson());
    } else {
      if (updateMask == null) {
        jsonDocs[index] = doc.toJson();
      } else {
        var jsonDoc = jsonDocs[index];
        final newJsonDoc = doc.toJson();
        for (final path in updateMask) {
          final newValue = _readValueInJsonDoc(newJsonDoc, path);
          _changeValueInJsonDoc(jsonDoc, newValue, path);
        }
        jsonDocs[index] = jsonDoc;
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
    final jsonDoc = jsonDocs[index];
    for (final t in fieldTransforms) {
      final oldValue = _readValueInJsonDoc(jsonDoc, t.fieldPath) as double;
      _changeValueInJsonDoc(
          jsonDoc, oldValue + (t.increment ?? 0), t.fieldPath);
    }
  }

  @override
  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    final docs = _getCollection<T>(docSetup);
    docs.remove(doc);
  }

  @override
  Future<void> deleteDocById<T extends YustDoc>(
      YustDocSetup<T> docSetup, String docId) async {
    final docs = _getCollection<T>(docSetup);
    docs.removeWhere((doc) => doc.id == docId);
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
    return collection.map<T>((e) => docSetup.fromJson(e)).toList();
  }

  List<Map<String, dynamic>> _filter(
    List<Map<String, dynamic>> collection,
    List<YustFilter>? filters,
  ) {
    for (final f in filters ?? []) {
      collection = collection
          .where((e) => f.isFieldMatching(_readValueInJsonDoc(e, f.field)))
          .toList();
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
    final segments = path.split('/');
    var subDoc = jsonDoc;
    for (final segment in segments.sublist(0, segments.length - 1)) {
      subDoc = subDoc[segment];
    }
    subDoc[segments.last] = newValue;
  }

  dynamic _readValueInJsonDoc(Map<String, dynamic> jsonDoc, String path) {
    final segments = path.split('/');
    var subDoc = jsonDoc;
    for (final segment in segments) {
      subDoc = subDoc[segment];
    }
    return subDoc;
  }
}
