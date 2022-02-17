import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:yust/models/yust_doc.dart';
import 'package:yust/models/yust_doc_setup.dart';

import '../yust.dart';

class YustDatabaseService {
  FirebaseFirestore fireStore;

  YustDatabaseService() : fireStore = FirebaseFirestore.instance;
  YustDatabaseService.mocked() : fireStore = new FakeFirebaseFirestore();

  /// Initialises a document with an id and the time it was created.
  ///
  /// Optionally an existing document can be given, which will still be
  /// assigned a new id becoming a new document if it had an id previously.
  T initDoc<T extends YustDoc>(YustDocSetup<T> modelSetup, [T? doc]) {
    if (doc == null) {
      doc = modelSetup.newDoc();
    }
    doc.id = fireStore.collection(_getCollectionPath(modelSetup)).doc().id;
    doc.createdAt = DateTime.now();
    doc.createdBy = Yust.store.currUser?.id;
    if (modelSetup.forEnvironment) {
      doc.envId = Yust.store.currUser?.currEnvId;
    }
    if (modelSetup.forUser) {
      doc.userId = Yust.store.currUser?.id;
    }
    if (modelSetup.onInit != null) {
      modelSetup.onInit!(doc);
    }
    return doc;
  }

  Query<Object?> getQuery<T extends YustDoc>(
      {required YustDocSetup<T> modelSetup,
      List<List<dynamic>>? filterList,
      List<String>? orderByList}) {
    Query query = fireStore.collection(_getCollectionPath(modelSetup));
    query = _executeStaticFilters(query, modelSetup);
    query = _executeFilterList(query, filterList);
    query = _executeOrderByList(query, orderByList);

    return query;
  }

  ///[filterList] each entry represents a condition that has to be met.
  ///All of those conditions must be true for each returned entry.
  ///
  ///Consists at first of the column name followed by either 'ASC' or 'DESC'.
  ///Multiple of those entries can be repeated.
  ///
  ///[filterList] may be null.
  Stream<List<T>> getDocs<T extends YustDoc>(
    YustDocSetup<T> modelSetup, {
    List<List<dynamic>>? filterList,
    List<String>? orderByList,
  }) {
    Query query = getQuery(
        modelSetup: modelSetup,
        orderByList: orderByList,
        filterList: filterList);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((docSnapshot) => transformDoc(modelSetup, docSnapshot))
          .whereType<T>()
          .toList();
    });
  }

  Future<List<T>> getDocsOnce<T extends YustDoc>(
    YustDocSetup<T> modelSetup, {
    List<List<dynamic>>? filterList,
    List<String>? orderByList,
  }) {
    Query query = getQuery(
        modelSetup: modelSetup,
        orderByList: orderByList,
        filterList: filterList);

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
      return modelSetup.fromJson(data);
    }
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

  Future<T> getDocOnce<T extends YustDoc>(
    YustDocSetup<T> modelSetup,
    String id,
  ) {
    return fireStore
        .collection(_getCollectionPath(modelSetup))
        .doc(id)
        .get(GetOptions(source: Source.server))
        .then((docSnapshot) => transformDoc<T>(modelSetup, docSnapshot)!);
  }

  /// Emits null events if no document was found.
  Stream<T?> getFirstDoc<T extends YustDoc>(
    YustDocSetup<T> modelSetup,
    List<List<dynamic>>? filterList, {
    List<String>? orderByList,
  }) {
    Query query = getQuery(
        modelSetup: modelSetup,
        filterList: filterList,
        orderByList: orderByList);

    return query.snapshots().map<T?>((snapshot) {
      if (snapshot.docs.length > 0) {
        return transformDoc(modelSetup, snapshot.docs[0]);
      } else {
        return null;
      }
    });
  }

  /// The result is null if no document was found.
  Future<T?> getFirstDocOnce<T extends YustDoc>(
    YustDocSetup<T> modelSetup,
    List<List<dynamic>> filterList, {
    List<String>? orderByList,
  }) async {
    Query query = getQuery(
        modelSetup: modelSetup,
        filterList: filterList,
        orderByList: orderByList);
    final snapshot = await query.get(GetOptions(source: Source.server));
    T? doc;

    if (snapshot.docs.length > 0) {
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
  }) async {
    var collection = fireStore.collection(_getCollectionPath(modelSetup));
    if (trackModification) {
      doc.modifiedAt = DateTime.now();
      doc.modifiedBy = Yust.store.currUser?.id;
    }
    if (doc.createdAt == null) {
      doc.createdAt = doc.modifiedAt;
    }
    if (doc.createdBy == null) {
      doc.createdBy = doc.modifiedBy;
    }
    if (doc.userId == null && modelSetup.forUser) {
      doc.userId = Yust.store.currUser!.id;
    }
    if (doc.envId == null && modelSetup.forEnvironment) {
      doc.envId = Yust.store.currUser!.currEnvId;
    }
    if (modelSetup.onSave != null && !skipOnSave) {
      await modelSetup.onSave!(doc);
    }
    final jsonDoc = doc.toJson();
    await collection.doc(doc.id).set(jsonDoc, SetOptions(merge: merge));
  }

  Future<void> deleteDocs<T extends YustDoc>(
    YustDocSetup<T> modelSetup, {
    List<List<dynamic>>? filterList,
  }) async {
    final docs = await getDocsOnce<T>(modelSetup, filterList: filterList);
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
    required T doc,
    Future<void> Function(T)? onInitialised,
  }) async {
    doc = initDoc<T>(modelSetup, doc);

    if (onInitialised != null) {
      await onInitialised(doc);
    }

    await saveDoc<T>(modelSetup, doc);

    return doc;
  }

  String _getCollectionPath(YustDocSetup modelSetup) {
    var collectionPath = modelSetup.collectionName;
    if (Yust.useSubcollections && modelSetup.forEnvironment) {
      collectionPath = Yust.envCollectionName +
          '/' +
          Yust.store.currUser!.currEnvId! +
          '/' +
          modelSetup.collectionName;
    }
    return collectionPath;
  }

  Query _filterForEnvironment(Query query) =>
      query.where('envId', isEqualTo: Yust.store.currUser!.currEnvId);

  Query _filterForUser(Query query) =>
      query.where('userId', isEqualTo: Yust.store.currUser!.id);

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

  ///[filterList] may be null.
  ///If it is not each contained list may not be null
  ///and has to have a length of three.
  Query _executeFilterList(Query query, List<List<dynamic>>? filterList) {
    if (filterList != null) {
      for (var filter in filterList) {
        assert(filter.length == 3);
        var operand1 = filter[0], operator = filter[1], operand2 = filter[2];

        switch (operator) {
          case '==':
            query = query.where(operand1, isEqualTo: operand2);
            break;
          case '<':
            query = query.where(operand1, isLessThan: operand2);
            break;
          case '<=':
            query = query.where(operand1, isLessThanOrEqualTo: operand2);
            break;
          case '>':
            query = query.where(operand1, isGreaterThan: operand2);
            break;
          case '>=':
            query = query.where(operand1, isGreaterThanOrEqualTo: operand2);
            break;
          case 'in':
            // If null is passed for the filter list, no filter is applied at all.
            // If an empty list is passed, an error is thrown.
            // I think that it should behave the same and return no data.

            if (operand2 != null && operand2 is List && operand2.isEmpty) {
              operand2 = null;
            }

            query = query.where(operand1, whereIn: operand2);

            // Makes sure that no data is returned.
            if (operand2 == null) {
              query = query.where(operand1, isEqualTo: true, isNull: true);
            }
            break;
          case 'arrayContains':
            query = query.where(operand1, arrayContains: operand2);
            break;
          case 'isNull':
            query = query.where(operand1, isNull: operand2);
            break;
          default:
            throw 'The operator "$operator" is not supported.';
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
