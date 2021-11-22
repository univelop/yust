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
    if (YustOfflineCache.isLocalFile(file.name)) {
      bool? confirmed = false;
      if (file.url == Yust.imageGetUploadedPath || file.file == null) {
        confirmed = await Yust.service.showConfirmation(
            context,
            'Achtung! Diese Datei wird soeben von einem anderen Gerät hochgeladen! Willst du diese Datei wirklich löschen?',
            'Löschen');
      } else {
        confirmed = await Yust.service
            .showConfirmation(context, 'Wirklich löschen', 'Löschen');
      }
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
      file: file,
      bytes: bytes,
      processing: false,
    );

    files.add(newFile);
    changeCallback(files);

    //if there are bytes in the file, it is a WEB operation > offline compatibility is not implemented
    if (isOfflineUploadPossible() && newFile.bytes == null) {
      // Add 'local' as a name suffix to distinguish the files between uploaded and local
      newFile.name = 'local' + newFile.name;
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

    if (newFile.url == null) {
      files.remove(newFile);
      changeCallback(files);
    }

    if (mounted) {
      changeCallback(files);
    }

    onChanged(files);

    YustOfflineCache.uploadLocalFiles(validateLocalFiles: false);
  }

  bool isOfflineUploadPossible() {
    return docAttribute != null && pathToDoc != null;
  }
}
