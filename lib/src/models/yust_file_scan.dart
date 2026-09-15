import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'yust_file_scan.g.dart';

/// What is known about a file's virus scan.
///
/// The absence of a [YustFileScan] and a [YustFileScan] are different things:
/// a file with no scan predates the feature, or its workspace has not enabled
/// scanning. **Neither may ever render as safe.**
///
/// Written by the backend scan trigger. The client only ever writes
/// [YustFileScanStatus.pending], and only when creating the map entry — see
/// [YustFileScanStatus.pending] for why.
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
    scannedAt: json['scannedAt'] == null
        ? null
        : json['scannedAt'] is DateTime
        ? json['scannedAt'] as DateTime
        : DateTime.tryParse(json['scannedAt'] as String),
  );

  /// A file that has been queued for scanning but has no verdict yet.
  factory YustFileScan.pending() =>
      YustFileScan(status: YustFileScanStatus.pending);

  /// What we know about the file. The only status that may render as safe is
  /// [YustFileScanStatus.clean].
  YustFileScanStatus status;

  /// The ClamAV signature name, e.g. `Win.Trojan.Agent-1774751`.
  ///
  /// Set only when [status] is [YustFileScanStatus.infected], and only for real
  /// detections — the scanner maps its engine's "could not open this"
  /// pseudo-signatures onto [reason] instead, so this field always means
  /// "malware was identified". Shown verbatim in admin and support views;
  /// never translated.
  String? signature;

  /// Why there is no verdict. Set only when [status] is
  /// [YustFileScanStatus.skipped].
  ///
  /// Translated for display — the user sees "too large to scan", not a code.
  YustFileScanReason? reason;

  /// When the verdict was written. Null while pending.
  DateTime? scannedAt;

  /// True only for a file an engine actually examined and found clean.
  ///
  /// Every other state — including no scan at all, which is why this lives
  /// here and there is a `YustFile.isScannedClean` beside it — is not safe.
  @JsonKey(includeToJson: false)
  bool get isClean => status == YustFileScanStatus.clean;

  /// True when the file is known to contain malware.
  @JsonKey(includeToJson: false)
  bool get isInfected => status == YustFileScanStatus.infected;

  /// True while a verdict is still expected. Distinct from having none.
  @JsonKey(includeToJson: false)
  bool get isPending => status == YustFileScanStatus.pending;

  Map<String, dynamic> toJson() => _$YustFileScanToJson(this);

  @override
  bool operator ==(Object other) =>
      other is YustFileScan &&
      other.status == status &&
      other.signature == signature &&
      other.reason == reason &&
      other.scannedAt == scannedAt;

  @JsonKey(includeToJson: false)
  @override
  int get hashCode => Object.hash(status, signature, reason, scannedAt);
}

/// The terminal states of a scan, plus [pending].
enum YustFileScanStatus {
  /// Queued, no verdict yet.
  ///
  /// Written by the client when the file entry is created, and replaced by the
  /// backend. That ordering is forced rather than chosen: the trigger
  /// annotates an existing map entry and cannot write a verdict before the
  /// entry exists. Writing `pending` on *update* would let a stale client push
  /// a real verdict back to "scanning…", which is the one way this field can
  /// do harm.
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
