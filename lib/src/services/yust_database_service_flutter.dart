import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import '../extensions/string_extension.dart';
import '../models/yust_doc.dart';
import '../models/yust_doc_setup.dart';
import '../models/yust_filter.dart';
import '../util/object_helper.dart';
import '../util/yust_field_transform.dart';
import '../yust.dart';
import 'yust_database_service_shared.dart';

class YustDatabaseService {
  final FirebaseFirestore _fireStore;
  DatabaseLogCallback? dbLogCallback;

  YustDatabaseService({this.dbLogCallback})
      : _fireStore = FirebaseFirestore.instance;
  YustDatabaseService.mocked({this.dbLogCallback})
      : _fireStore = FakeFirebaseFirestore();

  T initDoc<T extends YustDoc>(YustDocSetup<T> docSetup, [T? doc]) {
    final id = _fireStore.collection(_getCollectionPath(docSetup)).doc().id;
    return doInitDoc(docSetup, id, doc);
  }

  Stream<List<T>> getDocs<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
    int? limit,
  }) {
    var query = _getQuery(docSetup,
        orderByList: orderByList, filters: filters, limit: limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((docSnapshot) => _transformDoc(docSetup, docSnapshot))
          .whereType<T>()
          .toList();
    });
  }

  Future<List<T>> getDocsOnce<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
    int? limit,
  }) {
    var query = _getQuery(docSetup,
        orderByList: orderByList, filters: filters, limit: limit);

    return query.get(GetOptions(source: Source.server)).then((snapshot) {
      // print('Get docs once: ${docSetup.collectionName}');
      return snapshot.docs
          .map((docSnapshot) => _transformDoc(docSetup, docSnapshot))
          .whereType<T>()
          .toList();
    });
  }

  Stream<T?> getDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) {
    return _fireStore
        .collection(_getCollectionPath(docSetup))
        .doc(id)
        .snapshots()
        .map((docSnapshot) => _transformDoc(docSetup, docSnapshot));
  }

  Future<T?> getDocOnce<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
  ) {
    return _fireStore
        .collection(_getCollectionPath(docSetup))
        .doc(id)
        .get(GetOptions(source: Source.server))
        .then((docSnapshot) => _transformDoc<T>(docSetup, docSnapshot));
  }

  Stream<T?> getFirstDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
  }) {
    var query = _getQuery(docSetup,
        filters: filters, orderByList: orderByList, limit: 1);

    return query.snapshots().map<T?>((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return _transformDoc(docSetup, snapshot.docs[0]);
      } else {
        return null;
      }
    });
  }

  Future<T?> getFirstDocOnce<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    List<YustFilter> filters, {
    List<String>? orderByList,
  }) async {
    var query = _getQuery(docSetup,
        filters: filters, orderByList: orderByList, limit: 1);
    final snapshot = await query.get(GetOptions(source: Source.server));
    T? doc;

    if (snapshot.docs.isNotEmpty) {
      doc = _transformDoc(docSetup, snapshot.docs[0]);
    }
    return doc;
  }

  Future<void> saveDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    T doc, {
    bool? merge = true,
    bool trackModification = true,
    bool skipOnSave = false,
    bool? removeNullValues,
    List<String>? updateMask,
  }) async {
    var collection = _fireStore.collection(_getCollectionPath(docSetup));
    final yustUpdateMask = await prepareSaveDoc(docSetup, doc,
        trackModification: trackModification, skipOnSave: skipOnSave);
    if (updateMask != null) {
      updateMask.addAll(yustUpdateMask);
      merge = null;
    }

    final jsonDoc = doc.toJson();

    final modifiedDoc = _prepareJsonForFirebase(
      jsonDoc,
      removeNullValues: removeNullValues ?? docSetup.removeNullValues,
    );
    await collection
        .doc(doc.id)
        .set(modifiedDoc, SetOptions(merge: merge, mergeFields: updateMask));
  }

  /// Transforms (e.g. increment, decrement) a documents fields.
  Future<void> updateDocByTransform<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    String id,
    List<YustFieldTransform> fieldTransforms, {
    bool skipOnSave = false,
    bool? removeNullValues,
  }) async {
    var collection = _fireStore.collection(_getCollectionPath(docSetup));

    final update = _transformsToFieldValueMap(fieldTransforms);

    await collection.doc(id).update(update);
  }

  Map<String, dynamic> _prepareJsonForFirebase(
    Map<String, dynamic> obj, {
    bool removeNullValues = true,
  }) {
    final modifiedObj = TraverseObject.traverseObject(obj, (currentNode) {
      if (removeNullValues &&
          !currentNode.info.isInList &&
          currentNode.value == null) {
        return FieldValue.delete();
      }
      if (currentNode.value is DateTime) {
        return Timestamp.fromDate(currentNode.value);
      }
      if (currentNode.value is String &&
          (currentNode.value as String).isIso8601String) {
        return Timestamp.fromDate(DateTime.parse(currentNode.value));
      }
      return currentNode.value;
    });
    return modifiedObj;
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
    final docRef =
        _fireStore.collection(_getCollectionPath(docSetup)).doc(doc.id);
    await docRef.delete();
  }

  Future<void> deleteDocById<T extends YustDoc>(
      YustDocSetup<T> docSetup, String docId) async {
    final docRef =
        _fireStore.collection(_getCollectionPath(docSetup)).doc(docId);
    await docRef.delete();
  }

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
    return _transformDoc(docSetup, document as DocumentSnapshot);
  }

  String _getCollectionPath(YustDocSetup docSetup) {
    var collectionPath = '';
    if (Yust.useSubcollections && docSetup.forEnvironment) {
      collectionPath += '${Yust.envCollectionName}/${Yust.currEnvId!}/';
    }
    collectionPath += docSetup.collectionName;
    return collectionPath;
  }

  Query<Object?> _getQuery<T extends YustDoc>(
    YustDocSetup<T> docSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
    int? limit,
  }) {
    Query query = _fireStore.collection(_getCollectionPath(docSetup));
    query = _executeStaticFilters(query, docSetup);
    query = _executeFilters(query, filters);
    query = _executeOrderByList(query, orderByList);
    if (limit != null) {
      query = query.limit(limit);
    }

    return query;
  }

  Query _executeStaticFilters<T extends YustDoc>(
    Query query,
    YustDocSetup<T> docSetup,
  ) {
    if (!Yust.useSubcollections && docSetup.forEnvironment) {
      query = _filterForEnvironment(query);
    }
    if (docSetup.forUser) {
      query = _filterForUser(query);
    }
    return query;
  }

  Query _filterForEnvironment(Query query) =>
      query.where('envId', isEqualTo: Yust.currEnvId);

  Query _filterForUser(Query query) =>
      query.where('userId', isEqualTo: Yust.authService.currUserId);

  Query _executeFilters(Query query, List<YustFilter>? filters) {
    if (filters != null) {
      for (final filter in filters) {
        if (filter.value is List && filter.value.isEmpty) {
          filter.value = null;
        }
        if ((filter.value != null) ||
            (filter.comparator == YustFilterComparator.isNull)) {
          switch (filter.comparator) {
            case YustFilterComparator.equal:
              query = query.where(filter.field, isEqualTo: filter.value);
              break;
            case YustFilterComparator.notEqual:
              query = query.where(filter.field, isNotEqualTo: filter.value);
              break;
            case YustFilterComparator.lessThan:
              query = query.where(filter.field, isLessThan: filter.value);
              break;
            case YustFilterComparator.lessThanEqual:
              query =
                  query.where(filter.field, isLessThanOrEqualTo: filter.value);
              break;
            case YustFilterComparator.greaterThan:
              query = query.where(filter.field, isGreaterThan: filter.value);
              break;
            case YustFilterComparator.greaterThanEqual:
              query = query.where(filter.field,
                  isGreaterThanOrEqualTo: filter.value);
              break;
            case YustFilterComparator.arrayContains:
              query = query.where(filter.field, arrayContains: filter.value);
              break;
            case YustFilterComparator.arrayContainsAny:
              query = query.where(filter.field, arrayContainsAny: filter.value);
              break;
            case YustFilterComparator.inList:
              query = query.where(filter.field, whereIn: filter.value);
              break;
            case YustFilterComparator.notInList:
              query = query.where(filter.field, whereNotIn: filter.value);
              break;
            case YustFilterComparator.isNull:
              query = query.where(filter.field, isNull: true);
              break;
            default:
              throw 'The comparator "${filter.comparator}" is not supported.';
          }
        }
      }
    }
    return query;
  }

  Query _executeOrderByList(Query query, List<String>? orderByList) {
    if (orderByList != null) {
      orderByList.asMap().forEach((index, orderBy) {
        if (orderBy.toUpperCase() != 'DESC' && orderBy.toUpperCase() != 'ASC') {
          final desc = (index + 1 < orderByList.length &&
              orderByList[index + 1].toUpperCase() == 'DESC');
          query = query.orderBy(orderBy, descending: desc);
        }
      });
    }
    return query;
  }

  T? _transformDoc<T extends YustDoc>(
    YustDocSetup<T> docSetup,
    DocumentSnapshot snapshot,
  ) {
    if (snapshot.exists == false) {
      return null;
    }
    final data = snapshot.data();
    if (data is Map<String, dynamic>) {
      // Convert Timestamps to ISOStrings
      final modifiedData = TraverseObject.traverseObject(data, (currentNode) {
        // Convert Timestamp to Iso8601-String, as this is the format json_serializable expects
        if (currentNode.value is Timestamp) {
          return (currentNode.value as Timestamp)
              .toDate()
              .toLocal()
              .toIso8601String();
        }
        return currentNode.value;
      });
      return docSetup.fromJson(modifiedData);
    }
    return null;
  }

  static Map<String, dynamic> _transformsToFieldValueMap(
      List<YustFieldTransform> transforms) {
    final map = <String, dynamic>{};
    for (final transform in transforms) {
      final fieldValue = transform.toNativeTransform();
      if (fieldValue == null) continue;
      map[transform.fieldPath] = fieldValue;
    }
    return map;
  }
}
