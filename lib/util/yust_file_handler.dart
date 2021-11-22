import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/util/yust_offline_cache.dart';
import 'package:yust/yust.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'yust_exception.dart';

class YustFileHandler {
  final String folderPath;
  List<YustFile> files;
  final void Function(List<YustFile> images) onChanged;
  final Function(List<YustFile>) changeCallback;

  /// [pathToDoc] and [docAttribute] are needed for the offline compatibility.
  /// If not given, uploads are only possible with internet connection
  final String? pathToDoc;

  /// [pathToDoc] and [docAttribute] are needed for the offline compatibility.
  /// If not given, uploads are only possible with internet connection
  final String? docAttribute;

  YustFileHandler({
    required this.files,
    required this.folderPath,
    required this.onChanged,
    required this.changeCallback,
    this.pathToDoc,
    this.docAttribute,
  });

  Future<void> deleteFile(YustFile file, BuildContext context) async {
    Yust.service.unfocusCurrent(context);
    final connectivityResult = await Connectivity().checkConnectivity();
    if (YustOfflineCache.isLocalPath(file.url ?? '')) {
      bool? confirmed = false;
      confirmed = await Yust.service
          .showConfirmation(context, 'Wirklich löschen', 'Löschen');

      if (confirmed == true) {
        try {
          await YustOfflineCache.deleteLocalFile(file.name);
        } catch (e) {}
        files.remove(file);

        changeCallback(files);
        onChanged(files);
      }
    } else if (connectivityResult == ConnectivityResult.none) {
      // if the file is not local, and there is no connectivityResult, you can not delete the file
      Yust.service.showAlert(context, 'Kein Internet',
          'Für das Löschen der Datei ist eine Internetverbindung erforderlich.');
    } else {
      final confirmed = await Yust.service
          .showConfirmation(context, 'Wirklich löschen', 'Löschen');
      if (confirmed == true) {
        try {
          await firebase_storage.FirebaseStorage.instance
              .ref()
              .child(folderPath)
              .child(file.name)
              .delete();
        } catch (e) {}
        files.remove(file);
        changeCallback(files);
        onChanged(files);
      }
    }
  }

  Future<void> uploadFile({
    File? file,
    Uint8List? bytes,
    required String name,
    required bool mounted,
    required BuildContext context,
  }) async {
    final newFile = YustFile(
      name: name,
      url: '',
      file: file,
      bytes: bytes,
      processing: false,
    );
    // files.add(newFile);
    changeCallback(files);
    //if there are bytes in the file, it is a WEB operation > offline compatibility is not implemented
    if (isOfflineUploadPossible() && bytes == null) {
      newFile.url = await YustOfflineCache.saveFileTemporary(
        file: newFile,
        docAttribute: docAttribute!,
        folderPath: folderPath,
        pathToDoc: pathToDoc!,
      );
    } else {
      try {
        newFile.url = await Yust.service
            .uploadFile(path: folderPath, name: name, file: file, bytes: bytes);
      } on YustException catch (e) {
        if (mounted) {
          Yust.service.showAlert(context, 'Ups', e.message);
        }
      } catch (e) {
        if (mounted) {
          Yust.service.showAlert(
              context, 'Ups', 'Die Datei konnte nicht hochgeladen werden.');
        }
      }
    }

    if (newFile.url == '') {
      files.remove(newFile);
      changeCallback(files);
    }

    if (mounted) {
      changeCallback(files);
    }

    onChanged(files);

    YustOfflineCache.uploadLocalFiles(validateLocalFiles: false);
  }

  /// loads the [uploadedFiles] and  the files that are cached locally.
  Future<void> loadFiles(List<YustFile> uploadedFiles) async {
    List<YustLocalFile> localFiles = await YustOfflineCache.getLocalFiles();
    for (var localFile in localFiles) {
      if (localFile.folderPath == folderPath) {
        YustFile file = localFile;
        file.file = File(localFile.localPath);
        uploadedFiles.add(file);
      }
    }
    files = uploadedFiles;
  }

  bool isOfflineUploadPossible() {
    return docAttribute != null && pathToDoc != null;
  }
}
