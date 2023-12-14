import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';
import '../models/yust_order_by.dart';
import '../util/yust_exception.dart';
import '../util/yust_field_transform.dart';
import '../yust.dart';
import 'yust_database_service_flutter_firebase.dart';
import 'yust_database_service_flutter_parse.dart';
import 'yust_database_service_interface.dart';

class YustDatabaseService {
  DatabaseLogCallback? dbLogCallback;

  YustDatabaseService({this.dbLogCallback});

  YustDatabaseService.mocked({this.dbLogCallback});

  YustDatabaseServiceInterface useRightBackend(YustBackend? useBackend) {
    switch (useBackend ?? Yust.defaultBackend) {
      case YustBackend.firebase:
        return YustDatabaseServiceFirebase();
      case YustBackend.parse:
        return YustDatabaseServiceParse();
    }
  }

  T initDoc<T extends YustDoc>(YustDocSetup<T> docSetup,
          {T? doc, YustBackend? useBackend}) =>
      useRightBackend(useBackend).initDoc(docSetup, doc: doc);

  Future<T?> get<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id, {
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).get(docSetup, id);

  Future<T?> getFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id, {
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).getFromCache(docSetup, id);

  Future<T?> getFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id, {
    String? transaction,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend)
          .getFromDB(docSetup, id, transaction: transaction);

  Stream<T?> getStream<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id, {
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).getStream(docSetup, id);

  Future<T?> getFirst<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend)
          .getFirst(docSetup, filters: filters, orderBy: orderBy);

  Future<T?> getFirstFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend)
          .getFirstFromCache(docSetup, filters: filters, orderBy: orderBy);

  Future<T?> getFirstFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend)
          .getFirstFromDB(docSetup, filters: filters, orderBy: orderBy);

  Stream<T?> getFirstStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend)
          .getFirstStream(docSetup, filters: filters, orderBy: orderBy);

  Future<List<T>> getList<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend)
          .getList(docSetup, filters: filters, orderBy: orderBy, limit: limit);

  Future<List<T>> getListFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).getListFromCache(docSetup,
          filters: filters, orderBy: orderBy, limit: limit);

  Future<List<T>> getListFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).getListFromDB(docSetup,
          filters: filters, orderBy: orderBy, limit: limit);

  Stream<List<T>> getListStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).getListStream(docSetup,
          filters: filters, orderBy: orderBy, limit: limit);

  Future<int> count<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).count(docSetup, filters: filters);

  Future<void> saveDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc, {
    bool? merge = true,
    bool? trackModification,
    bool skipOnSave = false,
    bool? removeNullValues,
    List<String>? updateMask,
    bool doNotCreate = false,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).saveDoc(docSetup, doc,
          merge: merge,
          trackModification: trackModification,
          skipOnSave: skipOnSave,
          removeNullValues: removeNullValues,
          updateMask: updateMask,
          doNotCreate: doNotCreate);

  /// Transforms (e.g. increment, decrement) a documents fields.
  Future<void> updateDocByTransform<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
    List<YustFieldTransform> fieldTransforms, {
    bool skipOnSave = false,
    bool? removeNullValues,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).updateDocByTransform(
        docSetup,
        id,
        fieldTransforms,
        skipOnSave: skipOnSave,
        removeNullValues: removeNullValues,
      );

  Stream<T> getListChunked<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int pageSize = 5000,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).getListChunked(
        docSetup,
        filters: filters,
        orderBy: orderBy,
        pageSize: pageSize,
      );

  Future<void> deleteDocs<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).deleteDocs(docSetup, filters: filters);

  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
    YustBackend? useBackend,
  ) =>
      useRightBackend(useBackend).deleteDoc(docSetup, doc);

  Future<void> deleteDocById<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String docId,
    YustBackend? useBackend,
  ) =>
      useRightBackend(useBackend).deleteDocById(
        docSetup,
        docId,
      );

  Future<T> saveNewDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    required T doc,
    Future<void> Function(T)? onInitialized,
    bool? removeNullValues,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).saveNewDoc(
        docSetup,
        doc: doc,
        onInitialized: onInitialized,
        removeNullValues: removeNullValues,
      );

  /// Reads a document, executes a function and saves the document as a transaction.
  Future<void> runTransactionForDocument<T extends YustDoc>(
      YustDocSetup<T> docSetup,
      String docId,
      Function(T doc) transaction) async {
    throw YustException('Not implemented for flutter');
  }

  /// Begins a transaction.
  Future<String> beginTransaction() async {
    throw YustException('Not implemented for flutter');
  }

  /// Saves a YustDoc and finishes a transaction.
  Future<void> commitTransaction(
      String transaction, YustDocSetup docSetup, YustDoc doc) async {
    throw YustException('Not implemented for flutter');
  }

  dynamic getQuery<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
    YustBackend? useBackend,
  }) =>
      useRightBackend(useBackend).getQuery(
        docSetup,
        filters: filters,
        orderBy: orderBy,
        limit: limit,
      );

  T? transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    dynamic document,
    YustBackend? useBackend,
  ) =>
      useRightBackend(useBackend).transformDoc(docSetup, document);
}
