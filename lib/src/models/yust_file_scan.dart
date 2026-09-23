import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import 'yust_json_date.dart';

part 'yust_file_scan.g.dart';

/// What is known about a file's virus scan.
///
/// Written by the backend scan trigger. The client only ever writes
/// [YustFileScanStatus.pending], and only when creating the map entry.
///
/// A file with **no** [YustFileScan] is a different thing from a clean one, and
/// must never render as safe — use [YustFile.isScannedClean].
@JsonSerializable(createFactory: false)
class YustFileScan {
  YustFileScan({
    required this.status,
    this.signature,
    this.reason,
    this.scannedAt,
  });

  factory YustFileScan.fromJson(Map<String, dynamic> json) => YustFileScan(
    status: YustFileScanStatus.fromJson(json['status'] as String?),
    signature: json['signature'] as String?,
    reason: YustFileScanReason.fromJson(json['reason'] as String?),
    scannedAt: dateTimeFromJson(json['scannedAt']),
  );

  /// A file that has been queued for scanning but has no verdict yet.
  factory YustFileScan.pending() =>
      YustFileScan(status: YustFileScanStatus.pending);

  /// What we know about the file. The only status that may render as safe is
  /// [YustFileScanStatus.clean].
  YustFileScanStatus status;

  /// The engine's signature name, e.g. `Win.Trojan.Agent-1774751`.
  ///
  /// Set only when [status] is [YustFileScanStatus.infected], and only for real
  /// detections — "could not open this" maps onto [reason] instead, so this
  /// always means malware was identified. Never translated.
  String? signature;

  /// Why there is no verdict. Set only when [status] is
  /// [YustFileScanStatus.skipped].
  ///
  /// Translated for display — the user sees "too large to scan", not a code.
  YustFileScanReason? reason;

  /// When the verdict was written. Null while pending.
  DateTime? scannedAt;

  Map<String, dynamic> toJson() => _$YustFileScanToJson(this);
}

/// The terminal states of a scan, plus [pending].
enum YustFileScanStatus {
  /// Queued, no verdict yet.
  ///
  /// The client writes this when creating the entry, because the backend can
  /// only annotate an entry that already exists. Never on *update* — that
  /// would let a stale client push a real verdict back to "scanning…".
  pending,

  /// An engine examined the file and found nothing.
  clean,

  /// An engine identified malware. See [YustFileScan.signature].
  infected,

  /// Not scannable, for a reason that will not change. Never retried.
  skipped,

  /// Scanning failed after retries were exhausted. A re-scan tool SHOULD retry
  /// these; it must not retry [skipped].
  error;

  /// Converts a JSON string to a [YustFileScanStatus].
  ///
  /// An unknown or missing value becomes [error] rather than anything
  /// reassuring: a value this version of the client cannot interpret is not a
  /// value it may treat as safe.
  static YustFileScanStatus fromJson(String? status) =>
      YustFileScanStatus.values.firstWhereOrNull((e) => e.name == status) ??
      YustFileScanStatus.error;

  /// Converts a [YustFileScanStatus] to a JSON string.
  String toJson() => name;
}

/// Why a file has no verdict. Only set when the status is
/// [YustFileScanStatus.skipped].
///
/// Values are persisted — do not rename.
enum YustFileScanReason {
  /// Above the scan size cap, which is `YustFile.maxSizeInBytes`. Should be
  /// unreachable in practice: if it fires, an upload path bypassed yust's own
  /// limit and that is the thing to fix.
  tooLarge,

  /// Password-protected archive or document. The engine can see it but not
  /// open it.
  encrypted,

  /// The engine hit its own limits and stopped expanding the file. Part of it
  /// was never examined, so this is NOT clean.
  limitsExceeded;

  /// Converts a JSON string to a [YustFileScanReason], or null when absent or
  /// unrecognised.
  static YustFileScanReason? fromJson(String? reason) =>
      YustFileScanReason.values.firstWhereOrNull((e) => e.name == reason);

  /// Converts a [YustFileScanReason] to a JSON string.
  String toJson() => name;
}
