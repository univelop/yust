import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:googleapis/storage/v1.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import '../util/yust_storage_api.dart';

class YustFileService {
  final StorageApi _storageApi;

  YustFileService({String? emulatorAddress})
      : _storageApi = YustStorageApi.instance!;

  Future<String> uploadFile(
      {required String path,
      required String name,
      File? file,
      Uint8List? bytes}) async {
    // Check if either a file or bytes are provided
    if (file == null && bytes == null) {
      throw Exception('No file or bytes provided');
    }

    // Prefer file over bytes if both are provided
    final data = file != null
        ? file.openRead()
        : Stream<List<int>>.value(bytes!.toList());
    final token = Uuid().v4();
    final object = Object(
        name: '$path/$name',
        bucket: YustStorageApi.bucketName,
        metadata: {'firebaseStorageDownloadTokens': token});
    final media = Media(data, file?.lengthSync() ?? bytes!.length,
        contentType: lookupMimeType(name) ?? 'application/octet-stream');

    // Using the Google Storage API to insert (upload) the file
    await _storageApi.objects
        .insert(object, YustStorageApi.bucketName!, uploadMedia: media);
    return _createDownloadUrl(path, name, token);
  }

  Future<Uint8List?> downloadFile(
      {required String path,
      required String name,
      int maxSize = 20 * 1024 * 1024}) async {
    final object = await _storageApi.objects.get(
        YustStorageApi.bucketName!, '$path/$name',
        downloadOptions: DownloadOptions.fullMedia);

    if (object is Media) {
      final mediaStream = object.stream;

      final completer = Completer<Uint8List>();
      final bytesBuilder = BytesBuilder(copy: false);
      int totalBytes = 0;

      StreamSubscription<List<int>>? subscription;
      subscription = mediaStream.listen((List<int> data) {
        if (totalBytes + data.length > maxSize) {
          final leftOverBytes = maxSize - totalBytes;
          bytesBuilder.add(data.sublist(0, leftOverBytes));
          completer.complete(bytesBuilder.takeBytes());
          subscription?.cancel();
        } else {
          bytesBuilder.add(data);
          totalBytes += data.length;
        }
      }, onDone: () {
        if (!completer.isCompleted) {
          completer.complete(bytesBuilder.takeBytes());
        }
      }, onError: completer.completeError);

      return completer.future;
    }
    throw Exception('Unknown response Object');
  }

  Future<void> deleteFile({required String path, String? name}) async {
    await _storageApi.objects.delete(YustStorageApi.bucketName!, '$path/$name');
  }

  Future<bool> fileExist({required String path, required String name}) async {
    try {
      await _storageApi.objects.get(YustStorageApi.bucketName!, '$path/$name');
      return true;
    } on DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        return false;
      }
      rethrow;
    }
  }

  Future<String> getFileDownloadUrl(
      {required String path, required String name}) async {
    final object = await _storageApi.objects
        .get(YustStorageApi.bucketName!, '$path/$name');
    if (object is Object) {
      final token =
          object.metadata?['firebaseStorageDownloadTokens']?.split(',')[0];
      if (token == null) {
        throw Exception('No token found');
      }
      return _createDownloadUrl(path, name, token);
    }
    throw Exception('Unknown response Object');
  }

  String _createDownloadUrl(String path, String name, String token) {
    return 'https://firebasestorage.googleapis.com/v0/b/'
        '${YustStorageApi.bucketName}/o/${Uri.encodeComponent('$path/$name')}'
        '?alt=media&token=$token';
  }
}
