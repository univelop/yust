import 'dart:io';
import 'dart:typed_data';

import 'yust_file_service_shared.dart';

/// Handles file storage requests.
///
/// Using Firebase Storage for Flutter Platforms (Android, iOS, Web) and Google Cloud Storage for Dart-only environments.
abstract interface class IYustFileService {
  /// Uploads a file from either a [File] or [Uint8List]
  /// to the given [path] and [name].
  ///
  /// Optionally accepts [metadata] to be set on the uploaded file.
  /// Optionally accepts [bucketName] to override the default bucket.
  ///
  /// It returns the download url of the uploaded file.
  Future<String> uploadFile({
    required String path,
    required String name,
    File? file,
    Uint8List? bytes,
    Map<String, String>? metadata,
    String? bucketName,
  });

  /// Uploads a file from a [Stream] of [List<int>]
  /// to the given [path] and [name].
  ///
  /// Optionally accepts [metadata] to be set on the uploaded file.
  /// Optionally accepts [bucketName] to override the default bucket.
  ///
  /// Returns the download url of the uploaded file.
  Future<String> uploadStream({
    required String path,
    required String name,
    required Stream<List<int>> stream,
    String? contentDisposition,
    Map<String, String>? metadata,
    String? bucketName,
  });

  /// Downloads a file from a given [path] and [name] and returns it as [Uint8List].
  /// The [maxSize] parameter can be used to limit the size of the downloaded file.
  /// Optionally accepts [bucketName] to override the default bucket.
  Future<Uint8List?> downloadFile({
    required String path,
    required String name,
    int maxSize = 20 * 1024 * 1024,
    String? bucketName,
  });

  /// Deletes a existing file at [path] and filename [name].
  /// Optionally accepts [bucketName] to override the default bucket.
  Future<void> deleteFile({
    required String path,
    String? name,
    String? bucketName,
  });

  /// Deletes all files in a folder at the given [path].
  /// Optionally accepts [bucketName] to override the default bucket.
  Future<void> deleteFolder({required String path, String? bucketName});

  /// Checks if a file exists at a given [path] and [name].
  /// Optionally accepts [bucketName] to override the default bucket.
  Future<bool> fileExist({
    required String path,
    required String name,
    String? bucketName,
  });

  /// Returns the download url of a existing file at [path] and [name].
  /// Optionally accepts [bucketName] to override the default bucket.
  Future<String> getFileDownloadUrl({
    required String path,
    required String name,
    String? bucketName,
  });

  /// Returns metadata for a file at the given [path] and [name].
  /// Optionally accepts [bucketName] to override the default bucket.
  Future<YustFileMetadata> getMetadata({
    required String path,
    required String name,
    String? bucketName,
  });

  /// Returns a list of files in a folder at the given [path].
  /// Optionally accepts [bucketName] to override the default bucket.
  Future<List<Object>> getFilesInFolder({
    required String path,
    String? bucketName,
  });

  /// Returns file versions grouped by file name for a folder at the given [path].
  /// Optionally accepts [bucketName] to override the default bucket.
  Future<Map<String?, List<Object>>> getFileVersionsGrouped({
    required String path,
    String? bucketName,
  });

  /// Returns the latest file version generation for a file at [path] and [name].
  /// Optionally accepts [bucketName] to override the default bucket.
  Future<String?> getLatestFileVersion({
    required String path,
    required String name,
    String? bucketName,
  });

  /// Returns the latest invalid (deleted) file version generation for a file at [path] and [name].
  /// Optionally accepts [bucketName] to override the default bucket.
  Future<String?> getLatestInvalidFileVersion({
    required String path,
    required String name,
    DateTime? beforeDeletion,
    DateTime? afterDeletion,
    String? bucketName,
  });

  /// Recovers an outdated file version with the given [generation].
  /// Optionally accepts [bucketName] to override the default bucket.
  Future<void> recoverOutdatedFile({
    required String path,
    required String name,
    required String generation,
    String? bucketName,
  });
}
