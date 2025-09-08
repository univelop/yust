import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';
import 'package:mime/mime.dart';

import '../util/yust_exception.dart';
import 'yust_file_service_interface.dart';
import 'yust_file_service_shared.dart';

class YustFileService implements IYustFileService {
  late String defaultBucketName;

  YustFileService({
    Client? authClient,
    required String? emulatorAddress,
    required String projectId,
  }) : _fireStorage = FirebaseStorage.instance {
    defaultBucketName = '$projectId.appspot.com';
    if (emulatorAddress != null) {
      _fireStorage.useStorageEmulator(emulatorAddress, 9199);
    }
  }

  YustFileService.mocked() : _fireStorage = FirebaseStorage.instance {
    defaultBucketName = 'mocked-bucket';
    throw UnsupportedError('Not supported in Flutter Environment');
  }

  final FirebaseStorage _fireStorage;

  /// Returns the appropriate FirebaseStorage instance for the bucket
  FirebaseStorage _getStorageForBucket(String? bucketName) {
    final effectiveBucketName = bucketName ?? defaultBucketName;
    if (effectiveBucketName == defaultBucketName) {
      return _fireStorage;
    }
    // For different buckets, create a new instance
    return FirebaseStorage.instanceFor(bucket: effectiveBucketName);
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
      contentDisposition: contentDisposition,
      bucketName: bucketName,
    );
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
    try {
      final storage = _getStorageForBucket(bucketName);
      final storageReference = storage.ref().child(path).child(name);

      var size = _calcMaxUploadRetryTime(bytes, file);
      FirebaseStorage.instance.setMaxUploadRetryTime(
        Duration(seconds: size * 30),
      );

      UploadTask uploadTask;
      if (file != null) {
        // For file uploads, create metadata with custom metadata if provided
        var fileMetadata = SettableMetadata(
          contentType: lookupMimeType(name),
          customMetadata: metadata,
          contentDisposition: contentDisposition ?? 'inline; filename="$name"',
        );
        uploadTask = storageReference.putFile(file, fileMetadata);
      } else {
        var fileMetadata = SettableMetadata(
          contentType: lookupMimeType(name),
          customMetadata: metadata,
          contentDisposition: contentDisposition ?? 'inline; filename="$name"',
        );
        uploadTask = storageReference.putData(bytes!, fileMetadata);
      }
      await uploadTask;
      return await storageReference.getDownloadURL();
    } catch (e) {
      throw YustException('Error uploading file: $e');
    }
  }

  int _calcMaxUploadRetryTime(Uint8List? bytes, File? file) {
    var size = 0;
    if (bytes != null) {
      size = bytes.lengthInBytes;
    }
    if (file != null) {
      size = file.lengthSync();
    }

    // MaxUploadRetryTime is at minimum 30 seconds - therefore '+1'
    return (size / pow(10, 6)).round() + 1;
  }

  @override
  Future<Uint8List?> downloadFile({
    required String path,
    required String name,
    int maxSize = 20 * 1024 * 1024,
    String? bucketName,
  }) async {
    try {
      final storage = _getStorageForBucket(bucketName);
      return await storage.ref().child(path).child(name).getData(maxSize);
    } catch (e) {
      return Uint8List(0);
    }
  }

  @override
  Future<void> deleteFile({
    required String path,
    String? name,
    String? bucketName,
  }) async {
    if (name == null) return;
    try {
      final storage = _getStorageForBucket(bucketName);
      await storage.ref().child(path).child(name).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return;
      }
    } catch (e) {
      throw YustException(e.toString());
    }
  }

  @override
  Future<bool> fileExist({
    required String path,
    required String name,
    String? bucketName,
  }) async {
    try {
      final storage = _getStorageForBucket(bucketName);
      await storage.ref().child(path).child(name).getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<String> getFileDownloadUrl({
    required String path,
    required String name,
    String? bucketName,
  }) async {
    final storage = _getStorageForBucket(bucketName);
    return await storage.ref().child(path).child(name).getDownloadURL();
  }

  @override
  Future<YustFileMetadata> getMetadata({
    required String path,
    required String name,
    String? bucketName,
  }) async {
    final storage = _getStorageForBucket(bucketName);
    final metadata = await storage.ref().child(path).child(name).getMetadata();

    return YustFileMetadata(
      size: metadata.size ?? 0,
      token: metadata.customMetadata?['firebaseStorageDownloadTokens'] ?? '',
      customMetadata: metadata.customMetadata,
    );
  }

  @override
  Future<void> deleteFolder({required String path, String? bucketName}) async {
    final storage = _getStorageForBucket(bucketName);
    final fileList = await storage.ref().child(path).list();
    for (final file in fileList.items) {
      await file.delete();
    }
  }

  @override
  Future<List<Object>> getFilesInFolder({
    required String path,
    String? bucketName,
  }) async {
    throw YustException('Not implemented for flutter');
  }

  @override
  Future<Map<String?, List<Object>>> getFileVersionsGrouped({
    required String path,
    String? bucketName,
  }) async {
    throw YustException('Not implemented for flutter');
  }

  @override
  Future<String?> getLatestFileVersion({
    required String path,
    required String name,
    String? bucketName,
  }) async {
    throw YustException('Not implemented for flutter');
  }

  @override
  Future<String?> getLatestInvalidFileVersion({
    required String path,
    required String name,
    DateTime? beforeDeletion,
    DateTime? afterDeletion,
    String? bucketName,
  }) async {
    throw YustException('Not implemented for flutter');
  }

  @override
  Future<void> recoverOutdatedFile({
    required String path,
    required String name,
    required String generation,
    String? bucketName,
  }) async {
    throw YustException('Not implemented for flutter');
  }

  @override
  Future<void> updateMetadata({
    required String path,
    required String name,
    required Map<String, String> metadata,
    String? bucketName,
  }) async {
    try {
      final storage = _getStorageForBucket(bucketName);
      final storageReference = storage.ref().child(path).child(name);

      final newMetadata = SettableMetadata(customMetadata: metadata);

      await storageReference.updateMetadata(newMetadata);
    } catch (e) {
      throw YustException('Error updating metadata: $e');
    }
  }

  @override
  Future<void> addMetadata({
    required String path,
    required String name,
    required Map<String, String> metadata,
    String? bucketName,
  }) async {
    try {
      final storage = _getStorageForBucket(bucketName);
      final storageReference = storage.ref().child(path).child(name);

      // Get current metadata first
      final currentMetadata = await storageReference.getMetadata();
      final existingCustomMetadata =
          currentMetadata.customMetadata ?? <String, String>{};

      // Merge with new metadata
      final mergedMetadata = <String, String>{
        ...existingCustomMetadata,
        ...metadata,
      };

      final newMetadata = SettableMetadata(customMetadata: mergedMetadata);

      await storageReference.updateMetadata(newMetadata);
    } catch (e) {
      throw YustException('Error adding metadata: $e');
    }
  }
}
