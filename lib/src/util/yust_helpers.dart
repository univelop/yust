import 'dart:math';

class YustHelpers {
  String randomString({int length = 8}) {
    final rnd = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    var result = '';
    for (var i = 0; i < length; i++) {
      result += chars[rnd.nextInt(chars.length)];
    }
    return result;
  }

  void removeKeysFromMap(Map<String, dynamic> object, List<String> keys) {
    object.removeWhere((key, _) => keys.contains(key));
  }

  void preserveKeysInMap(Map<String, dynamic> object, List<String> keys) {
    object.removeWhere((key, _) => !keys.contains(key));
  }
}
