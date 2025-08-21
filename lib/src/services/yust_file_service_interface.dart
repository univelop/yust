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
  /// It returns the download url of the uploaded file.
  Future<String> uploadFile({
    required String path,
    required String name,
    File? file,
    Uint8List? bytes,
  });

  /// Uploads a file from a [Stream] of [List<int>]
  /// to the given [path] and [name].
  ///
  /// Returns the download url of the uploaded file.
  Future<String> uploadStream({
    required String path,
    required String name,
    required Stream<List<int>> stream,
    String? contentDisposition,
  });

  /// Downloads a file from a given [path] and [name] and returns it as [Uint8List].
  /// The [maxSize] parameter can be used to limit the size of the downloaded file.
  Future<Uint8List?> downloadFile({
    required String path,
    required String name,
    int maxSize = 20 * 1024 * 1024,
  });

  /// Deletes a existing file at [path] and filename [name].
  Future<void> deleteFile({required String path, String? name});

  /// Deletes all files in a folder at the given [path].
  Future<void> deleteFolder({required String path});

  /// Checks if a file exists at a given [path] and [name].
  Future<bool> fileExist({required String path, required String name});

  /// Returns the download url of a existing file at [path] and [name].
  Future<String> getFileDownloadUrl({
    required String path,
    required String name,
  });

  /// Returns metadata for a file at the given [path] and [name].
  Future<YustFileMetadata> getMetadata({
    required String path,
    required String name,
  });

  /// Returns a list of files in a folder at the given [path].
  Future<List<dynamic>> getFilesInFolder({required String path});

  /// Returns a list of file versions in a folder at the given [path].
  Future<List<dynamic>> getFileVersionsInFolder({required String path});

  /// Returns file versions grouped by file name for a folder at the given [path].
  Future<Map<String?, List<dynamic>>> getFileVersionsGrouped({
    required String path,
  });

  /// Returns the latest file version generation for a file at [path] and [name].
  Future<String?> getLatestFileVersion({
    required String path,
    required String name,
  });

  /// Returns the latest invalid (deleted) file version generation for a file at [path] and [name].
  Future<String?> getLatestInvalidFileVersion({
    required String path,
    required String name,
    DateTime? beforeDeletion,
    DateTime? afterDeletion,
  });

  /// Recovers an outdated file version with the given [generation].
  Future<void> recoverOutdatedFile({
    required String path,
    required String name,
    required String generation,
  });
}
