import 'package:collection/collection.dart';

import '../yust.dart';

typedef YustStatisticsMap = Map<String, Map<DatabaseLogAction, int>>;
typedef YustAggregatedStatisticsMap = Map<DatabaseLogAction, int>;
typedef YustEnhancedStatisticsMap = Map<String, int>;

class YustDatabaseStatistics {
  // Contains statistics for each collection, e.g. "collection"
  final YustStatisticsMap _statistics = {};
  // Contains statistics for each collection including it's parent, e.g. "parent_collection/parent_id/collection"
  final YustStatisticsMap _statisticsTwoSegments = {};

  void dbStatisticsCallback(
    DatabaseLogAction action,
    String documentPath,
    int count, {
    String? id,
    List<String>? updateMask,
    num? aggregationResult,
  }) {
    final collectionGroupName = documentPath
        .split('/')
        .lastWhereOrNull((e) => e.isNotEmpty);
    final collectionNameIncludingParent = documentPath
        .split('/')
        .reversed
        .take(3)
        .toList()
        .reversed
        .join('/');

    if (collectionGroupName == null) return;
    _statistics[collectionGroupName] ??= {};
    _statistics[collectionGroupName]![action] ??= 0;
    _statistics[collectionGroupName]![action] =
        _statistics[collectionGroupName]![action]! + count;

    _statisticsTwoSegments[collectionNameIncludingParent] ??= {};
    _statisticsTwoSegments[collectionNameIncludingParent]![action] ??= 0;
    _statisticsTwoSegments[collectionNameIncludingParent]![action] =
        _statisticsTwoSegments[collectionNameIncludingParent]![action]! + count;

    if (count == 0) {
      _statistics[collectionGroupName]![DatabaseLogAction
              .emptyReadOrAggregate] =
          (_statistics[collectionGroupName]![DatabaseLogAction
                  .emptyReadOrAggregate] ??
              0) +
          1;
      _statisticsTwoSegments[collectionNameIncludingParent]![DatabaseLogAction
              .emptyReadOrAggregate] =
          (_statisticsTwoSegments[collectionNameIncludingParent]![DatabaseLogAction
                  .emptyReadOrAggregate] ??
              0) +
          1;
    }
  }

  void clear() {
    _statistics.clear();
    _statisticsTwoSegments.clear();
  }

  YustStatisticsMap get statistics => _statistics;
  YustStatisticsMap get statisticsTwoSegments => _statisticsTwoSegments;

  YustAggregatedStatisticsMap get aggregatedStatistics => Map.fromEntries(
    DatabaseLogAction.values.map((key) => MapEntry(key, getActionCount(key))),
  );

  YustEnhancedStatisticsMap get enhancedStatistics =>
      aggregatedStatistics.map((key, value) => MapEntry(key.toJson(), value))
        ..addAll({
          'totalRead': getTotalReadCount(),
          'totalWrite': getTotalWriteCount(),
        });

  Map<String, dynamic> toJson() => _statistics.map(
    (key, value) =>
        MapEntry(key, value.map((key, value) => MapEntry(key.toJson(), value))),
  );

  /// Gets the count for a specific action in a specific collection
  int getCount(String collectionName, DatabaseLogAction action) {
    return _statistics[collectionName]?[action] ?? 0;
  }

  /// Gets the count for a specific action over all collections
  int getActionCount(DatabaseLogAction action) =>
      _statistics.values.map((e) => e[action] ?? 0).sum;

  /// Gets the total "read" count for the given action.
  /// This includes the actions "get", "aggregate" and "emptyReadOrAggregate".
  ///
  /// The results are according to the firestore pricing, so this will give you a somehow realistic number of reads.
  int getTotalReadCount() =>
      getActionCount(DatabaseLogAction.get) +
      (getActionCount(DatabaseLogAction.aggregate) / 1000).ceil() +
      getActionCount(DatabaseLogAction.emptyReadOrAggregate);

  /// Gets the total "write" count for the given action.
  /// This includes the actions "transform", "delete", "save" and "saveNew".
  int getTotalWriteCount() => _statistics.values
      .expand(
        (v) => v.entries
            .where(
              (e) => [
                DatabaseLogAction.transform,
                DatabaseLogAction.delete,
                DatabaseLogAction.save,
                DatabaseLogAction.saveNew,
              ].contains(e.key),
            )
            .map((e) => e.value),
      )
      .sum;
}
