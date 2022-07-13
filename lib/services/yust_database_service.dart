import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:yust/models/yust_doc.dart';
import 'package:yust/models/yust_doc_setup.dart';
import 'package:yust/models/yust_filter.dart';
import 'package:yust/util/object_helper.dart';

import '../yust.dart';

class YustDatabaseService {
  FirebaseFirestore fireStore;

  YustDatabaseService() : fireStore = FirebaseFirestore.instance;
  YustDatabaseService.mocked() : fireStore = FakeFirebaseFirestore();

  /// Initialises a document with an id and the time it was created.
  ///
  /// Optionally an existing document can be given, which will still be
  /// assigned a new id becoming a new document if it had an id previously.
  T initDoc<T extends YustDoc>(YustDocSetup<T> modelSetup, [T? doc]) {
    doc ??= modelSetup.newDoc();
    doc.id = fireStore.collection(_getCollectionPath(modelSetup)).doc().id;
    doc.createdAt = DateTime.now();
    doc.createdBy = Yust.authService.currUserId;
    if (modelSetup.forEnvironment) {
      doc.envId = Yust.currEnvId;
    }
    if (modelSetup.forUser) {
      doc.userId = Yust.authService.currUserId;
    }
    if (modelSetup.onInit != null) {
      modelSetup.onInit!(doc);
    }
    return doc;
  }

  Query<Object?> getQuery<T extends YustDoc>(
    YustDocSetup<T> modelSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
    int? limit,
  }) {
    Query query = fireStore.collection(_getCollectionPath(modelSetup));
    query = _executeStaticFilters(query, modelSetup);
    query = _executeFilters(query, filters);
    query = _executeOrderByList(query, orderByList);
    if (limit != null) {
      query = query.limit(limit);
    }

    return query;
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
    YustDocSetup<T> modelSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
    int? limit,
  }) {
    var query = getQuery(modelSetup,
        orderByList: orderByList, filters: filters, limit: limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((docSnapshot) => transformDoc(modelSetup, docSnapshot))
          .whereType<T>()
          .toList();
    });
  }

  Future<List<T>> getDocsOnce<T extends YustDoc>(
    YustDocSetup<T> modelSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
    int? limit,
  }) {
    var query = getQuery(modelSetup,
        orderByList: orderByList, filters: filters, limit: limit);

    return query.get(GetOptions(source: Source.server)).then((snapshot) {
      // print('Get docs once: ${modelSetup.collectionName}');
      return snapshot.docs
          .map((docSnapshot) => transformDoc(modelSetup, docSnapshot))
          .whereType<T>()
          .toList();
    });
  }

  /// Returns null if no data exists.
  T? transformDoc<T extends YustDoc>(
    YustDocSetup<T> modelSetup,
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
      return modelSetup.fromJson(modifiedData);
    }
    return null;
  }

  Stream<T?> getDoc<T extends YustDoc>(
    YustDocSetup<T> modelSetup,
    String id,
  ) {
    return fireStore
        .collection(_getCollectionPath(modelSetup))
        .doc(id)
        .snapshots()
        .map((docSnapshot) => transformDoc(modelSetup, docSnapshot));
  }

  Future<T?> getDocOnce<T extends YustDoc>(
    YustDocSetup<T> modelSetup,
    String id,
  ) {
    return fireStore
        .collection(_getCollectionPath(modelSetup))
        .doc(id)
        .get(GetOptions(source: Source.server))
        .then((docSnapshot) => transformDoc<T>(modelSetup, docSnapshot));
  }

  /// Emits null events if no document was found.
  Stream<T?> getFirstDoc<T extends YustDoc>(
    YustDocSetup<T> modelSetup, {
    List<YustFilter>? filters,
    List<String>? orderByList,
  }) {
    var query = getQuery(modelSetup,
        filters: filters, orderByList: orderByList, limit: 1);

    return query.snapshots().map<T?>((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return transformDoc(modelSetup, snapshot.docs[0]);
      } else {
        return null;
      }
    });
  }

  /// The result is null if no document was found.
  Future<T?> getFirstDocOnce<T extends YustDoc>(
    YustDocSetup<T> modelSetup,
    List<YustFilter> filters, {
    List<String>? orderByList,
  }) async {
    var query = getQuery(modelSetup,
        filters: filters, orderByList: orderByList, limit: 1);
    final snapshot = await query.get(GetOptions(source: Source.server));
    T? doc;

    if (snapshot.docs.isNotEmpty) {
      doc = transformDoc(modelSetup, snapshot.docs[0]);
    }
    return doc;
  }

  /// Saves a document.
  ///
  /// If [merge] is false a document with the same name
  /// will be overwritten instead of trying to merge the data.
  Future<void> saveDoc<T extends YustDoc>(
    YustDocSetup<T> modelSetup,
    T doc, {
    bool merge = true,
    bool trackModification = true,
    bool skipOnSave = false,
    bool? removeNullValues,
  }) async {
    var collection = fireStore.collection(_getCollectionPath(modelSetup));
    if (trackModification) {
      doc.modifiedAt = DateTime.now();
      doc.modifiedBy = Yust.authService.currUserId;
    }
    doc.createdAt ??= doc.modifiedAt;
    doc.createdBy ??= doc.modifiedBy;
    if (doc.userId == null && modelSetup.forUser) {
      doc.userId = Yust.authService.currUserId;
    }
    if (doc.envId == null && modelSetup.forEnvironment) {
      doc.envId = Yust.currEnvId;
    }
    if (modelSetup.onSave != null && !skipOnSave) {
      await modelSetup.onSave!(doc);
    }
    final jsonDoc = doc.toJson();

    final modifiedDoc = prepareJsonForFirebase(
      jsonDoc,
      removeNullValues: removeNullValues ?? modelSetup.removeNullValues,
    );
    await collection.doc(doc.id).set(modifiedDoc, SetOptions(merge: merge));
  }

  /// Regex that matches Strings created by DateTime.toIso8601String()
  final iso8601Regex = RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.?\d{0,9}');

  /// Converts DateTimes to Timestamps and removes null values (if not in List)
  Map<String, dynamic> prepareJsonForFirebase(
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
          iso8601Regex.hasMatch(currentNode.value)) {
        return Timestamp.fromDate(DateTime.parse(currentNode.value));
      }
      return currentNode.value;
    });
    return modifiedObj;
  }

  Future<void> deleteDocs<T extends YustDoc>(
    YustDocSetup<T> modelSetup, {
    List<YustFilter>? filters,
  }) async {
    final docs = await getDocsOnce<T>(modelSetup, filters: filters);
    for (var doc in docs) {
      await deleteDoc<T>(modelSetup, doc);
    }
  }

  Future<void> deleteDoc<T extends YustDoc>(
    YustDocSetup<T> modelSetup,
    T doc,
  ) async {
    if (modelSetup.onDelete != null) {
      await modelSetup.onDelete!(doc);
    }
    final docRef =
        fireStore.collection(_getCollectionPath(modelSetup)).doc(doc.id);
    await docRef.delete();
  }

  Future<void> deleteDocbyId<T extends YustDoc>(
      YustDocSetup<T> modelSetup, String docId) async {
    final docRef =
        fireStore.collection(_getCollectionPath(modelSetup)).doc(docId);
    await docRef.delete();
  }

  /// Initialises a document and saves it.
  ///
  /// If [onInitialised] is provided, it will be called and
  /// waited for after the document is initialised.
  ///
  /// An existing document can be given which will instead be initialised.
  Future<T> saveNewDoc<T extends YustDoc>(
    YustDocSetup<T> modelSetup, {
    T? doc,
    Future<void> Function(T)? onInitialised,
    bool? removeNullValues,
  }) async {
    doc = initDoc<T>(modelSetup, doc);

    if (onInitialised != null) {
      await onInitialised(doc);
    }

    await saveDoc<T>(
      modelSetup,
      doc,
      removeNullValues: removeNullValues ?? modelSetup.removeNullValues,
    );

    return doc;
  }

  String _getCollectionPath(YustDocSetup modelSetup) {
    var collectionPath = modelSetup.collectionName;
    if (Yust.useSubcollections && modelSetup.forEnvironment) {
      collectionPath = Yust.envCollectionName +
          '/' +
          Yust.currEnvId! +
          '/' +
          modelSetup.collectionName;
    }
    return collectionPath;
  }

  Query _filterForEnvironment(Query query) =>
      query.where('envId', isEqualTo: Yust.currEnvId);

  Query _filterForUser(Query query) =>
      query.where('userId', isEqualTo: Yust.authService.currUserId);

  Query _executeStaticFilters<T extends YustDoc>(
    Query query,
    YustDocSetup<T> modelSetup,
  ) {
    if (!Yust.useSubcollections && modelSetup.forEnvironment) {
      query = _filterForEnvironment(query);
    }
    if (modelSetup.forUser) {
      query = _filterForUser(query);
    }
    return query;
  }

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
}
