import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:yust/src/services/yust_file_service_mocked.dart';
import 'package:yust/yust.dart';

/// The mocked file service runs only without `dart:ui`, as in the Dart-only
/// packages that use it.
const _hasFlutter = bool.fromEnvironment('dart.library.ui');

void main() {
  group(
    'YustFileServiceMocked',
    skip: _hasFlutter ? 'Runs with `dart test` only.' : false,
    _defineTests,
  );
}

void _defineTests() {
  late YustFileServiceMocked fileService;
  var folderIndex = 0;
  late String folderPath;
  final contentBytes = Uint8List.fromList('content'.codeUnits);

  setUp(() {
    fileService = YustFileServiceMocked();
    // The mocked storage is shared between instances, so each test gets its
    // own folder.
    folderPath = 'records/rec${folderIndex++}';
  });

  group('downloadFileOrThrow', () {
    test('returns the stored bytes', () async {
      await fileService.uploadFile(
        path: folderPath,
        name: 'a.pdf',
        bytes: contentBytes,
      );

      expect(
        await fileService.downloadFileOrThrow(path: folderPath, name: 'a.pdf'),
        contentBytes,
      );
    });

    test('throws YustNotFoundException for a missing object', () async {
      await expectLater(
        fileService.downloadFileOrThrow(path: folderPath, name: 'missing.pdf'),
        throwsA(isA<YustNotFoundException>()),
      );
    });
  });

  group('copyFile', () {
    test(
      'stores the bytes under the new name and keeps the original',
      () async {
        await fileService.uploadFile(
          path: folderPath,
          name: 'old.pdf',
          bytes: contentBytes,
        );

        final url = await fileService.copyFile(
          path: folderPath,
          name: 'old.pdf',
          newName: 'new.pdf',
        );

        expect(url, contains('new.pdf'));
        expect(
          await fileService.downloadFileOrThrow(
            path: folderPath,
            name: 'new.pdf',
          ),
          contentBytes,
        );
        expect(
          await fileService.fileExist(path: folderPath, name: 'old.pdf'),
          isTrue,
        );
      },
    );

    test('throws YustNotFoundException for a missing source', () async {
      await expectLater(
        fileService.copyFile(
          path: folderPath,
          name: 'missing.pdf',
          newName: 'new.pdf',
        ),
        throwsA(isA<YustNotFoundException>()),
      );
      expect(
        await fileService.fileExist(path: folderPath, name: 'new.pdf'),
        isFalse,
      );
    });
  });
}
