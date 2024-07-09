import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:googleapis/storage/v1.dart';
import 'package:http/http.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

const firebaseStorageUrl = 'https://storage.googleapis.com/';

/// Handels Filestorage requests for Google Cloud Storage.
///
/// Uses the GoogleApi for Flutter Platforms (Android, iOS, Web)
/// and GoogleAPIs for **Dart-only environments**.
class YustFileService {
  late StorageApi _storageApi;
  late String bucketName;
  late String rootUrl;

  YustFileService({
    Client? authClient,
    required String? emulatorAddress,
    required String projectId,
  }) {
    bucketName = '$projectId.appspot.com';
    rootUrl = emulatorAddress != null
        ? 'http://$emulatorAddress:9199/'
        : firebaseStorageUrl;
    _storageApi = StorageApi(authClient!, rootUrl: rootUrl);
  }

  YustFileService.mocked() {
    bucketName = 'bucket_name_placeholder';
    rootUrl = '0.0.0.0:80';
  }

  /// Uploads a file from either a [File] or [Uint8List]
  /// to the given [path] and [name].
  ///
  /// It returns the download url of the uploaded file.
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
        bucket: bucketName,
        metadata: {'firebaseStorageDownloadTokens': token});
    final media = Media(data, file?.lengthSync() ?? bytes!.length,
        contentType: lookupMimeType(name) ?? 'application/octet-stream');

    // Using the Google Storage API to insert (upload) the file
    await _storageApi.objects.insert(object, bucketName, uploadMedia: media);
    return _createDownloadUrl(path, name, token);
  }

  /// Downloads a file from a given [path] and [name] and returns it as [Uint8List].
  /// The [maxSize] parameter can be used to limit the size of the downloaded file.
  Future<Uint8List?> downloadFile(
      {required String path,
      required String name,
      int maxSize = 20 * 1024 * 1024}) async {
    print('[[DEBUG]] Downloading File from $path/$name');
    final object = await _storageApi.objects.get(bucketName, '$path/$name',
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
          print(
              '[[DEBUG]] Completed download of File from $path/$name with ${bytesBuilder.length} bytes');
          subscription?.cancel();
        } else {
          bytesBuilder.add(data);
          totalBytes += data.length;
        }
      }, onDone: () {
        if (!completer.isCompleted) {
          print(
              '[[DEBUG]] Completed download of File from $path/$name with ${bytesBuilder.length} bytes');
          completer.complete(bytesBuilder.takeBytes());
        }
      }, onError: completer.completeError);

      return completer.future;
    }
    throw Exception('Unknown response Object');
  }

  /// Deletes a existing file at [path] and filename [name].
  Future<void> deleteFile({required String path, String? name}) async {
    await _storageApi.objects.delete(bucketName, '$path/$name');
  }

  Future<void> deleteFolder({required String path}) async {
    final objects = await _storageApi.objects.list(bucketName, prefix: path);

    if (objects.items != null) {
      for (final object in objects.items!) {
        await _storageApi.objects.delete(bucketName, object.name!);
      }
    }
  }

  /// Checks if a file exists at a given [path] and [name].
  Future<bool> fileExist({required String path, required String name}) async {
    try {
      await _storageApi.objects.get(bucketName, '$path/$name');
      return true;
    } on DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        return false;
      }
      rethrow;
    }
  }

  /// Returns the download url of a existing file at [path] and [name].
  Future<String> getFileDownloadUrl(
      {required String path, required String name}) async {
    final object = await _storageApi.objects.get(bucketName, '$path/$name');
    if (object is Object) {
      var token =
          object.metadata?['firebaseStorageDownloadTokens']?.split(',')[0];
      if (token == null) {
        token = Uuid().v4();
        if (object.metadata == null) {
          object.metadata = {'firebaseStorageDownloadTokens': token};
        } else {
          object.metadata!['firebaseStorageDownloadTokens'] = token;
        }
        try {
          await _storageApi.objects.update(object, bucketName, object.name!);
        } catch (e) {
          throw Exception('Error while creating token: ${e.toString()}}');
        }
      }
      return _createDownloadUrl(path, name, token);
    }
    throw Exception('Unknown response Object');
  }

  String _createDownloadUrl(String path, String name, String token) {
    return 'https://firebasestorage.googleapis.com/v0/b/'
        '$bucketName/o/${Uri.encodeComponent('$path/$name')}'
        '?alt=media&token=$token';
  }

  Future<List<Object>> getFilesInFolder({required String path}) async {
    return (await _storageApi.objects.list(bucketName, prefix: path)).items ??
        [];
  }

  Future<List<Object>> getFileVersionsInFolder({required String path}) async {
    return (await _storageApi.objects
                .list(bucketName, prefix: path, versions: true))
            .items ??
        [];
  }

  Future<Map<String?, List<Object>>> getFileVersionsGrouped(
      {required String path}) async {
    final objects = groupBy((await getFileVersionsInFolder(path: path)),
        (Object object) => object.name);
    return objects;
  }

  Future<String?> getLatestFileVersion(
      {required String path, required String name}) async {
    final fileVersions = (await getFileVersionsInFolder(path: path))
        .where((e) => e.name == '$path/$name');
    // Get the generation of the file that has been deleted last
    return fileVersions
        .where((e) => e.timeCreated != null)
        .sortedBy<DateTime>((element) => element.timeCreated!)
        .lastOrNull
        ?.generation;
  }

  Future<String?> getLatestInvalidFileVersion({
    required String path,
    required String name,
    DateTime? beforeDeletion,
    DateTime? afterDeletion,
  }) async {
    final fileVersions = (await getFileVersionsInFolder(path: path))
        .where((e) => e.name == '$path/$name');
    // Get the generation of the file that has been deleted last
    return fileVersions
        .where((e) => e.timeCreated != null && e.timeDeleted != null)
        .where((e) => beforeDeletion != null
            ? e.timeDeleted?.isAfter(beforeDeletion) ?? false
            : true)
        .where((e) => afterDeletion != null
            ? e.timeDeleted?.isBefore(afterDeletion) ?? false
            : true)
        .sortedBy<DateTime>((element) => element.timeDeleted!)
        .lastOrNull
        ?.generation;
  }

  Future<void> recoverOutdatedFile(
      {required String path,
      required String name,
      required String generation}) async {
    final object = await _storageApi.objects
        .get(bucketName, '$path/$name', generation: generation);
    if (object is Object) {
      await _storageApi.objects.rewrite(
          object, bucketName, object.name!, bucketName, object.name!,
          sourceGeneration: generation);
    }
  }
}
