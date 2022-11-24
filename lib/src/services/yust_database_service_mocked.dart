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
    final docs = _getCollection<T>(docSetup.collectionName);
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
    // TODO: Use filter and order by
    final docs = _getCollection<T>(docSetup.collectionName);
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
    return _getCollection<T>(docSetup.collectionName);
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
    // TODO: Change doc
    final docs = _getCollection<T>(docSetup.collectionName);
    if (!doNotCreate && !docs.contains(doc)) {
      docs.add(doc);
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
    // TODO: Mocked
  }

  /// Delete a [YustDoc].
  @override
  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    final docs = _getCollection<T>(docSetup.collectionName);
    docs.remove(doc);
  }

  /// Delete a [YustDoc] by the ID.
  @override
  Future<void> deleteDocById<T extends YustDoc>(
      YustDocSetup<T> docSetup, String docId) async {
    final docs = _getCollection<T>(docSetup.collectionName);
    docs.removeWhere((doc) => doc.id == docId);
  }

  List<T> _getCollection<T extends YustDoc>(String collectionName) {
    if (_db[collectionName] == null) {
      _db[collectionName] = [];
    }
    return List<T>.from(_db[collectionName]!);
  }
}
