import 'dart:collection';

class TraversalInfo {
  final LinkedHashSet<dynamic> visitedNodes;
  final String? currentPath;
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
    TraversalCallback callback, {
    bool cloneObject = true,
  }) {
    final info = TraversalInfo(
      visitedNodes: new LinkedHashSet<dynamic>(),
      currentPath: null,
      depth: 0,
      cloneObject: cloneObject,
      isInList: false,
    );

    if (_isBuiltIn(obj)) return obj;

    return Map<String, dynamic>.from(_traverseRecursive(
        cloneObject ? _shallowClone(obj) : obj, callback, info));
  }

  static dynamic _traverseRecursive(
    dynamic obj,
    TraversalCallback callback,
    TraversalInfo info,
  ) {
    if (info.visitedNodes.contains(obj)) return obj;

    info.visitedNodes.add(obj);

    for (final key in _keys(obj)) {
      final value = (obj)[key];
      final previousPath = info.currentPath;
      final currentPath =
          previousPath == null ? "${key}" : "${previousPath}.${key}";

      final newInfo = new TraversalInfo(
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
        obj[key] = _traverseRecursive(
            info.cloneObject ? _shallowClone(value) : value, callback, newInfo);
      } else if (value != null) {
        // When we are at a leaf node, call the callback
        obj[key] = callback(
          new TraversalCurrentNode(
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
