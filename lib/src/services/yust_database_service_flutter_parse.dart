import 'package:parse_server_sdk/parse_server_sdk.dart';

import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';
import '../models/yust_order_by.dart';
import '../util/object_helper.dart';
import '../util/yust_exception.dart';
import '../util/yust_field_transform.dart';
import '../yust.dart';
import 'yust_database_service_interface.dart';
import 'yust_database_service_shared.dart';

class YustDatabaseServiceParse implements YustDatabaseServiceInterface {
  @override
  DatabaseLogCallback? dbLogCallback;

  YustDatabaseServiceParse({this.dbLogCallback});

  YustDatabaseServiceParse.mocked({this.dbLogCallback});

  @override
  T initDoc<T extends YustDoc>(YustDocSetup<T> docSetup, {T? doc}) {
    throw YustException('Not implemented for parse');
  }

  @override
  Future<T?> get<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    try {
      return await ParseObject(docSetup.collectionName)
          .getObject(id)
          .then((response) => _transformDoc(docSetup, response));
    } catch (e) {
      return await ParseObject(docSetup.collectionName)
          .fromPin(id)
          .then((response) => _transformDoc(docSetup, response));
    }
  }

  @override
  Future<T?> getFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    try {
      return await ParseObject(docSetup.collectionName)
          .fromPin(id)
          .then((response) => _transformDoc(docSetup, response));
    } catch (e) {
      return await ParseObject(docSetup.collectionName)
          .getObject(id)
          .then((response) => _transformDoc(docSetup, response));
    }
  }

  @override
  Future<T?> getFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id, {
    String? transaction,
  }) async {
    return await ParseObject(docSetup.collectionName)
        .getObject(id)
        .then((response) => _transformDoc(docSetup, response));
  }

  @override
  Stream<T?> getStream<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async* {
    yield await get(docSetup, id);

    final liveQuery = LiveQuery();
    final parseObject = ParseObject(docSetup.collectionName);
    final query = QueryBuilder(parseObject)..whereEqualTo('objectId', id);

    final subscription = await liveQuery.client.subscribe(query);

    subscription.on(LiveQueryEvent.update, (response) async* {
      final result = _transformDoc(docSetup, response);
      yield result;
    });
  }

  @override
  Future<T?> getFirst<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    throw YustException('Not implemented for parse');
  }

  @override
  Future<T?> getFirstFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    throw YustException('Not implemented for parse');
  }

  @override
  Future<T?> getFirstFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) async {
    throw YustException('Not implemented for parse');
  }

  @override
  Stream<T?> getFirstStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
  }) {
    throw YustException('Not implemented for parse');
  }

  @override
  Future<List<T>> getList<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    throw YustException('Not implemented for parse');
  }

  @override
  Future<List<T>> getListFromCache<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) async {
    throw YustException('Not implemented for parse');
  }

  @override
  Future<List<T>> getListFromDB<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    throw YustException('Not implemented for parse');
  }

  @override
  Stream<List<T>> getListStream<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    throw YustException('Not implemented for parse');
  }

  @override
  Future<int> count<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
  }) async {
    throw YustException('Not implemented for parse');
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

    final parseDoc = ParseObject(docSetup.collectionName)..objectId = doc.id;
    final jsonDoc = doc.toJson();
    for (final key in updateMask ?? jsonDoc.keys) {
      if (key == 'id') continue;
      parseDoc.set(key, jsonDoc[key]);
    }

    if (doNotCreate && (await get(docSetup, doc.id)) == null) return;
    await parseDoc.save();
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
    throw YustException('Not implemented for parse');
  }

  @override
  Stream<T> getListChunked<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int pageSize = 5000,
  }) async* {
    throw YustException('Not implemented for parse');
  }

  @override
  Future<void> deleteDocs<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
  }) async {
    throw YustException('Not implemented for parse');
  }

  @override
  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    throw YustException('Not implemented for parse');
  }

  @override
  Future<void> deleteDocById<T extends YustDoc>(
      YustDocSetup<T> docSetup, String docId) async {
    throw YustException('Not implemented for parse');
  }

  @override
  Future<T> saveNewDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    required T doc,
    Future<void> Function(T)? onInitialized,
    bool? removeNullValues,
  }) async {
    throw YustException('Not implemented for parse');
  }

  /// Reads a document, executes a function and saves the document as a transaction.
  @override
  Future<void> runTransactionForDocument<T extends YustDoc>(
      YustDocSetup<T> docSetup,
      String docId,
      Function(T doc) transaction) async {
    throw YustException('Not implemented for flutter');
  }

  /// Begins a transaction.
  @override
  Future<String> beginTransaction() async {
    throw YustException('Not implemented for flutter');
  }

  /// Saves a YustDoc and finishes a transaction.
  @override
  Future<void> commitTransaction(
      String transaction, YustDocSetup docSetup, YustDoc doc) async {
    throw YustException('Not implemented for flutter');
  }

  @override
  dynamic getQuery<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<YustOrderBy>? orderBy,
    int? limit,
  }) {
    throw YustException('Not implemented for parse');
  }

  @override
  T? transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    dynamic document,
  ) {
    throw YustException('Not implemented for parse');
  }

  T? _transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    ParseResponse response,
  ) {
    if (response.error != null) {
      throw response.error!;
    }
    final data = response.results!.first;
    if (data is Map<String, dynamic>) {
      // Convert Timestamps to ISOStrings
      final modifiedData = TraverseObject.traverseObject(data, (currentNode) {
        // // Convert Timestamp to Iso8601-String, as this is the format json_serializable expects
        // if (currentNode.value is Timestamp) {
        //   return (currentNode.value as Timestamp)
        //       .toDate()
        //       .toUtc()
        //       .toIso8601String();
        // }

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
}
