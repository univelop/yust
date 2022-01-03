import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
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

  /// shows if the _uploadFiles-procces is currently running
  static bool _uploadingCachedFiles = false;

  /// Steadily increasing by the [_reuploadFactor]. Indicates the next upload attempt.
  /// [_reuploadTime] is reset for each upload
  Duration _reuploadTime = new Duration(milliseconds: 250);
  double _reuploadFactor = 1.25;

  List<YustFile> _yustFiles = [];

  YustFileHandler({
    required this.storageFolderPath,
    this.linkedDocAttribute,
    this.linkedDocPath,
  });

  List<YustFile> getFiles() {
    return _yustFiles;
  }

  List<YustFile> getOnlineFiles() {
    return _yustFiles.where((f) => f.cached == false).toList();
  }

  Future<void> updateFiles(List<YustFile> onlineFiles,
      {bool loadFiles = false}) async {
    _yustFiles = [];
    _mergeOnlineFiles(_yustFiles, onlineFiles, storageFolderPath);
    await _mergeCachedFiles(_yustFiles, linkedDocPath, linkedDocAttribute);

    if (loadFiles) await _loadFiles();
  }

  Future<void> _loadFiles() async {
    for (var yustFile in _yustFiles) {
      if (yustFile.cached) {
        yustFile.file = File(yustFile.devicePath!);
      }
    }
  }

  void _mergeOnlineFiles(List<YustFile> yustFiles, List<YustFile> onlineFiles,
      String storageFolderPath) async {
    onlineFiles.forEach((f) => f.storageFolderPath = storageFolderPath);
    _mergeIntoYustFiles(_yustFiles, onlineFiles);
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
    _yustFiles.add(yustFile);
    if (!kIsWeb && yustFile.cacheable) {
      await _saveFileOnDevice(yustFile);
      if (!_uploadingCachedFiles) {
        _uploadingCachedFiles = true;
        _uploadCachedFiles(_reuploadTime);
      }
    } else {
      await _uploadFileToStorage(yustFile);
    }
  }

  /// if online files get deleted while the device is offline, error is thrown
  Future<void> deleteFile(YustFile yustFile) async {
    if (yustFile.cached) {
      await _deleteFileFromCache(yustFile);
    } else {
      await _deleteFileFromStorage(yustFile);
    }
    _yustFiles.removeWhere((f) => f.name == yustFile.name);
  }

  /// Uploads all cached files. If the upload fails,  a new attempt is made after [_reuploadTime].
  /// Can be started only once, renewed call only possible after successful upload.
  /// [validateCachedFiles] can delete files added shortly before if they are not yet
  /// entered in the database. Check this before!
  static Future<void> uploadCachedFiles(
      {bool validateCachedFiles = true}) async {
    if (!_uploadingCachedFiles) {
      _uploadingCachedFiles = true;

      YustFileHandler _filehandler = new YustFileHandler(storageFolderPath: '');
      if (validateCachedFiles) await _filehandler._validateCachedFiles();

      await _filehandler._uploadCachedFiles(_filehandler._reuploadTime);
    }
  }

  Future<void> _uploadCachedFiles(Duration reuploadTime) async {
    List<YustFile> cachedFiles = await _getCachedFiles();
    bool uploadError = false;
    // print("Cache: try to upload");
    for (final yustFile in cachedFiles) {
      yustFile.lastError = null;
      try {
        await _uploadFileToStorage(yustFile);
        await _deleteFileFromCache(yustFile);
      } catch (error) {
        print(error.toString());
        yustFile.lastError = error.toString();
        uploadError = true;
      }
    }

    cachedFiles.removeWhere((f) => f.lastError == null);
    int length = cachedFiles.length;
    _mergeIntoYustFiles(cachedFiles, await _getCachedFiles());

    if (length < cachedFiles.length) {
      // retry upload with reseted uploadTime because new files where added
      uploadError = true;
      reuploadTime = _reuploadTime;
    }

    if (!uploadError) {
      // print("Cache: Success!");
      _uploadingCachedFiles = false;
    } else {
      // saving cachedFiles, to store error log messages
      await _saveCachedFiles(cachedFiles);

      reuploadTime = reuploadTime;
      // print("Cache: Try again in " + reuploadTime.toString());
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

  /// works for cacheable and non-cacheable files
  void _mergeIntoYustFiles(List<YustFile> yustFiles, List<YustFile> newFiles) {
    for (final newFile in newFiles) {
      if (!yustFiles.any((yustFile) {
        bool nameEQ = yustFile.name == newFile.name;
        if (yustFile.cacheable && newFile.cacheable) {
          return nameEQ &&
              yustFile.linkedDocPath == newFile.linkedDocPath &&
              yustFile.linkedDocAttribute == newFile.linkedDocAttribute;
        }
        return nameEQ;
      })) {
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

    var attribute;
    if (yustFile.cached) {
      if (await _isFileInCache(yustFile)) {
        yustFile.file = File(yustFile.devicePath!);
      } else {
        //removing file data, because file is missing in cache
        await _deleteFileFromCache(yustFile);
        return;
      }
      attribute = await _getDocAttribute(yustFile);
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
      oldAttribute, YustFile cachedFile, String url) async {
    var newAttribute = await _getDocAttribute(cachedFile);

    if (_areAttributesEqual(oldAttribute, newAttribute)) {
      if (oldAttribute is Map) {
        if (oldAttribute['url'] == null) {
          oldAttribute['name'] = cachedFile.name;
          oldAttribute['url'] = url;
        } else {
          // edge case: image picker changes from single- to multi-image view
          oldAttribute = [oldAttribute];
        }
      }
      if (oldAttribute is List) {
        oldAttribute.removeWhere((f) => f['name'] == cachedFile.name);
        oldAttribute.add({'name': cachedFile.name, 'url': url});
      }

      await FirebaseFirestore.instance
          .doc(cachedFile.linkedDocPath!)
          .update({cachedFile.linkedDocAttribute!: oldAttribute});
    } else {
      _updateDocAttribute(newAttribute, cachedFile, url);
    }
  }

  bool _areAttributesEqual(a1, a2) {
    if (a1 is Map && a2 is Map) {
      return a1['name'] == a2['name'] && a1['url'] == a2['url'];
    }
    if (a1 is List && a2 is List) {
      return DeepCollectionEquality().equals(a1, a2);
    }
    return false;
  }

  Future<dynamic> _getDocAttribute(YustFile yustFile) async {
    var attribute;
    final doc = await FirebaseFirestore.instance
        .doc(yustFile.linkedDocPath!)
        .get(GetOptions(source: Source.server));

    if (doc.exists && doc.data() != null) {
      try {
        attribute = doc.get(yustFile.linkedDocAttribute!);
      } catch (e) {
        // edge case, image picker allows only one image, attribute must be initialized manually
        attribute = {'name': yustFile.name, 'url': null};
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
          .deleteFile(path: yustFile.storageFolderPath!, name: yustFile.name)
          .timeout(Duration(seconds: 1));
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

  /// Limits [reuploadTime] to 10 minutes
  Duration _incReuploadTime(Duration reuploadTime) {
    return reuploadTime > Duration(minutes: 10)
        ? Duration(minutes: 10)
        : reuploadTime * _reuploadFactor;
  }

  Future<bool> _isFileInCache(YustFile yustFile) async {
    return yustFile.devicePath != null &&
        await File(yustFile.devicePath!).exists();
  }
}
