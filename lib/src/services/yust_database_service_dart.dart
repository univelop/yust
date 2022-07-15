import 'package:googleapis/firestore/v1.dart';

import '../extensions/string_extension.dart';
import '../extensions/date_time_extension.dart';
import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';
import '../util/yust_exception.dart';
import '../util/yust_firestore_api.dart';
import '../yust.dart';
import 'yust_database_service_shared.dart';

class YustDatabaseService {
  FirestoreApi api = YustFirestoreApi.instance!;
  String projectId = YustFirestoreApi.projectId!;

  YustDatabaseService();
  YustDatabaseService.mocked();

  /// Initialises a document with an id and the time it was created.
  ///
  /// Optionally an existing document can be given, which will still be
  /// assigned a new id becoming a new document if it had an id previously.
  T initDoc<T extends YustDoc>(YustDocSetup<T> docSetup, [T? doc]) {
    final id = _createDocumentId();
    return doInitDoc(docSetup, id, doc);
  }

  ///[filters] each entry represents a condition that has to be met.
  ///All of those conditions must be true for each returned entry.
  ///
  ///Consists at first of the column name followed by either 'ASC' or 'DESC'.
  ///Multiple of those entries can be repeated.
  ///
  ///[filters] may be null.
  ///
  ///[limit] can be passed to reduce loading time
  Stream<List<T>> getDocs<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
    int? limit,
  }) {
    throw (YustException('Not implemented for server.'));
  }

  Future<List<T>> getDocsOnce<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
    int? limit,
  }) async {
    final response = await api.projects.databases.documents.runQuery(
        _getQuery(docSetup,
            filters: filters, orderByList: orderByList, limit: limit),
        _getCollectionPath(docSetup));

    return response
        .map((e) {
          if (e.document == null) {
            return null;
          }
          return _transformDoc<T>(docSetup, e.document!);
        })
        .whereType<T>()
        .toList();
  }

  Stream<T?> getDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) {
    throw (YustException('Not implemented for server.'));
  }

  Future<T?> getDocOnce<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) async {
    final response = await api.projects.databases.documents
        .get(_getDocumentPath(docSetup, id));
    return _transformDoc<T>(docSetup, response);
  }

  /// Emits null events if no document was found.
  Stream<T?> getFirstDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
  }) {
    throw (YustException('Not implemented for server.'));
  }

  /// The result is null if no document was found.
  Future<T?> getFirstDocOnce<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    List<YustFilter> filters, {
    List<String>? orderByList,
  }) async {
    final response = await api.projects.databases.documents.runQuery(
        _getQuery(docSetup,
            filters: filters, orderByList: orderByList, limit: 1),
        _getCollectionPath(docSetup));

    if (response.isEmpty) {
      return null;
    }
    return _transformDoc<T>(docSetup, response.first.document!);
  }

  /// Saves a document.
  ///
  /// If [merge] is false a document with the same name
  /// will be overwritten instead of trying to merge the data.
  Future<void> saveDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc, {
    bool merge = true,
    bool trackModification = true,
    bool skipOnSave = false,
    bool? removeNullValues,
  }) async {
    await preapareSaveDoc(docSetup, doc,
        trackModification: trackModification, skipOnSave: skipOnSave);

    final jsonDoc = doc.toJson();
    final dbDoc = Document(
        fields:
            jsonDoc.map((key, value) => MapEntry(key, _valueToDbValue(value))));

    await api.projects.databases.documents
        .patch(dbDoc, _getDocumentPath(docSetup, doc.id));
  }

  Future<void> deleteDocs<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
  }) async {
    final docs = await getDocsOnce<T>(docSetup, filters: filters);
    for (var doc in docs) {
      await deleteDoc<T>(docSetup, doc);
    }
  }

  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc,
  ) async {
    await api.projects.databases.documents
        .delete(_getDocumentPath(docSetup, doc.id));
  }

  Future<void> deleteDocById<T extends YustDoc>(
      YustDocSetup<T> docSetup, String docId) async {
    await api.projects.databases.documents
        .delete(_getDocumentPath(docSetup, docId));
  }

  /// Initialises a document and saves it.
  ///
  /// If [onInitialised] is provided, it will be called and
  /// waited for after the document is initialised.
  ///
  /// An existing document can be given which will instead be initialised.
  Future<T> saveNewDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    required T doc,
    Future<void> Function(T)? onInitialised,
    bool? removeNullValues,
  }) async {
    doc = initDoc<T>(docSetup, doc);

    if (onInitialised != null) {
      await onInitialised(doc);
    }

    await saveDoc<T>(
      docSetup,
      doc,
      removeNullValues: removeNullValues ?? docSetup.removeNullValues,
    );

    return doc;
  }

  dynamic getQuery<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
    int? limit,
  }) {
    return _getQuery<T>(docSetup,
        filters: filters, orderByList: orderByList, limit: limit);
  }

  T? transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    dynamic document,
  ) {
    return _transformDoc(docSetup, document as Document);
  }

  String _getCollectionPath(YustDocSetup docSetup) {
    var collectionPath = 'projects/$projectId/databases/(default)/documents/';
    if (Yust.useSubcollections && docSetup.forEnvironment) {
      collectionPath += '${Yust.envCollectionName}/${Yust.currEnvId!}/';
    }
    collectionPath += docSetup.collectionName;
    return collectionPath;
  }

  String _getDocumentPath(YustDocSetup docSetup, String id) {
    return '${_getCollectionPath(docSetup)}/$id';
  }

  RunQueryRequest _getQuery<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
    int? limit,
  }) {
    return RunQueryRequest(
      structuredQuery: StructuredQuery(
          where: Filter(
              compositeFilter: CompositeFilter(
                  filters: _executeStaticFilters(docSetup) +
                      _executeFilters(filters))),
          orderBy: _executeOrderByList(orderByList),
          limit: limit),
    );
  }

  List<Filter> _executeStaticFilters<T extends YustDoc>(
    YustDocSetup<T> docSetup,
  ) {
    final result = <Filter>[];
    if (!Yust.useSubcollections && docSetup.forEnvironment) {
      result.add(Filter(
          fieldFilter: FieldFilter(
        field: FieldReference(fieldPath: 'envId'),
        op: 'EQUAL',
        value: _valueToDbValue(Yust.currEnvId),
      )));
    }
    if (docSetup.forUser) {
      result.add(Filter(
          fieldFilter: FieldFilter(
        field: FieldReference(fieldPath: 'userId'),
        op: 'EQUAL',
        value: _valueToDbValue(Yust.authService.currUserId),
      )));
    }
    return result;
  }

  List<Filter> _executeFilters(List<YustFilter>? filters) {
    final result = <Filter>[];
    if (filters != null) {
      for (final filter in filters) {
        if (filter.value is List && filter.value.isEmpty) {
          filter.value = null;
        }
        if ((filter.value != null) ||
            (filter.comparator == YustFilterComparator.isNull)) {
          String op;
          switch (filter.comparator) {
            case YustFilterComparator.equal:
              op = 'EQUAL';
              break;
            case YustFilterComparator.notEqual:
              op = 'NOT_EQUAL';
              break;
            case YustFilterComparator.lessThan:
              op = 'LESS_THAN';
              break;
            case YustFilterComparator.lessThanEqual:
              op = 'LESS_THAN_OR_EQUAL';
              break;
            case YustFilterComparator.greaterThan:
              op = 'GREATHER_THAN';
              break;
            case YustFilterComparator.greaterThanEqual:
              op = 'GREATHER_THAN_OR_EQUAL';
              break;
            case YustFilterComparator.arrayContains:
              op = 'ARRAY_CONTAINS';
              break;
            case YustFilterComparator.arrayContainsAny:
              op = 'ARRAY_CONTAINS_ANY';
              break;
            case YustFilterComparator.inList:
              op = 'IN';
              break;
            case YustFilterComparator.notInList:
              op = 'NOT_IN';
              break;
            case YustFilterComparator.isNull:
              op = 'IS_NULL';
              break;
            default:
              throw 'The comparator "${filter.comparator}" is not supported.';
          }

          result.add(Filter(
              fieldFilter: FieldFilter(
            field: FieldReference(fieldPath: filter.field),
            op: op,
            value: _valueToDbValue(filter.value),
          )));
        }
      }
    }
    return result;
  }

  List<Order> _executeOrderByList(List<String>? orderByList) {
    final result = <Order>[];
    if (orderByList != null) {
      orderByList.asMap().forEach((index, orderBy) {
        if (orderBy.toUpperCase() != 'DESC' && orderBy.toUpperCase() != 'ASC') {
          final desc = (index + 1 < orderByList.length &&
              orderByList[index + 1].toUpperCase() == 'DESC');
          result.add(Order(
              field: FieldReference(fieldPath: orderBy),
              direction: desc ? 'DESCENDING' : 'ASCENDING'));
        }
      });
    }
    return result;
  }

  /// Returns null if no data exists.
  T? _transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    Document document,
  ) {
    final json = document.fields
        ?.map((key, dbValue) => MapEntry(key, _dbValueToValue(dbValue)));

    if (json == null) {
      return null;
    }

    return docSetup.fromJson(json);
  }

  Value _valueToDbValue(dynamic value) {
    if (value is List) {
      return Value(
          arrayValue: ArrayValue(
              values: value
                  .map((childValue) => _valueToDbValue(childValue))
                  .toList()));
    } else if (value is Map) {
      return Value(
          mapValue: MapValue(
              fields: value.map((key, childValue) =>
                  MapEntry(key, _valueToDbValue(childValue)))));
    } else if (value is bool) {
      return Value(booleanValue: value);
    } else if (value is int) {
      return Value(integerValue: value.toString());
    } else if (value == null) {
      return Value(nullValue: 'NULL_VALUE');
    } else if (value is String && value.isIso8601String) {
      value = DateTime.parse(value).toIso8601StringWithOffset();
      return Value(timestampValue: value);
    } else if (value is String) {
      return Value(stringValue: value);
    } else {
      throw (YustException('Value can not be transformed for Firestore.'));
    }
  }

  dynamic _dbValueToValue(Value dbValue) {
    if (dbValue.arrayValue != null) {
      return dbValue.arrayValue!.values?.map((childValue) {
        return _dbValueToValue(childValue);
      }).toList();
    } else if (dbValue.mapValue != null) {
      return dbValue.mapValue!.fields?.map(
          (key, childValue) => MapEntry(key, _dbValueToValue(childValue)));
    } else if (dbValue.booleanValue != null) {
      return dbValue.booleanValue;
    } else if (dbValue.integerValue != null) {
      return int.parse(dbValue.integerValue!);
    } else if (dbValue.nullValue != null) {
      return null;
    } else if (dbValue.stringValue != null) {
      return dbValue.stringValue;
    } else if (dbValue.timestampValue != null) {
      if (dbValue.timestampValue!.isIso8601String == true) {
        return DateTime.parse(dbValue.timestampValue!);
      } else {
        return null;
      }
    } else {
      throw (YustException('Value can not be transformed from Firestore.'));
    }
  }

  String _createDocumentId() {
    return Yust.helpers.randomString(length: 20);
  }
}
