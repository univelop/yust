import 'package:test/test.dart';
import 'package:yust/src/services/yust_file_service_shared.dart';

void main() {
  group('YustFileMetadata.md5HexFromBase64', () {
    test('converts the base64 md5 storage reports into hex', () {
      // md5('hello') = 5d41402abc4b2a76b9719d911017c592
      expect(
        YustFileMetadata.md5HexFromBase64('XUFAKrxLKna5cZ2REBfFkg=='),
        '5d41402abc4b2a76b9719d911017c592',
      );
    });

    test('returns null when storage reports no hash', () {
      expect(YustFileMetadata.md5HexFromBase64(null), isNull);
      expect(YustFileMetadata.md5HexFromBase64(''), isNull);
    });
  });
}
