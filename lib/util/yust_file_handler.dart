import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  /// Path to the storage folder.
  final String storageFolderPath;

  /// Path to the Firebase document.
  final String? linkedDocPath;

  /// Attribute of the Firebase document.
  final String? linkedDocAttribute;
  List<Map<String, String?>> onlineFiles;

  /// shows if the _uploadFiles-procces is currently running
  static bool _uploadingCachedFiles = false;

  /// Steadily increasing by the [_reuploadFactor]. Indicates the next upload attempt.
  /// [_reuploadTime] is reset for each upload
  Duration _reuploadTime = new Duration(milliseconds: 250);
  double _reuploadFactor = 1.25;

  List<YustFile> _yustFiles = [];
  YustFile? _lastDeletedFile;

  YustFileHandler({
    required this.storageFolderPath,
    this.linkedDocAttribute,
    this.linkedDocPath,
    required this.onlineFiles,
  });

  Future<List<YustFile>> updateFiles(
      List<Map<String, String?>> onlineFiles) async {
    _yustFiles = [];
    _mergeOnlineFiles(_yustFiles, onlineFiles, storageFolderPath);
    await _mergeCachedFiles(_yustFiles, linkedDocPath, linkedDocAttribute);

    return _yustFiles;
  }

  void _mergeOnlineFiles(List<YustFile> yustFiles,
      List<Map<String, String?>> onlineFiles, String storageFolderPath) async {
    final onlineYustFiles = yustFilesFromJson(onlineFiles, storageFolderPath);
    if (_lastDeletedFile != null)
      onlineYustFiles.removeWhere((f) => f.name == _lastDeletedFile!.name);
    _mergeIntoYustFiles(_yustFiles, onlineYustFiles);
  }

  Future<void> _mergeCachedFiles(List<YustFile> yustFiles,
      String? linkedDocPath, String? linkedDocAttribute) async {
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
        // throw Error();
        await _uploadFileToStorage(yustFile);
        await _deleteFileFromCache(yustFile);
      } catch (error) {
        print(error.toString());
        yustFile.lastError = error.toString();
        await _saveFileOnDevice(yustFile);

        Future.delayed(_reuploadTime, () {
          uploadCachedFiles(validateCachedFiles: false);
        });
      }
    } else {
      await _uploadFileToStorage(yustFile);
    }
  }

  Future<void> deleteFile(YustFile yustFile) async {
    if (yustFile.cached) {
      await _deleteFileFromCache(yustFile);
    } else {
      await _deleteFileFromStorage(yustFile);
    }

    _lastDeletedFile = yustFile;
    _yustFiles.removeWhere((f) => f.name == yustFile.name);
    // callback();
  }

  /// Uploads all cached files. If the upload fails,  a new attempt is made after [_reuploadTime].
  /// Can be started only once, renewed call only possible after successful upload.
  /// [validateCachedFiles] can delete files added shortly before if they are not yet
  /// entered in the database. Check this before!

  // TODO: uploadCachedFiles im konstanten Intervall von 1 Minute ab App start.
  static Future<void> uploadCachedFiles(
      {bool validateCachedFiles = true}) async {
    if (!_uploadingCachedFiles) {
      _uploadingCachedFiles = true;

      YustFileHandler _filehandler =
          new YustFileHandler(storageFolderPath: '', onlineFiles: []);
      if (validateCachedFiles) await _filehandler._validateCachedFiles();

      await _filehandler._uploadCachedFiles(_filehandler._reuploadTime);
    }
  }

  Future<void> _uploadCachedFiles(Duration reuploadTime) async {
    final cachedFiles = await _getCachedFiles();
    bool uploadError = false;

    for (final yustFile in cachedFiles) {
      try {
        await _uploadFileToStorage(yustFile);
        await _deleteFileFromCache(yustFile);
      } catch (error) {
        print(error.toString());
        yustFile.lastError = error.toString();
        _saveFileOnDevice(yustFile);

        uploadError = true;
      }
    }

    if (!uploadError) {
      _uploadingCachedFiles = false;
    } else {
      reuploadTime = reuploadTime;
      Future.delayed(reuploadTime, () {
        reuploadTime = _incReuploadTime(reuploadTime);
        _uploadCachedFiles(reuploadTime);
      });
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
          filePath = await _getDirectory(yustFile) + '${yustFile.name}';

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
    String devicePath = await _getDirectory(yustFile);

    yustFile.devicePath = devicePath + '${yustFile.name}';

    await yustFile.file!.copy(yustFile.devicePath!);
    final cachedFileList = await _getCachedFiles();
    cachedFileList.add(yustFile);
    await _saveCachedFiles(cachedFileList);
  }

  Future<String> _getDirectory(YustFile yustFile) async {
    final tempDir = await getTemporaryDirectory();

    String devicePath = '${tempDir.path}/${yustFile.storageFolderPath}/';

    if (!Directory(devicePath).existsSync()) {
      await Directory(devicePath).create(recursive: true);
    }

    return devicePath;
  }

  Future<void> _uploadFileToStorage(YustFile yustFile) async {
    // throw YustException('No internet');
    if (yustFile.storageFolderPath == null) {
      throw (YustException(
          'Can not upload file. The storage folder path is missing.'));
    }

    // yustFile.processing = true;
    var attribute;

    if (yustFile.cached) {
      if (_isFileInCache(yustFile)) {
        attribute = await _getDocAttribute(yustFile);
        yustFile.file = File(yustFile.devicePath!);
      } else {
        //removing file data, because file is missing in cache
        await _deleteFileFromCache(yustFile);
        // yustFile.processing = false;
        return;
      }
    }

    final url = await Yust.service.uploadFile(
      path: yustFile.storageFolderPath!,
      name: yustFile.name,
      file: yustFile.file,
      bytes: yustFile.bytes,
    );
    yustFile.url = url;

    if (yustFile.cached) await _updateDocAttribute(attribute, yustFile, url);
  }

  Future<void> _updateDocAttribute(
      attribute, YustFile cachedFile, String url) async {
    if (attribute is Map) {
      attribute['name'] = cachedFile.name;
      attribute['url'] = url;
    } else if (attribute is List) {
      attribute.add({'name': cachedFile.name, 'url': url});
    }

    await FirebaseFirestore.instance
        .doc(cachedFile.linkedDocPath!)
        .update({cachedFile.linkedDocAttribute!: attribute});
  }

  Future<dynamic> _getDocAttribute(YustFile yustFile) async {
    var attribute;
    final doc =
        await FirebaseFirestore.instance.doc(yustFile.linkedDocPath!).get();
    if (doc.exists && doc.data() != null) {
      try {
        attribute = doc.get(yustFile.linkedDocAttribute!);
      } catch (e) {
        // edge case, image picker allows only one image, attribute must be initialized manually
        attribute = {'name': '', 'url': null};
      }
    } else {
      // It is possible that the upload accesses the database before the searched address is initialized.
      // If the access adress is corrupt, the process 'validateLocalFiles' removes the file.
      throw YustException(
          'Database entry did not exist. Try again in a moment.');
    }
    return attribute;
  }

  Future<void> _deleteFileFromStorage(YustFile yustFile) async {
    if (yustFile.storageFolderPath != null) {
      await Yust.service
          .deleteFile(path: yustFile.storageFolderPath!, name: yustFile.name);
    }
  }

  Future<void> _deleteFileFromCache(YustFile yustFile) async {
    List<YustFile> cachedFiles = await _getCachedFiles();
    if (yustFile.devicePath != null &&
        File(yustFile.devicePath!).existsSync()) {
      await File(yustFile.devicePath!).delete();
    }

    cachedFiles.removeWhere((f) => f.devicePath == yustFile.devicePath);
    await _saveCachedFiles(cachedFiles);
    yustFile.devicePath = null;
  }

  /// Loads a list of all cached [YustFile]s.
  Future<List<YustFile>> _getCachedFiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var temporaryJsonFiles = prefs.getString('YustCachedFiles');

    return jsonDecode(temporaryJsonFiles ?? '[]')
        .map<YustFile>((file) => YustFile.fromLocalJson(file))
        .toList();
  }

  /// Saves all cached [YustFile]s.
  Future<void> _saveCachedFiles(List<YustFile> yustFiles) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var jsonFiles = yustFiles.map((file) => file.toLocalJson()).toList();
    await prefs.setString('YustCachedFiles', jsonEncode(jsonFiles));
  }

  Future<void> _launch(YustFile file) async {
    if (await canLaunch(file.url ?? '')) {
      await launch(file.url ?? '');
    } else {
      throw YustException('Öffnen nicht erlaubt.');
    }
  }

  /// Checks the cached files for corruption and deletes them if necessary.
  Future<void> _validateCachedFiles() async {
    var cachedFiles = await _getCachedFiles();
    // Checks if all required database addresses are initialized.
    for (var cachedFile in cachedFiles) {
      final doc =
          await FirebaseFirestore.instance.doc(cachedFile.linkedDocPath!).get();
      if (!doc.exists || doc.data() == null) {
        await _deleteFileFromCache(cachedFile);
      }
    }
  }

  /// Limits [reuploadTime] to 5 minutes
  Duration _incReuploadTime(Duration reuploadTime) {
    return reuploadTime > Duration(minutes: 5)
        ? Duration(minutes: 5)
        : reuploadTime * _reuploadFactor;
  }

  bool _isFileInCache(YustFile yustFile) {
    return yustFile.devicePath != null &&
        File(yustFile.devicePath!).existsSync();
  }
}
