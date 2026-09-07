import 'package:test/test.dart';
import 'package:yust/src/services/yust_database_service_shared.dart';

void main() {
  group('cleanUpdateMask', () {
    test(
      'drops stale nested paths when the field was cleared to null (map→null)',
      () {
        final data = {
          'brickValues': {'f3VOLnWX': null},
        };
        final mask = [
          'brickValues.f3VOLnWX.selectedId',
          'brickValues.f3VOLnWX.labelMl.de',
          'brickValues.f3VOLnWX',
        ];

        expect(
          cleanUpdateMask(data, mask),
          unorderedEquals(['brickValues.f3VOLnWX']),
        );
      },
    );

    test('collapses a pure child path to the nearest existing ancestor', () {
      final data = {
        'brickValues': {'f3VOLnWX': null},
      };
      final mask = ['brickValues.f3VOLnWX.selectedId'];

      expect(
        cleanUpdateMask(data, mask),
        unorderedEquals(['brickValues.f3VOLnWX']),
      );
    });

    test('collapses overlapping ancestor and descendant paths', () {
      final data = {
        'a': {
          'b': {'c': 1},
        },
      };
      final mask = ['a', 'a.b.c'];

      expect(cleanUpdateMask(data, mask), unorderedEquals(['a']));
    });

    test('keeps a valid nested map mask unchanged', () {
      final data = {
        'a': {
          'b': {'c': 1, 'd': 2},
        },
      };
      final mask = ['a.b.c', 'a.b.d'];

      expect(cleanUpdateMask(data, mask), unorderedEquals(['a.b.c', 'a.b.d']));
    });

    test('keeps scalar field paths unchanged', () {
      final data = {'name': 'foo', 'count': 1, 'flag': null};
      final mask = ['name', 'count', 'flag'];

      expect(
        cleanUpdateMask(data, mask),
        unorderedEquals(['name', 'count', 'flag']),
      );
    });

    test('keeps a whole-field path when the data holds a map (null→map)', () {
      final data = {
        'brickValues': {
          'f3VOLnWX': {'selectedId': 'status_2'},
        },
      };
      final mask = ['brickValues.f3VOLnWX'];

      expect(
        cleanUpdateMask(data, mask),
        unorderedEquals(['brickValues.f3VOLnWX']),
      );
    });

    test('drops a path whose first segment does not exist in the data', () {
      final data = {'name': 'foo'};
      final mask = ['missing.bar', 'name'];

      expect(cleanUpdateMask(data, mask), unorderedEquals(['name']));
    });

    test('tolerates backtick-quoted segments', () {
      final data = {
        'brickValues': {'0abc': null},
      };
      final mask = ['brickValues.`0abc`.selectedId'];

      expect(
        cleanUpdateMask(data, mask),
        unorderedEquals(['brickValues.`0abc`']),
      );
    });

    test('deduplicates paths that resolve to the same existing ancestor', () {
      final data = {
        'brickValues': {'f3VOLnWX': null},
      };
      final mask = [
        'brickValues.f3VOLnWX.selectedId',
        'brickValues.f3VOLnWX.labelMl.de',
      ];

      expect(
        cleanUpdateMask(data, mask),
        unorderedEquals(['brickValues.f3VOLnWX']),
      );
    });

    test('returns an empty mask for an empty input mask', () {
      expect(cleanUpdateMask({'a': 1}, []), isEmpty);
    });
  });
}
