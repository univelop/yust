import 'package:collection/collection.dart';

import '../models/yust_doc_setup.dart';
import '../yust.dart';

typedef YustStatisticsMap = Map<String, Map<DatabaseLogAction, int>>;
typedef YustAggregatedStatisticsMap = Map<DatabaseLogAction, int>;
typedef YustEnhancedStatisticsMap = Map<String, int>;

class YustDatabaseStatistics {
  final YustStatisticsMap _statistics = {};

  void dbStatisticsCallback(
      DatabaseLogAction action, YustDocSetup setup, int count,
      {String? id, List<String>? updateMask, num? aggregationResult}) {
    final collectionGroupName = setup.collectionName.split('/').last;
    _statistics[collectionGroupName] ??= {};
    _statistics[collectionGroupName]![action] ??= 0;
    _statistics[collectionGroupName]![action] =
        _statistics[collectionGroupName]![action]! + count;
  }

  clear() => _statistics.clear();

  YustStatisticsMap get statistics => _statistics;

  YustAggregatedStatisticsMap get aggregatedStatistics =>
      Map.fromEntries(DatabaseLogAction.values
          .map((key) => MapEntry(key, getActionCount(key))));

  YustEnhancedStatisticsMap get enhancedStatistics =>
      aggregatedStatistics.map((key, value) => MapEntry(key.toJson(), value))
        ..addAll({
          'totalRead': getTotalReadCount(),
          'totalWrite': getTotalWriteCount(),
        });

  Map<String, dynamic> toJson() => _statistics.map((key, value) =>
      MapEntry(key, value.map((key, value) => MapEntry(key.toJson(), value))));

  /// Gets the count for a specific action in a specific collection
  int getCount(String collectionName, DatabaseLogAction action) {
    return _statistics[collectionName]?[action] ?? 0;
  }

  /// Gets the count for a specific action over all collections
  int getActionCount(DatabaseLogAction action) =>
      _statistics.values.map((e) => e[action] ?? 0).sum;

  /// Gets the total "read" count for the given action.
  /// This includes the actions "get"
  int getTotalReadCount() => getActionCount(DatabaseLogAction.get);

  /// Gets the total "write" count for the given action.
  /// This includes the actions "transform", "delete", "save" and "saveNew".
  int getTotalWriteCount() => _statistics.values
      .expand((v) => v.entries
          .where((e) => [
                DatabaseLogAction.transform,
                DatabaseLogAction.delete,
                DatabaseLogAction.save,
                DatabaseLogAction.saveNew
              ].contains(e.key))
          .map((e) => e.value))
      .sum;
}
