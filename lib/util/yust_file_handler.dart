import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/yust.dart';

import 'yust_exception.dart';

class YustFileHandler {
  final Function() callback;

  YustFileHandler({
    required this.callback,
  });

  void mergeOnlineFiles(List<YustFile> yustFiles,
      List<Map<String, String?>> onlineFiles, String storageFolderPath) async {
    final onlineYustFiles = yustFilesFromJson(onlineFiles, storageFolderPath);
    _mergeIntoYustFiles(yustFiles, onlineYustFiles);
  }

  Future<void> mergeCachedFiles(List<YustFile> yustFiles, String? linkedDocPath,
      String? linkedDocAttribute) async {
    if (linkedDocPath != null && linkedDocAttribute != null) {
      var cachedFiles = await _getCachedFiles();
      cachedFiles = cachedFiles
          .where((yustFile) =>
              yustFile.linkedDocPath == linkedDocPath &&
              yustFile.linkedDocAttribute == linkedDocAttribute)
          .toList();
      _mergeIntoYustFiles(yustFiles, cachedFiles);
    }
  }

  Future<void> addFile(YustFile yustFile) async {
    if (!kIsWeb && yustFile.cacheable) {
      await _saveFileOnDevice(yustFile);
      try {
        await _uploadFileToStorage(yustFile);
        await _deleteFileFromCache(yustFile);
      } catch (error) {
        print(error.toString());
        // TODO: Error handling
      }
    } else {
      await _uploadFileToStorage(yustFile);
    }
  }

  Future<void> deleteFile(List<YustFile> yustFiles, YustFile yustFile) async {
    if (yustFile.cached) {
      _deleteFileFromCache(yustFile);
    } else {
      _deleteFileFromStorage(yustFile);
    }
    yustFiles.removeWhere((f) => f.name == yustFile.name);
    callback();
  }

  Future<void> uploadCachedFiles() async {
    final cachedFiles = await _getCachedFiles();
    for (final yustFile in cachedFiles) {
      try {
        await _uploadFileToStorage(yustFile);
        await _deleteFileFromCache(yustFile, cachedFiles);
      } catch (error) {
        print(error.toString());
        // TODO: Error handling
      }
    }
  }

  Future<void> showFile(BuildContext context, YustFile yustFile) async {
    await EasyLoading.show(status: 'Datei laden...');
    try {
      if (!kIsWeb) {
        String filePath;
        if (yustFile.cached) {
          filePath = yustFile.devicePath!;
        } else if (yustFile.url == null) {
          throw YustException('Die Datei existiert nicht.');
        } else {
          final tempDir = await getTemporaryDirectory();
          filePath = '${tempDir.path}/${yustFile.name}';
          await Dio().download(yustFile.url!, filePath);
        }
        var result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          _launch(yustFile);
        }
      } else {
        _launch(yustFile);
      }
      await EasyLoading.dismiss();
    } catch (e) {
      await EasyLoading.dismiss();
      await Yust.service.showAlert(context, 'Ups',
          'Die Datei kann nicht geöffnet werden. ${e.toString()}');
    }
  }

  List<YustFile> yustFilesFromJson(
      List<Map<String, String?>> jsonFiles, String storageFolderPath) {
    return jsonFiles
        .map((f) => YustFile.fromJson(f)..storageFolderPath = storageFolderPath)
        .toList();
  }

  List<Map<String, String?>> yustFilesToJson(List<YustFile> yustFiles) {
    return yustFiles.map((f) => f.toJson()).toList();
  }

  void _mergeIntoYustFiles(List<YustFile> yustFiles, List<YustFile> newFiles) {
    for (final newFile in newFiles) {
      if (!yustFiles.any((yustFile) => yustFile.name == newFile.name)) {
        yustFiles.add(newFile);
      }
    }
  }

  Future<void> _saveFileOnDevice(YustFile yustFile) async {
    final tempDir = await getTemporaryDirectory();
    yustFile.devicePath = '${tempDir.path}/${yustFile.name}';
    // TODO: file name muss nicht eindeutig sein.
    await yustFile.file!.copy(yustFile.devicePath!);
    final cachedFileList = await _getCachedFiles();
    cachedFileList.add(yustFile);
    await _saveCachedFiles(cachedFileList);
  }

  Future<void> _uploadFileToStorage(YustFile yustFile) async {
    // throw YustException('No internet');
    if (yustFile.storageFolderPath == null) {
      throw (YustException(
          'Can not upload file. The storage folder path is missing.'));
    }
    yustFile.processing = true;
    callback();
    final url = await Yust.service.uploadFile(
      path: yustFile.storageFolderPath!,
      name: yustFile.name,
      file: yustFile.file,
      bytes: yustFile.bytes,
    );
    yustFile.url = url;
    // TODO: Wo updaten wir die Datenbank?
    yustFile.processing = false;
    callback();
  }

  Future<void> _deleteFileFromStorage(YustFile yustFile) async {
    if (yustFile.storageFolderPath != null) {
      await Yust.service
          .deleteFile(path: yustFile.storageFolderPath!, name: yustFile.name);
    }
  }

  Future<void> _deleteFileFromCache(YustFile yustFile,
      [List<YustFile>? cachedFiles]) async {
    cachedFiles ??= await _getCachedFiles();
    if (yustFile.devicePath != null &&
        File(yustFile.devicePath!).existsSync()) {
      await File(yustFile.devicePath!).delete();
    }
    cachedFiles.removeWhere((f) => f.devicePath == yustFile.devicePath);
    await _saveCachedFiles(cachedFiles);
    yustFile.devicePath = null;
    callback();
  }

  /// Loads a list of all cached [YustFile]s.
  Future<List<YustFile>> _getCachedFiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var temporaryJsonFiles = prefs.getString('temporaryFiles');
    // TODO: Prefs name ändern?
    return jsonDecode(temporaryJsonFiles ?? '[]')
        .map<YustFile>((file) => YustFile.fromLocalJson(file))
        .toList();
  }

  /// Saves all cached [YustFile]s.
  Future<void> _saveCachedFiles(List<YustFile> yustFiles) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var jsonFiles = yustFiles.map((file) => file.toLocalJson()).toList();
    await prefs.setString('temporaryFiles', jsonEncode(jsonFiles));
  }

  Future<void> _launch(YustFile file) async {
    if (await canLaunch(file.url ?? '')) {
      await launch(file.url ?? '');
    } else {
      throw YustException('Öffnen nicht erlaubt.');
    }
  }
}
