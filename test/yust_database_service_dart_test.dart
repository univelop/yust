import 'package:test/test.dart';
import 'package:yust/src/models/yust_doc.dart';
import 'package:yust/src/models/yust_filter.dart';
import 'package:yust/src/models/yust_order_by.dart';
import 'package:yust/src/services/yust_database_service_dart.dart';

class _FakeDoc extends YustDoc {
  _FakeDoc({required String id}) {
    this.id = id;
  }

  @override
  Map<String, dynamic> toJson() => {'id': id};

  YustDoc fromJson(Map<String, dynamic> json) => _FakeDoc(id: json['id']);
}

void main() {
  final anchor = _FakeDoc(id: 'anchor');

  group('YustDatabaseService.getOrderBy — without startAfterDocument', () {
    test('returns caller orderBy unchanged (null stays null)', () {
      expect(
        YustDatabaseService.getOrderBy<YustDoc>(
          filters: null,
          orderBy: null,
          startAfterDocument: null,
        ),
        isNull,
      );
    });

    test('returns caller orderBy unchanged (explicit list preserved)', () {
      final orderBy = [YustOrderBy(field: 'createdAt', descending: true)];
      final result = YustDatabaseService.getOrderBy<YustDoc>(
        filters: [
          YustFilter(
            field: 'modifiedAt',
            comparator: YustFilterComparator.greaterThanEqual,
            value: 'x',
          ),
        ],
        orderBy: orderBy,
        startAfterDocument: null,
      );
      expect(result, same(orderBy));
    });
  });

  group('YustDatabaseService.getOrderBy — with startAfterDocument', () {
    test('null orderBy + no inequality filter → [__name__]', () {
      final result = YustDatabaseService.getOrderBy(
        filters: null,
        orderBy: null,
        startAfterDocument: anchor,
      );

      expect(result, isNotNull);
      expect(result!.map((o) => o.field), ['__name__']);
    });

    test('null orderBy + only equality filter → [__name__]', () {
      final result = YustDatabaseService.getOrderBy(
        filters: [
          YustFilter(
            field: 'status',
            comparator: YustFilterComparator.equal,
            value: 'open',
          ),
        ],
        orderBy: null,
        startAfterDocument: anchor,
      );

      expect(result!.map((o) => o.field), ['__name__']);
    });

    test('null orderBy + inequality filter → [<field>, __name__]', () {
      final result = YustDatabaseService.getOrderBy(
        filters: [
          YustFilter(
            field: 'modifiedAt',
            comparator: YustFilterComparator.greaterThanEqual,
            value: '2025-07-01T00:00:00Z',
          ),
        ],
        orderBy: null,
        startAfterDocument: anchor,
      );

      expect(result!.map((o) => o.field), ['modifiedAt', '__name__']);
      expect(result.first.descending, isFalse);
    });

    test('null orderBy + range on same field (>= and <=) → '
        'single field + __name__', () {
      final result = YustDatabaseService.getOrderBy(
        filters: [
          YustFilter(
            field: 'modifiedAt',
            comparator: YustFilterComparator.greaterThanEqual,
            value: 'a',
          ),
          YustFilter(
            field: 'modifiedAt',
            comparator: YustFilterComparator.lessThanEqual,
            value: 'b',
          ),
        ],
        orderBy: null,
        startAfterDocument: anchor,
      );

      expect(result!.map((o) => o.field), ['modifiedAt', '__name__']);
    });

    test('explicit orderBy + no filter → orderBy + __name__ tiebreaker', () {
      final result = YustDatabaseService.getOrderBy(
        filters: null,
        orderBy: [YustOrderBy(field: 'createdAt', descending: true)],
        startAfterDocument: anchor,
      );

      expect(result!.map((o) => o.field), ['createdAt', '__name__']);
      expect(result.first.descending, isTrue);
    });

    test('explicit orderBy already contains __name__ → not appended twice', () {
      final result = YustDatabaseService.getOrderBy(
        filters: null,
        orderBy: [
          YustOrderBy(field: 'createdAt'),
          YustOrderBy(field: '__name__'),
        ],
        startAfterDocument: anchor,
      );

      expect(result!.map((o) => o.field), ['createdAt', '__name__']);
    });

    test('explicit orderBy present with inequality filter → keep caller '
        'order, append __name__', () {
      // Caller-supplied orderBy takes precedence; we do not add the
      // inequality field because Firestore requires the caller to have
      // already put it first (this is validated elsewhere).
      final result = YustDatabaseService.getOrderBy(
        filters: [
          YustFilter(
            field: 'modifiedAt',
            comparator: YustFilterComparator.greaterThanEqual,
            value: 'a',
          ),
        ],
        orderBy: [YustOrderBy(field: 'modifiedAt')],
        startAfterDocument: anchor,
      );

      expect(result!.map((o) => o.field), ['modifiedAt', '__name__']);
    });
  });
}
