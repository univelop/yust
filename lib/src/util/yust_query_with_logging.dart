import 'package:cloud_firestore/cloud_firestore.dart';

import '../yust.dart';

// ignore: subtype_of_sealed_class
/// A Custom implementation of [Query] that logs all actions to a callback.
///
/// Its very closely based on the [_WithConverterQuery] class from the Firestore package.
class YustQueryWithLogging implements Query {
  YustQueryWithLogging(
    this._dbLogCallback,
    this._originalQuery,
  );

  final Query _originalQuery;
  final DatabaseLogCallback _dbLogCallback;

  @override
  FirebaseFirestore get firestore => _originalQuery.firestore;

  @override
  Map<String, dynamic> get parameters => _originalQuery.parameters;

  Query _mapQuery(
    Query newOriginalQuery,
  ) =>
      YustQueryWithLogging(
        _dbLogCallback,
        newOriginalQuery,
      );

  @override
  Future<QuerySnapshot> get([GetOptions? options]) async {
    final snapshot = await _originalQuery.get(options);
    if (snapshot.docs.isNotEmpty) {
      for (final doc in snapshot.docs) {
        _dbLogCallback(
            DatabaseLogAction.fromSnapshot(doc), doc.reference.parent.path, 1);
      }
    }

    return snapshot;
  }

  @override
  Stream<QuerySnapshot> snapshots({bool includeMetadataChanges = false}) =>
      _originalQuery
          .snapshots(includeMetadataChanges: includeMetadataChanges)
          .map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            _dbLogCallback(DatabaseLogAction.fromSnapshot(doc),
                doc.reference.parent.path, 1);
          }
        }
        return snapshot;
      });

  @override
  Query<R> withConverter<R extends Object?>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) =>
      throw UnimplementedError();

  // ########################################################################
  // #                                                                      #
  // # NO Custom logic below here, just passing through to _originalQuery   #
  // #                                                                      #
  // ########################################################################

  @override
  Query endAt(Iterable<Object?> values) =>
      _mapQuery(_originalQuery.endAt(values));

  @override
  Query endAtDocument(DocumentSnapshot documentSnapshot) =>
      _mapQuery(_originalQuery.endAtDocument(documentSnapshot));

  @override
  Query endBefore(Iterable<Object?> values) =>
      _mapQuery(_originalQuery.endBefore(values));

  @override
  Query endBeforeDocument(DocumentSnapshot documentSnapshot) =>
      _mapQuery(_originalQuery.endBeforeDocument(documentSnapshot));

  @override
  Query limit(int limit) => _mapQuery(_originalQuery.limit(limit));

  @override
  Query limitToLast(int limit) => _mapQuery(_originalQuery.limitToLast(limit));

  @override
  Query orderBy(Object field, {bool descending = false}) =>
      _mapQuery(_originalQuery.orderBy(field, descending: descending));

  @override
  Query startAfter(Iterable<Object?> values) =>
      _mapQuery(_originalQuery.startAfter(values));

  @override
  Query startAfterDocument(DocumentSnapshot documentSnapshot) =>
      _mapQuery(_originalQuery.startAfterDocument(documentSnapshot));

  @override
  Query startAt(Iterable<Object?> values) =>
      _mapQuery(_originalQuery.startAt(values));

  @override
  Query startAtDocument(DocumentSnapshot documentSnapshot) =>
      _mapQuery(_originalQuery.startAtDocument(documentSnapshot));

  @override
  Query where(Object field,
          {Object? isEqualTo,
          Object? isNotEqualTo,
          Object? isLessThan,
          Object? isLessThanOrEqualTo,
          Object? isGreaterThan,
          Object? isGreaterThanOrEqualTo,
          Object? arrayContains,
          Iterable<Object?>? arrayContainsAny,
          Iterable<Object?>? whereIn,
          Iterable<Object?>? whereNotIn,
          bool? isNull}) =>
      _mapQuery(_originalQuery.where(field,
          isEqualTo: isEqualTo,
          isNotEqualTo: isNotEqualTo,
          isLessThan: isLessThan,
          isLessThanOrEqualTo: isLessThanOrEqualTo,
          isGreaterThan: isGreaterThan,
          isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
          arrayContains: arrayContains,
          arrayContainsAny: arrayContainsAny,
          whereIn: whereIn,
          whereNotIn: whereNotIn,
          isNull: isNull));

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is YustQueryWithLogging &&
        other._dbLogCallback == _dbLogCallback &&
        other._originalQuery == _originalQuery;
  }

  @override
  int get hashCode => Object.hash(runtimeType, _dbLogCallback, _originalQuery);

  @override
  AggregateQuery count() => _originalQuery.count();

  @override
  AggregateQuery aggregate(AggregateField aggregateField1,
          [AggregateField? aggregateField2,
          AggregateField? aggregateField3,
          AggregateField? aggregateField4,
          AggregateField? aggregateField5,
          AggregateField? aggregateField6,
          AggregateField? aggregateField7,
          AggregateField? aggregateField8,
          AggregateField? aggregateField9,
          AggregateField? aggregateField10,
          AggregateField? aggregateField11,
          AggregateField? aggregateField12,
          AggregateField? aggregateField13,
          AggregateField? aggregateField14,
          AggregateField? aggregateField15,
          AggregateField? aggregateField16,
          AggregateField? aggregateField17,
          AggregateField? aggregateField18,
          AggregateField? aggregateField19,
          AggregateField? aggregateField20,
          AggregateField? aggregateField21,
          AggregateField? aggregateField22,
          AggregateField? aggregateField23,
          AggregateField? aggregateField24,
          AggregateField? aggregateField25,
          AggregateField? aggregateField26,
          AggregateField? aggregateField27,
          AggregateField? aggregateField28,
          AggregateField? aggregateField29,
          AggregateField? aggregateField30]) =>
      _originalQuery.aggregate(
          aggregateField1,
          aggregateField2,
          aggregateField3,
          aggregateField4,
          aggregateField5,
          aggregateField6,
          aggregateField7,
          aggregateField8,
          aggregateField9,
          aggregateField10,
          aggregateField11,
          aggregateField12,
          aggregateField13,
          aggregateField14,
          aggregateField15,
          aggregateField16,
          aggregateField17,
          aggregateField18,
          aggregateField19,
          aggregateField20,
          aggregateField21,
          aggregateField22,
          aggregateField23,
          aggregateField24,
          aggregateField25,
          aggregateField26,
          aggregateField27,
          aggregateField28,
          aggregateField29,
          aggregateField30);
}
