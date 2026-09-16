import 'package:test/test.dart';
import 'package:yust/yust.dart';

void main() {
  group('YustFileScan', () {
    test('round-trips a clean verdict', () {
      final json = YustFileScan(
        status: YustFileScanStatus.clean,
        scannedAt: DateTime.utc(2026, 9, 11, 10),
      ).toJson();

      expect(json, {
        'status': 'clean',
        'signature': null,
        'reason': null,
        'scannedAt': '2026-09-11T10:00:00.000Z',
      });
      expect(YustFileScan.fromJson(json).status, YustFileScanStatus.clean);
    });

    test('round-trips an infected verdict with its signature', () {
      final scan = YustFileScan.fromJson(
        YustFileScan(
          status: YustFileScanStatus.infected,
          signature: 'Win.Trojan.Agent-1774751',
        ).toJson(),
      );

      expect(scan.status, YustFileScanStatus.infected);
      expect(scan.signature, 'Win.Trojan.Agent-1774751');
    });

    test('round-trips a skipped verdict with its reason', () {
      final scan = YustFileScan.fromJson(
        YustFileScan(
          status: YustFileScanStatus.skipped,
          reason: YustFileScanReason.encrypted,
        ).toJson(),
      );

      expect(scan.status, YustFileScanStatus.skipped);
      expect(scan.reason, YustFileScanReason.encrypted);
    });

    test('never persists the computed getters', () {
      // They would otherwise be written into every file map entry in the
      // database and read back as unknown keys.
      expect(YustFileScan.pending().toJson().keys, [
        'status',
        'signature',
        'reason',
        'scannedAt',
      ]);
    });

    test('reads an unknown status as error, never as something reassuring', () {
      // A value this client version cannot interpret is not a value it may
      // treat as safe.
      final scan = YustFileScan.fromJson({'status': 'quarantined'});

      expect(scan.status, YustFileScanStatus.error);
    });

    test('reads a missing status as error', () {
      expect(
        YustFileScan.fromJson(<String, dynamic>{}).status,
        YustFileScanStatus.error,
      );
    });

    test('ignores an unknown skip reason rather than inventing one', () {
      expect(
        YustFileScan.fromJson({
          'status': 'skipped',
          'reason': 'sunspots',
        }).reason,
        isNull,
      );
    });
  });

  group('YustFile scan integration', () {
    test('carries the verdict through fromJson and toJson', () {
      final file = YustFile.fromJson({
        'name': 'invoice.pdf',
        'hash': 'abc',
        'scan': {
          'status': 'infected',
          'signature': 'Eicar-Signature',
          'scannedAt': '2026-09-11T10:00:00.000Z',
        },
      });

      expect(file.scan?.status, YustFileScanStatus.infected);
      expect(file.isScannedClean, isFalse);
      expect((file.toJson()['scan'] as Map)['signature'], 'Eicar-Signature');
    });

    test('treats a file with no scan as not safe, not as safe', () {
      // The whole point of isScannedClean: `scan?.isClean != false` and its
      // relatives all quietly turn an absent verdict into a safe one.
      final file = YustFile.fromJson({'name': 'legacy.pdf', 'hash': 'abc'});

      expect(file.scan, isNull);
      expect(file.isScannedClean, isFalse);
    });

    test('omits scan from JSON when there is none', () {
      expect(YustFile(name: 'a.pdf').toJson()['scan'], isNull);
    });

    test('update() carries the verdict across', () {
      final target = YustFile(name: 'a.pdf', hash: 'h')
        ..update(
          YustFile(
            name: 'a.pdf',
            hash: 'h',
            scan: YustFileScan(status: YustFileScanStatus.clean),
          ),
        );

      expect(target.isScannedClean, isTrue);
    });
  });
}
