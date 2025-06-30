import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';
import '../models/yust_order_by.dart';
import '../util/yust_database_statistics.dart';
import '../util/yust_field_transform.dart';
import '../yust.dart';
import 'yust_database_service_shared.dart';

const firestoreApiUrl = 'https://firestore.googleapis.com/';

/// Handles database requests for Cloud Firestore.
///
/// Using FlutterFire for Flutter Platforms (Android, iOS, Web) and GoogleAPIs for Dart-only environments.
abstract interface class IYustDatabaseService {
  DatabaseLogCallback? dbLogCallback;
  YustDatabaseStatistics get statistics;

  /// Represents the collection name for the tenants.
  String get envCollectionName;

  /// If [useSubcollections] is set to true (default), Yust is creating Subcollections for each tenant automatically.
  bool get useSubcollections;

  /// Which version of documents to read.
  ///
  /// A timestamp in the past will return the document at that time.
  /// Null will return the most recent version.
  DateTime? readTime;

  /// Initializes a document with an id and the time it was created.
  ///
  /// Optionally an existing document can be given, which will still be
  /// assigned a new id becoming a new document if it had an id previously.
  T initDoc<T extends YustDoc>(YustDocSetup<T> docSetup, [T? doc]);

  /// Returns a [YustDoc] from the server, if available, otherwise from the cache.
  /// The cached documents may not be up to date!
  ///
  /// Be careful with offline functionality.
  Future<T?> get<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  );

  /// Returns a [YustDoc] from the cache, if available, otherwise from the server.
  /// Be careful: The cached documents may not be up to date!
  ///
  /// Be careful with offline functionality.
  Future<T?> getFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  );

  /// Returns a [YustDoc] directly from the server.
  ///
  /// Be careful with offline functionality.
  Future<T?> getFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id, {
    String? transaction,
  });

  /// Returns a stream of a [YustDoc].
  ///
  /// Whenever another user makes a change, a new version of the document is returned.
  Stream<T?> getStream<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  );

  /// Returns the first [YustDoc] in a list from the server, if available, otherwise from the cache.
  /// The cached documents may not be up to date!
  ///
  /// Be careful with offline functionality.
  /// The result is null if no document was found.
  Future<T?> getFirst<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  });

  /// Returns the first [YustDoc] in a list from the cache, if available, otherwise from the server.
  /// Be careful: The cached documents may not be up to date!
  ///
  /// Be careful with offline functionality.
  /// The result is null if no document was found.
  Future<T?> getFirstFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  });

  /// Returns the first [YustDoc] in a list directly from the server.
  ///
  /// Be careful with offline functionality.
  /// The result is null if no document was found.
  Future<T?> getFirstFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  });

  /// Returns a stream of the first [YustDoc] in a list.
  ///
  /// Whenever another user make a change, a new version of the document is returned.
  /// The result is null if no document was found.
  Stream<T?> getFirstStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  });

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
    Map<String, dynamic>? startAfterDocument,
  });

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
    Map<String, dynamic>? startAfterDocument,
  });

  /// Returns [YustDoc]s directly from the database.
  ///
  /// Be careful with offline functionality.
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
    Map<String, dynamic>? startAfterDocument,
  });

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
    int pageSize = 300,
    Map<String, dynamic>? startAfterDocument,
  });

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
    Map<String, dynamic>? startAfterDocument,
  });

  /// Counts the number of documents in a collection.
  ///
  /// [docSetup] is used to read the collection path.
  ///
  /// [filters] Each entry represents a condition that has to be met.
  /// All of those conditions must be true for each returned entry.
  Future<int> count<T extends YustDoc>(YustDocSetup<T> docSetup,
      {List<YustFilter>? filters, int? limit});

  /// Returns the sum over a field of multiple documents in a collection.
  ///
  /// [docSetup] is used to read the collection path.
  ///
  /// [field] is the field over which to sum.
  ///
  /// [filters] Each entry represents a condition that has to be met.
  /// All of those conditions must be true for each returned entry.
  Future<AggregationResult> sum<T extends YustDoc>(
      YustDocSetup<T> docSetup, String fieldPath,
      {List<YustFilter>? filters, int? limit});

  /// Returns the sum over a field of multiple documents in a collection.
  ///
  /// [docSetup] is used to read the collection path.
  ///
  /// [fieldPath] is the field over which to sum.
  ///
  /// [filters] Each entry represents a condition that has to be met.
  /// All of those conditions must be true for each returned entry.
  Future<AggregationResult> avg<T extends YustDoc>(
      YustDocSetup<T> docSetup, String fieldPath,
      {List<YustFilter>? filters, int? limit});

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
  });

  /// Transforms (e.g. increment, decrement) a documents fields.
  Future<void> updateDocByTransform<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
    List<YustFieldTransform> fieldTransforms, {
    bool skipOnSave = false,
    bool? removeNullValues,
  });

  /// Delete all [YustDoc]s in the filter.
  Future<void> deleteDocs<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
  });

  /// Delete all [YustDoc]s in the filter as a batch.
  Future<int> deleteDocsAsBatch<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  });

  /// Delete a [YustDoc] by the ID.
  Future<void> deleteDocById<T extends YustDoc>(
      YustDocSetup<T> docSetup, String id);

  /// Initializes a [YustDoc] and saves it.
  ///
  /// If [onInitialised] is provided, it will be called and
  /// waited for after the document is initialized.
  ///
  /// An existing document can be given which will instead be initialized.
  Future<T> saveNewDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    required T doc,
    Future<void> Function(T)? onInitialised,
    bool? removeNullValues,
  });

  /// Reads a document, executes a function and saves the document as a transaction.
  /// Returns true if the transaction was successful.
  ///
  /// If the transaction fails, it will be retried up to [maxTries] - 1 times.
  /// If [ignore409Error] is true, no error will be thrown on 409 (Unsuccessful Transaction) Errors.
  /// [transaction] should return the updated document, if it returns null, nothing will be saved to the db.
  ///
  /// Some general Notes on Transactions:
  /// - Transactions are only auto-retried by the google client libraries, so we need to do it manually
  /// - Transactions will only fail if a document was changed by a other transaction.
  ///   _Not_ if the document was changed by a normal save
  Future<(bool, T?)> runTransactionForDocument<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String docId,
    Future<T?> Function(T doc) transaction, {
    int maxTries = 200,
    bool ignoreTransactionErrors = false,
    bool useUpdateMask = false,
  });

  /// Begins a transaction.
  Future<String> beginTransaction();

  /// Saves a YustDoc and finishes a transaction.
  Future<void> commitTransaction(
      String transaction, YustDocSetup docSetup, YustDoc doc,
      {bool useUpdateMask = false});

  // Makes an empty commit, thereby releasing the lock on the document.
  Future<void> commitEmptyTransaction(String transaction);

  /// Transforms a json to a [YustDoc]
  T? transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    dynamic document,
  );
}
