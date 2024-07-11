import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';
import 'package:mime/mime.dart';

import '../util/yust_exception.dart';

class YustFileService {
  YustFileService({
    Client? authClient,
    required String? emulatorAddress,
    required String projectId,
  }) : _fireStorage = FirebaseStorage.instance {
    if (emulatorAddress != null) {
      _fireStorage.useStorageEmulator(emulatorAddress, 9199);
    }
  }

  YustFileService.mocked() : _fireStorage = FirebaseStorage.instance {
    throw UnsupportedError('Not supported in Flutter Environment');
  }

  final FirebaseStorage _fireStorage;

  Future<String> uploadFile(
      {required String path,
      required String name,
      File? file,
      Uint8List? bytes}) async {
    try {
      final storageReference = _fireStorage.ref().child(path).child(name);

      var size = _calcMaxUploadRetryTime(bytes, file);
      FirebaseStorage.instance
          .setMaxUploadRetryTime(Duration(seconds: size * 30));

      UploadTask uploadTask;
      if (file != null) {
        uploadTask = storageReference.putFile(file);
      } else {
        var metadata = SettableMetadata(
          contentType: lookupMimeType(name),
        );
        uploadTask = storageReference.putData(bytes!, metadata);
      }
      await uploadTask;
      return await storageReference.getDownloadURL();
    } catch (error) {
      throw YustException('Fehler beim Upload: ${error.toString()}');
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

  Future<Uint8List?> downloadFile(
      {required String path,
      required String name,
      int maxSize = 20 * 1024 * 1024}) async {
    try {
      return await _fireStorage.ref().child(path).child(name).getData(maxSize);
    } catch (e) {
      return Uint8List(0);
    }
  }

  Future<void> deleteFile({required String path, String? name}) async {
    if (name == null) return;
    try {
      await _fireStorage.ref().child(path).child(name).delete();
    } catch (e) {
      throw YustException(e.toString());
    }
  }

  Future<bool> fileExist({required String path, required String name}) async {
    final fileList = await _fireStorage.ref().child(path).list();
    return fileList.items.any((element) => element.name == name);
  }

  Future<String> getFileDownloadUrl(
      {required String path, required String name}) async {
    return await _fireStorage.ref().child(path).child(name).getDownloadURL();
  }

  Future<void> deleteFolder({required String path}) async {
    final fileList = await _fireStorage.ref().child(path).list();
    for (final file in fileList.items) {
      await file.delete();
    }
  }

  Future<List<Object>> getFilesInFolder({required String path}) async {
    throw YustException('Not implemented for flutter');
  }

  Future<List<Object>> getFileVersionsInFolder({required String path}) async {
    throw YustException('Not implemented for flutter');
  }

  Future<Map<String?, List<Object>>> getFileVersionsGrouped(
      {required String path}) async {
    throw YustException('Not implemented for flutter');
  }

  Future<String?> getLatestFileVersion(
      {required String path, required String name}) async {
    throw YustException('Not implemented for flutter');
  }

  Future<String?> getLatestInvalidFileVersion({
    required String path,
    required String name,
    DateTime? beforeDeletion,
    DateTime? afterDeletion,
  }) async {
    throw YustException('Not implemented for flutter');
  }

  Future<void> recoverOutdatedFile(
      {required String path,
      required String name,
      required String generation}) async {
    throw YustException('Not implemented for flutter');
  }
}
