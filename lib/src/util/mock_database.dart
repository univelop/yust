import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';

/// A mock database for storing docs.
///
/// The database does not store the records in Firestore.
/// Take care: Filters, sorting and limits are not working in the
/// first version.
class MockDatabase {
  final _db = <String, List<dynamic>>{};

  /// Returns [YustDoc]s directly from the database.
  ///
  /// Be careful with offline fuctionality.
  ///
  /// [docSetup] is used to read the collection path.
  ///
  /// [filters] each entry represents a condition that has to be met.
  /// All of those conditions must be true for each returned entry.
  ///
  /// Consists at first of the column name followed by either 'ASC' or 'DESC'.
  /// Multiple of those entries can be repeated.
  ///
  /// [limit] can be passed to reduce loading time
  Future<List<T>> getDocsOnce<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
    int? limit,
  }) async {
    return _getCollection<T>(docSetup.collectionName);
  }

  /// Returns a [YustDoc] directly from the server.
  ///
  /// Be careful with offline fuctionality.
  Future<T?> getDocOnce<T extends YustDoc>(
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

  /// Returns a stram of the first [YustDoc] in a list.
  ///
  /// Be careful with offline fuctionality.
  /// The result is null if no document was found.
  Future<T?> getFirstDocOnce<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    List<YustFilter> filters, {
    List<String>? orderByList,
  }) async {
    final docs = _getCollection<T>(docSetup.collectionName);
    if (docs.isEmpty) {
      return null;
    } else {
      return docs.first;
    }
  }

  /// Saves a document.
  ///
  /// If [merge] is false a document with the same name
  /// will be overwritten instead of trying to merge the data.
  Future<void> saveDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc, {
    bool merge = true,
    bool? trackModification,
    bool skipOnSave = false,
    bool? removeNullValues,
    bool doNotCreate = false,
  }) async {
    final docs = _getCollection<T>(docSetup.collectionName);
    if (!doNotCreate && !docs.contains(doc)) {
      docs.add(doc);
    }
  }

  /// Delete a [YustDoc].
  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    final docs = _getCollection<T>(docSetup.collectionName);
    docs.remove(doc);
  }

  /// Delete a [YustDoc] by the ID.
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
