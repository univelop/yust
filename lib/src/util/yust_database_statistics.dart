import 'package:collection/collection.dart';

import '../models/yust_doc_setup.dart';
import '../yust.dart';

typedef StatisticsMap = Map<String, Map<DatabaseLogAction, int>>;

class YustDatabaseStatistics {
  final StatisticsMap _statistics = {};

  void dbStatisticsCallback(
      DatabaseLogAction action, YustDocSetup setup, int count,
      {String? id, List<String>? updateMask, num? aggregationResult}) {
    _statistics[setup.collectionName] ??= {};
    _statistics[setup.collectionName]![action] ??= 0;
    _statistics[setup.collectionName]![action] =
        _statistics[setup.collectionName]![action]! + count;
  }

  clear() => _statistics.clear();

  StatisticsMap get statistics => _statistics;

  /// Gets the count for a specific action in a specific collection
  int getCount(String collectionName, DatabaseLogAction action) {
    return _statistics[collectionName]?[action] ?? 0;
  }

  /// Gets the count for a specific action over all collections
  int getActionCount(DatabaseLogAction action) =>
      _statistics.values.map((e) => e[action] ?? 0).sum;

  /// Gets the total "read" count for the given action.
  /// This includes the actions "get" and "aggregate".
  int getTotalReadCount(DatabaseLogAction action) => _statistics.values
      .expand((v) => v.entries
          .where((e) => [DatabaseLogAction.get, DatabaseLogAction.aggregate]
              .contains(e.key))
          .map((e) => e.value))
      .sum;

  /// Gets the total "write" count for the given action.
  /// This includes the actions "transform", "delete", "save" and "saveNew".
  int getTotalWriteCount(DatabaseLogAction action) => _statistics.values
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
