import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import '../util/yust_exception.dart';
import 'yust_file_service.dart';
import 'yust_file_service_shared.dart';

const firebaseStorageUrl = 'https://storage.googleapis.com/';

/// Mocked Filestorage service.
class YustFileServiceMocked extends YustFileService {
  // In-memory storage for the files.
  static final Map<String, Map<String, MockedFile>> _storage = {};

  YustFileServiceMocked() : super.mocked();

  @override
  Future<String> uploadStream({
    required String path,
    required String name,
    required Stream<List<int>> stream,
    String? contentDisposition,
  }) async {
    final collected = <int>[];
    await for (final chunk in stream) {
      collected.addAll(chunk);
    }
    final bytes = Uint8List.fromList(collected);

    return uploadFile(path: path, name: name, bytes: bytes);
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
  }) async {
    if (file == null && bytes == null) {
      throw Exception('No file or bytes provided');
    }

    final data = file != null ? await file.readAsBytes() : bytes!;
    final token = Uuid().v4();

    _storage.putIfAbsent(path, () => {});

    _storage[path]![name] = MockedFile(
      data: data,
      metadata: {'firebaseStorageDownloadTokens': token},
      mimeType: lookupMimeType(name) ?? 'application/octet-stream',
    );

    return _createDownloadUrl(path, name, token);
  }

  /// Downloads a file from a given [path] and [name] and returns it as [Uint8List].
  /// The [maxSize] parameter can be used to limit the size of the downloaded file.
  @override
  Future<Uint8List?> downloadFile({
    required String path,
    required String name,
    int maxSize = 20 * 1024 * 1024,
  }) async {
    final file = _storage[path]?[name];
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
  Future<void> deleteFile({required String path, String? name}) async {
    _storage[path]?.remove(name);
  }

  /// Deletes all files in the specified folder [path].
  @override
  Future<void> deleteFolder({required String path}) async {
    _storage.remove(path);
  }

  /// Checks if a file exists at a given [path] and [name].
  @override
  Future<bool> fileExist({required String path, required String name}) async {
    return _storage[path]?.containsKey(name) ?? false;
  }

  /// Returns the download url of an existing file at [path] and [name].
  @override
  Future<String> getFileDownloadUrl({
    required String path,
    required String name,
  }) async {
    final file = _storage[path]?[name];
    if (file == null) {
      throw Exception('File not found');
    }

    var token = file.metadata['firebaseStorageDownloadTokens'];
    if (token == null) {
      token = Uuid().v4();
      file.metadata['firebaseStorageDownloadTokens'] = token;
    }

    return _createDownloadUrl(path, name, token);
  }

  @override
  Future<YustFileMetadata> getMetadata({
    required String path,
    required String name,
  }) async {
    final object = _storage[path]?[name];

    return YustFileMetadata(
      size: object?.data.length ?? 0,
      token: object?.metadata['firebaseStorageDownloadTokens'] ?? '',
    );
  }

  @override
  Future<List<dynamic>> getFilesInFolder({required String path}) async {
    throw YustException('Not implemented for mocked');
  }

  @override
  Future<List<dynamic>> getFileVersionsInFolder({required String path}) async {
    throw YustException('Not implemented for mocked');
  }

  @override
  Future<Map<String?, List<dynamic>>> getFileVersionsGrouped({
    required String path,
  }) async {
    throw YustException('Not implemented for mocked');
  }

  @override
  Future<String?> getLatestFileVersion({
    required String path,
    required String name,
  }) async {
    throw YustException('Not implemented for mocked');
  }

  @override
  Future<String?> getLatestInvalidFileVersion({
    required String path,
    required String name,
    DateTime? beforeDeletion,
    DateTime? afterDeletion,
  }) async {
    throw YustException('Not implemented for mocked');
  }

  @override
  Future<void> recoverOutdatedFile({
    required String path,
    required String name,
    required String generation,
  }) async {
    throw YustException('Not implemented for mocked');
  }

  String _createDownloadUrl(String path, String name, String token) {
    return 'https://not-a-real-url.mocked/$path/$name&token=$token';
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
