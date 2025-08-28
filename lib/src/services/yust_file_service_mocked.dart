import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import '../util/yust_exception.dart';
import 'yust_file_service.dart';
import 'yust_file_service_shared.dart';

const firebaseStorageUrl = 'https://storage.googleapis.com/';

/// Represents a collection of files in a folder (filename -> MockedFile)
typedef MockedFolder = Map<String, MockedFile>;

/// Represents all folders in a bucket (path -> MockedFolder)
typedef MockedBucket = Map<String, MockedFolder>;

/// Represents all buckets in storage (bucketName -> MockedBucket)
typedef MockedStorage = Map<String, MockedBucket>;

/// Mocked Filestorage service.
class YustFileServiceMocked extends YustFileService {
  /// In-memory storage for the files, organized by bucket -> path -> filename -> file
  static final MockedStorage _storage = {};

  YustFileServiceMocked() : super.mocked() {
    defaultBucketName = 'mocked-bucket';
  }

  /// Gets the storage for a specific bucket, creating it if needed
  MockedBucket _getStorageForBucket(String? bucketName) {
    final effectiveBucketName = bucketName ?? defaultBucketName;
    _storage.putIfAbsent(effectiveBucketName, () => <String, MockedFolder>{});
    return _storage[effectiveBucketName]!;
  }

  @override
  Future<String> uploadStream({
    required String path,
    required String name,
    required Stream<List<int>> stream,
    String? contentDisposition,
    Map<String, String>? metadata,
    String? bucketName,
  }) async {
    final collected = <int>[];
    await for (final chunk in stream) {
      collected.addAll(chunk);
    }
    final bytes = Uint8List.fromList(collected);

    return uploadFile(
      path: path,
      name: name,
      bytes: bytes,
      metadata: metadata,
      bucketName: bucketName,
    );
  }

  /// Uploads a file from either a [File] or [Uint8List]
  /// to the given [path] and [name].
  ///
  /// It returns the download url of the uploaded file.
  @override
  Future<String> uploadFile({
    required String path,
    required String name,
    File? file,
    Uint8List? bytes,
    Map<String, String>? metadata,
    String? bucketName,
  }) async {
    if (file == null && bytes == null) {
      throw Exception('No file or bytes provided');
    }

    final data = file != null ? await file.readAsBytes() : bytes!;
    final token = Uuid().v4();

    final bucketStorage = _getStorageForBucket(bucketName);
    bucketStorage.putIfAbsent(path, () => <String, MockedFile>{});

    final fileMetadata = <String, String>{
      ...?metadata,
      'firebaseStorageDownloadTokens': token,
    };

    bucketStorage[path]![name] = MockedFile(
      data: data,
      metadata: fileMetadata,
      mimeType: lookupMimeType(name) ?? 'application/octet-stream',
    );

    return _createDownloadUrl(
      path,
      name,
      token,
      bucketName ?? defaultBucketName,
    );
  }

  /// Downloads a file from a given [path] and [name] and returns it as [Uint8List].
  /// The [maxSize] parameter can be used to limit the size of the downloaded file.
  @override
  Future<Uint8List?> downloadFile({
    required String path,
    required String name,
    int maxSize = 20 * 1024 * 1024,
    String? bucketName,
  }) async {
    final bucketStorage = _getStorageForBucket(bucketName);
    final file = bucketStorage[path]?[name];
    if (file == null) {
      throw Exception('File not found');
    }

    if (file.data.length > maxSize) {
      return file.data.sublist(0, maxSize);
    }
    return file.data;
  }

  /// Deletes an existing file at [path] and filename [name].
  @override
  Future<void> deleteFile({
    required String path,
    String? name,
    String? bucketName,
  }) async {
    final bucketStorage = _getStorageForBucket(bucketName);
    bucketStorage[path]?.remove(name);
  }

  /// Deletes all files in the specified folder [path].
  @override
  Future<void> deleteFolder({required String path, String? bucketName}) async {
    final bucketStorage = _getStorageForBucket(bucketName);
    bucketStorage.remove(path);
  }

  /// Checks if a file exists at a given [path] and [name].
  @override
  Future<bool> fileExist({
    required String path,
    required String name,
    String? bucketName,
  }) async {
    final bucketStorage = _getStorageForBucket(bucketName);
    return bucketStorage[path]?.containsKey(name) ?? false;
  }

  /// Returns the download url of an existing file at [path] and [name].
  @override
  Future<String> getFileDownloadUrl({
    required String path,
    required String name,
    String? bucketName,
  }) async {
    final bucketStorage = _getStorageForBucket(bucketName);
    final file = bucketStorage[path]?[name];
    if (file == null) {
      throw Exception('File not found');
    }

    var token = file.metadata['firebaseStorageDownloadTokens'];
    if (token == null) {
      token = Uuid().v4();
      file.metadata['firebaseStorageDownloadTokens'] = token;
    }

    return _createDownloadUrl(
      path,
      name,
      token,
      bucketName ?? defaultBucketName,
    );
  }

  @override
  Future<YustFileMetadata> getMetadata({
    required String path,
    required String name,
    String? bucketName,
  }) async {
    final bucketStorage = _getStorageForBucket(bucketName);
    final object = bucketStorage[path]?[name];

    return YustFileMetadata(
      size: object?.data.length ?? 0,
      token: object?.metadata['firebaseStorageDownloadTokens'] ?? '',
    );
  }

  @override
  Future<List<dynamic>> getFilesInFolder({
    required String path,
    String? bucketName,
  }) async {
    throw YustException('Not implemented for mocked');
  }

  @override
  Future<Map<String?, List<dynamic>>> getFileVersionsGrouped({
    required String path,
    String? bucketName,
  }) async {
    throw YustException('Not implemented for mocked');
  }

  @override
  Future<String?> getLatestFileVersion({
    required String path,
    required String name,
    String? bucketName,
  }) async {
    throw YustException('Not implemented for mocked');
  }

  @override
  Future<String?> getLatestInvalidFileVersion({
    required String path,
    required String name,
    DateTime? beforeDeletion,
    DateTime? afterDeletion,
    String? bucketName,
  }) async {
    throw YustException('Not implemented for mocked');
  }

  @override
  Future<void> recoverOutdatedFile({
    required String path,
    required String name,
    required String generation,
    String? bucketName,
  }) async {
    throw YustException('Not implemented for mocked');
  }

  String _createDownloadUrl(
    String path,
    String name,
    String token,
    String bucketName,
  ) {
    return 'https://not-a-real-url.mocked/$bucketName/$path/$name&token=$token';
  }
}

class MockedFile {
  final Uint8List data;
  final Map<String, String> metadata;
  final String mimeType;

  MockedFile({
    required this.data,
    required this.metadata,
    required this.mimeType,
  });
}
