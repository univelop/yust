import 'package:test/test.dart';
import 'package:yust/src/services/yust_database_service_shared.dart';
import 'package:yust/yust.dart';

void main() {
  group('assertValidPathSegment', () {
    const validIds = [
      'aB3dE5gH7jK9mN1pQ3sT',
      'record_1-2',
      'a.b',
      '...a',
      'äöü',
      '_a_',
      '__a',
    ];

    for (final id in validIds) {
      test('accepts "$id"', () {
        expect(() => assertValidPathSegment(id), returnsNormally);
      });
    }

    final invalidIds = {
      'null': null,
      'empty': '',
      'single dot': '.',
      'double dot': '..',
      'slash': 'a/b',
      'leading slash': '/abc',
      'traversal': '../../../../otherEnv/recordSpecs/spec/records/rec',
      'backslash': r'a\b',
      'reserved': '__name__',
      'newline': 'a\nb',
      'null byte': 'a\x00b',
      'too long': 'a' * 1501,
    };

    invalidIds.forEach((name, id) {
      test('rejects $name', () {
        expect(
          () => assertValidPathSegment(id),
          throwsA(isA<YustInvalidPathSegmentException>()),
        );
      });
    });

    test('accepts the maximum length of 1500 bytes', () {
      expect(() => assertValidPathSegment('a' * 1500), returnsNormally);
    });

    test('counts bytes, not characters', () {
      // 'ä' is 2 bytes in UTF-8
      expect(
        () => assertValidPathSegment('ä' * 751),
        throwsA(isA<YustInvalidPathSegmentException>()),
      );
    });
  });

  group('assertValidDocSetupPath', () {
    YustDocSetup<YustNotification> setup({
      String collectionName = 'notifications',
      String? envId = 'env1',
    }) => YustDocSetup<YustNotification>(
      collectionName: collectionName,
      envId: envId,
      fromJson: YustNotification.fromJson,
      forEnvironment: true,
    );

    test('accepts nested collection names', () {
      expect(
        () => assertValidDocSetupPath(
          setup(collectionName: 'recordSpecs/spec1/records'),
          withEnvironment: true,
        ),
        returnsNormally,
      );
    });

    test('rejects traversal in a collection name segment', () {
      expect(
        () => assertValidDocSetupPath(
          setup(collectionName: 'recordSpecs/../records'),
          withEnvironment: true,
        ),
        throwsA(isA<YustInvalidPathSegmentException>()),
      );
    });

    test('rejects empty collection name segments', () {
      expect(
        () => assertValidDocSetupPath(
          setup(collectionName: 'recordSpecs//records'),
          withEnvironment: true,
        ),
        throwsA(isA<YustInvalidPathSegmentException>()),
      );
    });

    test('rejects an invalid environment id', () {
      expect(
        () => assertValidDocSetupPath(
          setup(envId: '../otherEnv'),
          withEnvironment: true,
        ),
        throwsA(isA<YustInvalidPathSegmentException>()),
      );
    });

    test('ignores the environment id without environment', () {
      expect(
        () => assertValidDocSetupPath(
          setup(envId: '../otherEnv'),
          withEnvironment: false,
        ),
        returnsNormally,
      );
    });

    test('tolerates a null environment id', () {
      expect(
        () =>
            assertValidDocSetupPath(setup(envId: null), withEnvironment: true),
        returnsNormally,
      );
    });
  });
}
