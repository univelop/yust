import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:mime/mime.dart';

import '../util/yust_exception.dart';

class YustFileService {
  YustFileService() : _fireStorage = firebase_storage.FirebaseStorage.instance;

  YustFileService.mocked() : _fireStorage = MockFirebaseStorage();

  final firebase_storage.FirebaseStorage _fireStorage;

  Future<String> uploadFile(
      {required String path,
      required String name,
      File? file,
      Uint8List? bytes}) async {
    try {
      final storageReference = _fireStorage.ref().child(path).child(name);

      var size = _calcMaxUploadRetryTime(bytes, file);
      firebase_storage.FirebaseStorage.instance
          .setMaxUploadRetryTime(Duration(seconds: size * 30));

      firebase_storage.UploadTask uploadTask;
      if (file != null) {
        uploadTask = storageReference.putFile(file);
      } else {
        var metadata = firebase_storage.SettableMetadata(
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
      {required String path, required String name, int? maxSize}) async {
    try {
      return await _fireStorage
          .ref()
          .child(path)
          .child(name)
          .getData(maxSize ?? 5 * 1024 * 1024);
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
    try {
      await _fireStorage.ref().child(path).child(name).getDownloadURL();
    } on firebase_storage.FirebaseException catch (_) {
      return false;
    }
    return true;
  }

  Future<String> getFileDownloadUrl(
      {required String path, required String name}) async {
    return await _fireStorage.ref().child(path).child(name).getDownloadURL();
  }
}
