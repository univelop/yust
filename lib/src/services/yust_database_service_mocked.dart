import 'package:rfc_6901/rfc_6901.dart';

import '../../yust.dart';
import 'yust_database_service_dart.dart';

/// A mock database service for storing docs.
class YustDatabaseServiceMocked extends YustDatabaseService {
  final _db = <String, List<Map<String, dynamic>>>{};

  /// Returns a [YustDoc] directly from the server.
  ///
  /// Be careful with offline fuctionality.
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

  /// Returns the first [YustDoc] in a list directly from the server.
  ///
  /// Be careful with offline fuctionality.
  /// The result is null if no document was found.
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

  /// Saves a document.
  ///
  /// If [merge] is false a document with the same name
  /// will be overwritten instead of trying to merge the data.
  @override
  Future<void> saveDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc, {
    bool merge = true,
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
          final pointer = JsonPointer(path);
          final newValue = pointer.read(newJsonDoc);
          jsonDoc = pointer.write(jsonDoc, newValue) as Map<String, dynamic>;
        }
        jsonDocs[index] = jsonDoc;
      }
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
    final jsonDocs = _getJSONCollection(docSetup.collectionName);
    final index = jsonDocs.indexWhere((doc) => doc['id'] == id);
    final jsonDoc = jsonDocs[index];
    for (final t in fieldTransforms) {
      final pointer = JsonPointer(t.fieldPath);
      final oldValue = pointer.read(jsonDoc) as double;
      jsonDocs[index] = pointer.write(jsonDoc, oldValue + (t.increment ?? 0))
          as Map<String, dynamic>;
    }
  }

  /// Delete a [YustDoc].
  @override
  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    final docs = _getCollection<T>(docSetup);
    docs.remove(doc);
  }

  /// Delete a [YustDoc] by the ID.
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
          .where((e) => f.isFieldMatching(JsonPointer(f.field).read(e)))
          .toList();
    }
    return collection;
  }

  List<Map<String, dynamic>> _orderBy(
    List<Map<String, dynamic>> collection,
    List<YustOrderBy>? orderBy,
  ) {
    // TODO: Implement orderBy
    for (final o in (orderBy ?? []).reversed) {}
    return collection;
  }
}
