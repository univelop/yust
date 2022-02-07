import 'dart:collection';

class TraversalInfo {
  final LinkedHashSet<dynamic> visitedNodes;
  final List<String> currentPath;
  final int depth;
  final bool cloneObject;
  final bool isInList;
  TraversalInfo({
    required this.visitedNodes,
    required this.currentPath,
    required this.depth,
    required this.cloneObject,
    required this.isInList,
  });
}

class TraversalCurrentNode {
  final dynamic parent;

  /// The Key can be string (for maps) or number (for lists)
  final dynamic key;
  final dynamic value;
  final TraversalInfo info;
  TraversalCurrentNode(
      {required this.parent,
      required this.key,
      required this.value,
      required this.info});
}

typedef TraversalCallback = dynamic Function(TraversalCurrentNode currentNode);

class TraverseObject {
  static dynamic _shallowClone(dynamic obj) {
    if (obj is List || obj is Set) return [...obj];
    if (obj is Map) return {...obj};
    return obj;
  }

  static bool _isBuiltIn(dynamic obj) {
    return obj is DateTime || obj is Function;
  }

  static List<dynamic> _keys(dynamic obj) {
    if (obj is List || obj is Set)
      return [for (var i = 0; i < obj.length; i++) i];
    if (obj is Map) return obj.keys.toList();
    return [];
  }

  static Map<String, dynamic> traverseObject(
    Map<String, dynamic> obj,
    TraversalCallback leafNodeCallback, {
    TraversalCallback? innerNodeCallback,
    bool cloneObject = true,
  }) {
    final info = TraversalInfo(
      visitedNodes: LinkedHashSet<dynamic>(),
      currentPath: [],
      depth: 0,
      cloneObject: cloneObject,
      isInList: false,
    );

    if (_isBuiltIn(obj)) return obj;

    return Map<String, dynamic>.from(_traverseRecursive(
      cloneObject ? _shallowClone(obj) : obj,
      leafNodeCallback,
      innerNodeCallback ?? (currentNode) => currentNode.value,
      info,
    ));
  }

  static dynamic _traverseRecursive(
    dynamic obj,
    TraversalCallback leafNodeCallback,
    TraversalCallback innerNodeCallback,
    TraversalInfo info,
  ) {
    if (info.visitedNodes.contains(obj)) return obj;

    info.visitedNodes.add(obj);

    for (final key in _keys(obj)) {
      final value = (obj)[key];
      final currentPath = List<String>.from(info.currentPath);
      currentPath.add(key.toString());

      final newInfo = TraversalInfo(
        currentPath: currentPath,
        visitedNodes: info.visitedNodes,
        depth: info.depth + 1,
        cloneObject: info.cloneObject,
        isInList: info.isInList || obj is List || obj is Set,
      );

      // We don't touch functions or built-ins
      if (_isBuiltIn(value)) continue;

      // Check if we can traverse deeper
      // We need to check if not null because of 'typeof null == "object"'
      if (value is List || value is Map || value is Set) {
        // When we are at a leaf node, first call the innerNodeCallback
        final clonedValue = info.cloneObject ? _shallowClone(value) : value;
        innerNodeCallback(
          TraversalCurrentNode(
            parent: obj,
            key: key,
            value: clonedValue,
            info: newInfo,
          ),
        );
        obj[key] = _traverseRecursive(
          clonedValue,
          leafNodeCallback,
          innerNodeCallback,
          newInfo,
        );
      } else if (value != null) {
        // When we are at a leaf node, call the leafNodeCallback
        obj[key] = leafNodeCallback(
          TraversalCurrentNode(
            parent: obj,
            key: key,
            value: value,
            info: newInfo,
          ),
        );
      }
    }
    return obj;
  }
}
