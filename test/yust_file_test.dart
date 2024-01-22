import 'package:test/test.dart';
import 'package:yust/yust.dart';

void main() {
  group('The remove extension', () {
    test('Remove extension easy', () {
      final helper = YustFile(name: 'test.html');
      var filename = helper.getFileNameWithoutExtension();

      expect(filename, 'test');
    });

    test('Remove extension hard', () {
      final helper = YustFile(name: 'test.west.spec.html');
      var filename = helper.getFileNameWithoutExtension();

      expect(filename, 'test.west.spec');
    });

    test('no extension', () {
      final helper = YustFile(name: 'test');
      var filename = helper.getFileNameWithoutExtension();

      expect(filename, 'test');
    });
  });

  group('get extension', () {
    test('Remove extension easy', () {
      final helper = YustFile(name: 'test.html');
      var filename = helper.getFilenameExtension();

      expect(filename, 'html');
    });

    test('Remove extension hard', () {
      final helper = YustFile(name: 'test.west.spec.html');
      var filename = helper.getFilenameExtension();

      expect(filename, 'html');
    });

    test('no extension', () {
      final helper = YustFile(name: 'test');
      var filename = helper.getFilenameExtension();

      expect(filename, '');
    });
  });
}
