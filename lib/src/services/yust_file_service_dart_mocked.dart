import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import 'yust_file_service.dart';

const firebaseStorageUrl = 'https://storage.googleapis.com/';

/// Mocked Filestorage service.
class YustFileServiceMocked extends YustFileService {
  // In-memory storage for the files.
  final Map<String, Map<String, MockedFile>> _storage = {};

  YustFileServiceMocked({
    required super.emulatorAddress,
    required super.projectId,
  }) : super.mocked();

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

  String _createDownloadUrl(String path, String name, String token) {
    return '${rootUrl}v0/b/'
        '$bucketName/o/${Uri.encodeComponent('$path/$name')}'
        '?alt=media&token=$token';
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
