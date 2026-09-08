import '../util/yust_exception.dart';

/// The hard upper limit for a single file yust uploads or downloads.
///
/// Applies to every upload and download regardless of the caller. Callers may
/// enforce a stricter limit of their own, but never a larger one.
const yustMaxFileSizeInBytes = 500 * 1024 * 1024;

/// Throws a [YustFileTooLargeException] when [sizeInBytes] exceeds
/// [yustMaxFileSizeInBytes].
void validateYustUploadSize(String name, int sizeInBytes) {
  if (sizeInBytes > yustMaxFileSizeInBytes) {
    throw YustFileTooLargeException(
      'The file $name is $sizeInBytes bytes and exceeds the maximum upload '
      'size of $yustMaxFileSizeInBytes bytes.',
      sizeInBytes,
      yustMaxFileSizeInBytes,
    );
  }
}

class YustFileMetadata {
  int size;
  String token;
  Map<String, String>? customMetadata;

  YustFileMetadata({
    required this.size,
    required this.token,
    this.customMetadata,
  });
}
