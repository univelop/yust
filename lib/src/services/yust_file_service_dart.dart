import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:googleapis/storage/v1.dart';
import 'package:http/http.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import '../../yust.dart';
import '../util/yust_retry_helper.dart';
import 'yust_file_service_interface.dart';
import 'yust_file_service_shared.dart';

const firebaseStorageUrl = 'https://storage.googleapis.com/';

/// Handles Filestorage requests for Google Cloud Storage.
///
/// Uses the GoogleApi for Flutter Platforms (Android, iOS, Web)
/// and GoogleAPIs for **Dart-only environments**.
class YustFileService implements IYustFileService {
  late StorageApi _storageApi;
  late String defaultBucketName;
  late String rootUrl;

  YustFileService({
    Client? authClient,
    required String? emulatorAddress,
    required String projectId,
  }) {
    defaultBucketName = '$projectId.appspot.com';
    rootUrl = emulatorAddress != null
        ? 'http://$emulatorAddress:9199/'
        : firebaseStorageUrl;
    _storageApi = StorageApi(authClient!, rootUrl: rootUrl);
  }

  YustFileService.mocked() {
    defaultBucketName = 'bucket_name_placeholder';
    rootUrl = '0.0.0.0:80';
  }

  @override
  Future<String> uploadFile({
    required String path,
    required String name,
    File? file,
    Uint8List? bytes,
    Map<String, String>? metadata,
    String? contentDisposition,
    String? bucketName,
  }) async {
    // Check if either a file or bytes are provided
    if (file == null && bytes == null) {
      throw YustException('No file or bytes provided');
    }

    final effectiveBucketName = bucketName ?? defaultBucketName;

    // Prefer file over bytes if both are provided
    final data = file != null
        ? file.openRead()
        : Stream<List<int>>.value(bytes!.toList());
    final token = Uuid().v4();
    final fileMetadata = <String, String>{
      ...?metadata,
      'firebaseStorageDownloadTokens': token,
    };

    final object = Object(
      name: '$path/$name',
      bucket: effectiveBucketName,
      metadata: fileMetadata,
      contentDisposition: contentDisposition ?? 'inline; filename="$name"',
    );
    final media = Media(
      data,
      file?.lengthSync() ?? bytes!.length,
      contentType: lookupMimeType(name) ?? 'application/octet-stream',
    );

    // Using the Google Storage API to insert (upload) the file
    await _retryOnException(
      'Upload-File',
      '$effectiveBucketName/$path/$name',
      () => _storageApi.objects.insert(
        object,
        effectiveBucketName,
        uploadMedia: media,
      ),
    );
    return _createDownloadUrl(path, name, token, effectiveBucketName);
  }

  /// Uploads a file from a [Stream] of [List<int>]
  /// to the given [path] and [name].
  ///
  /// Returns the download url of the uploaded file.
  @override
  Future<String> uploadStream({
    required String path,
    required String name,
    required Stream<List<int>> stream,
    String? contentDisposition,
    Map<String, String>? metadata,
    String? bucketName,
  }) async {
    final effectiveBucketName = bucketName ?? defaultBucketName;
    final token = Uuid().v4();
    final fileMetadata = <String, String>{
      ...?metadata,
      'firebaseStorageDownloadTokens': token,
    };

    final object = Object(
      name: '$path/$name',
      bucket: effectiveBucketName,
      metadata: fileMetadata,
      contentDisposition: contentDisposition ?? 'inline; filename="$name"',
    );
    final media = Media(
      stream,
      null,
      contentType: lookupMimeType(name) ?? 'application/octet-stream',
    );

    // Use the Google Storage API to insert (upload) the file
    await _retryOnException(
      'Upload-Stream',
      '$effectiveBucketName/$path/$name',
      () => _storageApi.objects.insert(
        object,
        effectiveBucketName,
        uploadMedia: media,
        uploadOptions: ResumableUploadOptions(chunkSize: 64 * 1024 * 1024),
      ),
    );
    return _createDownloadUrl(path, name, token, effectiveBucketName);
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
    final effectiveBucketName = bucketName ?? defaultBucketName;
    print('[[DEBUG]] Downloading File from $path/$name');

    final object = await _retryOnException(
      'Download-File',
      '$effectiveBucketName/$path/$name',
      () => _storageApi.objects.get(
        effectiveBucketName,
        '$effectiveBucketName/$path/$name',
        downloadOptions: DownloadOptions.fullMedia,
      ),
    );

    if (object is Media) {
      final mediaStream = object.stream;

      final completer = Completer<Uint8List>();
      final bytesBuilder = BytesBuilder(copy: false);
      int totalBytes = 0;

      StreamSubscription<List<int>>? subscription;
      subscription = mediaStream.listen(
        (List<int> data) {
          if (totalBytes + data.length > maxSize) {
            final leftOverBytes = maxSize - totalBytes;
            bytesBuilder.add(data.sublist(0, leftOverBytes));
            completer.complete(bytesBuilder.takeBytes());
            print(
              '[[DEBUG]] Completed download of File from $path/$name with ${bytesBuilder.length} bytes',
            );
            subscription?.cancel();
          } else {
            bytesBuilder.add(data);
            totalBytes += data.length;
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            print(
              '[[DEBUG]] Completed download of File from $path/$name with ${bytesBuilder.length} bytes',
            );
            completer.complete(bytesBuilder.takeBytes());
          }
        },
        onError: completer.completeError,
      );

      return completer.future;
    }
    throw YustException('Unknown response Object');
  }

  /// Deletes a existing file at [path] and filename [name].
  @override
  Future<void> deleteFile({
    required String path,
    String? name,
    String? bucketName,
  }) async {
    final effectiveBucketName = bucketName ?? defaultBucketName;
    await _retryOnException(
      'deleteFile',
      '$effectiveBucketName/$path/$name',
      () => _storageApi.objects.delete(effectiveBucketName, '$path/$name'),
      shouldIgnoreNotFound: true,
    );
  }

  @override
  Future<void> deleteFolder({required String path, String? bucketName}) async {
    final effectiveBucketName = bucketName ?? defaultBucketName;
    final objects = (await _retryOnException(
      'Get-Folder-Content-For-Deletion',
      '$effectiveBucketName/$path/',
      () => _storageApi.objects.list(effectiveBucketName, prefix: path),
    ))!;

    if (objects.items != null) {
      for (final object in objects.items!) {
        await _retryOnException(
          'Delete-File-of-Folder',
          '$path/${object.name!}',
          () => _storageApi.objects.delete(effectiveBucketName, object.name!),
          shouldIgnoreNotFound: true,
        );
      }
    }
  }

  /// Checks if a file exists at a given [path] and [name].
  @override
  Future<bool> fileExist({
    required String path,
    required String name,
    String? bucketName,
  }) async {
    final effectiveBucketName = bucketName ?? defaultBucketName;
    final obj = await _retryOnException(
      'Get-File',
      '$effectiveBucketName/$path/$name',
      () => _storageApi.objects.get(effectiveBucketName, '$path/$name'),
      shouldIgnoreNotFound: true,
    );
    return obj != null;
  }

  /// Returns the download url of a existing file at [path] and [name].
  @override
  Future<String> getFileDownloadUrl({
    required String path,
    required String name,
    String? bucketName,
  }) async {
    final effectiveBucketName = bucketName ?? defaultBucketName;

    final object = await _retryOnException(
      'Get-Storage-Obj-For-File-Url',
      '$effectiveBucketName/$path/$name',
      () => _storageApi.objects.get(effectiveBucketName, '$path/$name'),
    );

    if (object is! Object) {
      throw YustException('Unknown response Object');
    }

    var token = object.metadata?['firebaseStorageDownloadTokens']?.split(
      ',',
    )[0];
    if (token == null) {
      token = Uuid().v4();
      if (object.metadata == null) {
        object.metadata = {'firebaseStorageDownloadTokens': token};
      } else {
        object.metadata!['firebaseStorageDownloadTokens'] = token;
      }
      try {
        await _retryOnException(
          'Setting-Token-For-Download-Url',
          '$effectiveBucketName/$path/$name',
          () => _storageApi.objects.update(
            object,
            effectiveBucketName,
            object.name!,
          ),
        );
      } catch (e) {
        throw YustException('Error while creating token: ${e.toString()}}');
      }
    }

    return _createDownloadUrl(path, name, token, effectiveBucketName);
  }

  @override
  Future<YustFileMetadata> getMetadata({
    required String path,
    required String name,
    String? bucketName,
  }) async {
    final effectiveBucketName = bucketName ?? defaultBucketName;

    final Object object = await _retryOnException<dynamic>(
      'Get-Storage-Obj-For-File-Url',
      '$effectiveBucketName/$path/$name',
      () => _storageApi.objects.get(effectiveBucketName, '$path/$name'),
    );

    return YustFileMetadata(
      size: int.parse(object.size ?? '0'),
      token: object.metadata?['firebaseStorageDownloadTokens'] ?? '',
      customMetadata: object.metadata,
    );
  }

  String _createDownloadUrl(
    String path,
    String name,
    String token,
    String bucketName,
  ) {
    return 'https://firebasestorage.googleapis.com/v0/b/'
        '$bucketName/o/${Uri.encodeComponent('$path/$name')}'
        '?alt=media&token=$token';
  }

  @override
  Future<List<Object>> getFilesInFolder({
    required String path,
    String? bucketName,
  }) async {
    final effectiveBucketName = bucketName ?? defaultBucketName;
    return (await _retryOnException(
          'List-Files-Of-Folder',
          '$effectiveBucketName/$path/',
          () => _storageApi.objects.list(effectiveBucketName, prefix: path),
        ))?.items ??
        [];
  }

  Future<List<Object>> _getFileVersionsInFolder({
    required String path,
    String? bucketName,
  }) async {
    final effectiveBucketName = bucketName ?? defaultBucketName;
    return (await _retryOnException(
          'Get-File-Versions-In-Folder',
          '$effectiveBucketName/$path/',
          () => _storageApi.objects.list(
            effectiveBucketName,
            prefix: path,
            versions: true,
          ),
        ))?.items ??
        [];
  }

  @override
  Future<Map<String?, List<Object>>> getFileVersionsGrouped({
    required String path,
    String? bucketName,
  }) async {
    final effectiveBucketName = bucketName ?? defaultBucketName;
    final objects = groupBy(
      (await _retryOnException(
            'Get-File-Versions-Grouped',
            '$effectiveBucketName/$path/',
            () => _getFileVersionsInFolder(
              path: path,
              bucketName: effectiveBucketName,
            ),
          )) ??
          <Object>[],
      (Object object) => (object).name,
    );
    return objects;
  }

  @override
  Future<String?> getLatestFileVersion({
    required String path,
    required String name,
    String? bucketName,
  }) async {
    final fileVersions = (await _getFileVersionsInFolder(
      path: path,
      bucketName: bucketName,
    )).where((e) => (e).name == '$path/$name');
    // Get the generation of the file that has been deleted last
    final sortedVersions = fileVersions
        .where((e) => (e).timeCreated != null)
        .sortedBy<DateTime>((element) => (element).timeCreated!);
    return sortedVersions.isNotEmpty ? (sortedVersions.last).generation : null;
  }

  @override
  Future<String?> getLatestInvalidFileVersion({
    required String path,
    required String name,
    DateTime? beforeDeletion,
    DateTime? afterDeletion,
    String? bucketName,
  }) async {
    final fileVersions = (await _getFileVersionsInFolder(
      path: path,
      bucketName: bucketName,
    )).where((e) => (e).name == '$path/$name');
    // Get the generation of the file that has been deleted last
    final sortedVersions = fileVersions
        .where((e) => (e).timeCreated != null && e.timeDeleted != null)
        .where(
          (e) => beforeDeletion != null
              ? (e).timeDeleted?.isAfter(beforeDeletion) ?? false
              : true,
        )
        .where(
          (e) => afterDeletion != null
              ? (e).timeDeleted?.isBefore(afterDeletion) ?? false
              : true,
        )
        .sortedBy<DateTime>((element) => (element).timeDeleted!);
    return sortedVersions.isNotEmpty ? (sortedVersions.last).generation : null;
  }

  @override
  Future<void> recoverOutdatedFile({
    required String path,
    required String name,
    required String generation,
    String? bucketName,
  }) async {
    final effectiveBucketName = bucketName ?? defaultBucketName;
    final object = await _retryOnException(
      'Recover-Outdated-File-Get',
      '$effectiveBucketName/$path/$name',
      () => _storageApi.objects.get(
        effectiveBucketName,
        '$path/$name',
        generation: generation,
      ),
    );
    if (object is Object) {
      await _retryOnException(
        'Recover-Outdated-File-Rewrite',
        '$effectiveBucketName/$path/$name',
        () => _storageApi.objects.rewrite(
          object,
          effectiveBucketName,
          object.name!,
          effectiveBucketName,
          object.name!,
          sourceGeneration: generation,
        ),
      );
    }
  }

  @override
  Future<void> updateMetadata({
    required String path,
    required String name,
    required Map<String, String> metadata,
    String? bucketName,
  }) async {
    final effectiveBucketName = bucketName ?? defaultBucketName;

    // Get current object
    final object = await _retryOnException(
      'Get-Object-For-Metadata-Update',
      '$effectiveBucketName/$path/$name',
      () => _storageApi.objects.get(effectiveBucketName, '$path/$name'),
    );

    if (object is! Object) {
      throw YustException('Unknown response Object');
    }

    // Update metadata
    object.metadata = metadata;

    await _retryOnException(
      'Update-Metadata',
      '$effectiveBucketName/$path/$name',
      () =>
          _storageApi.objects.patch(object, effectiveBucketName, object.name!),
    );
  }

  @override
  Future<void> addMetadata({
    required String path,
    required String name,
    required Map<String, String> metadata,
    String? bucketName,
  }) async {
    final effectiveBucketName = bucketName ?? defaultBucketName;

    // Get current object
    final object = await _retryOnException(
      'Get-Object-For-Metadata-Add',
      '$effectiveBucketName/$path/$name',
      () => _storageApi.objects.get(effectiveBucketName, '$path/$name'),
    );

    if (object is! Object) {
      throw YustException('Unknown response Object');
    }

    // Merge with existing metadata
    final existingMetadata = object.metadata ?? <String, String>{};
    final mergedMetadata = <String, String>{...existingMetadata, ...metadata};

    object.metadata = mergedMetadata;

    await _retryOnException(
      'Add-Metadata',
      '$effectiveBucketName/$path/$name',
      () =>
          _storageApi.objects.patch(object, effectiveBucketName, object.name!),
    );
  }

  /// Retries the given function if a TlsException, ClientException or YustBadGatewayException occurs.
  /// Those are network errors that can occur when the firestore is rate-limiting.
  Future<T?> _retryOnException<T>(
    String fnName,
    String docPath,
    Future<T> Function() fn, {
    bool shouldIgnoreNotFound = false,
  }) async {
    final maxTries = 16;
    return await YustRetryHelper.retryOnException<T>(
      fnName,
      docPath,
      fn,
      maxTries: maxTries,
      actionOnExceptionList: [
        YustRetryHelper.actionOnNetworkException,
        YustRetryHelper.actionOnDetailedApiRequestError(
          shouldIgnoreNotFound: shouldIgnoreNotFound,
        ),
      ],
      onRetriesExceeded: (lastError, fnName, docPath) => print(
        '[[ERROR]] Retried $fnName call $maxTries times, but still failed: $lastError for $docPath',
      ),
    );
  }
}
