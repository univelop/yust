import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  final Duration _reuploadTime = Duration(milliseconds: 250);
  final double _reuploadFactor = 1.25;

  List<YustFile> _yustFiles = [];

  var uploadControllIndex = 0;

  /// gets triggerd after successful upload
  void Function()? onFileUploaded;

  YustFileHandler({
    required this.storageFolderPath,
    this.linkedDocAttribute,
    this.linkedDocPath,
    this.onFileUploaded,
  });

  List<YustFile> getFiles() {
    return _yustFiles;
  }

  List<YustFile> getOnlineFiles() {
    return _yustFiles.where((f) => f.cached == false).toList();
  }

  List<YustFile> getCachedFiles() {
    return _yustFiles.where((f) => f.cached == true).toList();
  }

  Future<void> updateFiles(List<YustFile> onlineFiles,
      {bool loadFiles = false}) async {
    // _yustFiles = [];
    _mergeOnlineFiles(_yustFiles, onlineFiles, storageFolderPath);
    await _mergeCachedFiles(_yustFiles, linkedDocPath, linkedDocAttribute);

    if (loadFiles) _loadFiles();
  }

  void _loadFiles() {
    for (var yustFile in _yustFiles) {
      if (yustFile.cached) {
        yustFile.file = File(yustFile.devicePath!);
      }
    }
  }

  void _mergeOnlineFiles(List<YustFile> yustFiles, List<YustFile> onlineFiles,
      String storageFolderPath) async {
    onlineFiles.forEach((f) => f.storageFolderPath = storageFolderPath);
    _mergeIntoYustFiles(yustFiles, onlineFiles);
  }

  Future<void> _mergeCachedFiles(List<YustFile> yustFiles,
      String? linkedDocPath, String? linkedDocAttribute) async {
    if (linkedDocPath != null && linkedDocAttribute != null) {
      var cachedFiles = await _loadCachedFiles();
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
      _startUploadingCachedFiles();
    } else {
      await _uploadFileToStorage(yustFile);
    }
  }

  /// if online files get deleted while the device is offline, error is thrown
  Future<void> deleteFile(YustFile yustFile) async {
    if (yustFile.cached) {
      await _deleteFileFromCache(yustFile);
    } else {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw ('No internet connection.');
      }
      try {
        await _deleteFileFromStorage(yustFile);
        // ignore: empty_catches
      } catch (e) {}
    }
    _yustFiles.removeWhere((f) => f.name == yustFile.name);
  }

  /// Uploads all cached files. If the upload fails,  a new attempt is made after [_reuploadTime].
  /// Can be started only once, renewed call only possible after successful upload.
  static Future<void> uploadCachedFiles() async {
    if (!_uploadingCachedFiles) {
      var _filehandler = YustFileHandler(storageFolderPath: '');
      await _filehandler._validateCachedFiles();
      _filehandler._startUploadingCachedFiles();
    }
  }

  void _startUploadingCachedFiles() {
    if (!_uploadingCachedFiles) {
      _uploadingCachedFiles = true;
      uploadControllIndex++;
      if (uploadControllIndex > 1) {
        print('CRITICAL ERROR');
      }
      _uploadCachedFiles(_reuploadTime);
    }
  }

  Future<void> _uploadCachedFiles(Duration reuploadTime) async {
    print('UCI: ' + uploadControllIndex.toString());
    var cachedFiles = getCachedFiles();
    var uploadError = false;
    for (final yustFile in cachedFiles) {
      yustFile.lastError = null;
      try {
        await _uploadFileToStorage(yustFile);
        await _deleteFileFromCache(yustFile);

        _yustFiles.firstWhere((file) => file.name == yustFile.name).devicePath =
            null;
        if (onFileUploaded != null) onFileUploaded!();
      } catch (error) {
        print(error.toString());
        yustFile.lastError = error.toString();
        uploadError = true;
      }
    }
    if (cachedFiles.isNotEmpty) {
      cachedFiles.removeWhere((f) => f.lastError == null);
    }
    var length = cachedFiles.length;
    _mergeIntoYustFiles(cachedFiles, getCachedFiles());

    if (length < cachedFiles.length) {
      // retry upload with reseted uploadTime, because new files where added
      uploadError = true;
      reuploadTime = _reuploadTime;
    }

    if (!uploadError) {
      _uploadingCachedFiles = false;
      uploadControllIndex--;
    } else {
      // saving cachedFiles, to store error log messages
      await _saveCachedFiles(cachedFiles);

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
          await EasyLoading.show(status: 'Datei laden...');
          filePath = await _getDirectory(yustFile) + '${yustFile.name}';

          await Dio().download(yustFile.url!, filePath);
          await EasyLoading.dismiss();
        }
        var result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          await _launchBrowser(yustFile);
        }
      } else {
        await _launchBrowser(yustFile);
      }
      await EasyLoading.dismiss();
    } catch (e) {
      await EasyLoading.dismiss();
      await Yust.alertService.showAlert(context, 'Ups',
          'Die Datei kann nicht geöffnet werden. ${e.toString()}');
    }
  }

  List<YustFile> yustFilesFromJson(
      List<Map<String, String?>> jsonFiles, String storageFolderPath) {
    return jsonFiles
        .map((f) => YustFile.fromJson(f)..storageFolderPath = storageFolderPath)
        .toList();
  }

  List<Map<String, dynamic>> yustFilesToJson(List<YustFile> yustFiles) {
    return yustFiles.map((f) => f.toJson()).toList();
  }

  /// works for cacheable and non-cacheable files
  void _mergeIntoYustFiles(List<YustFile> yustFiles, List<YustFile> newFiles) {
    for (final newFile in newFiles) {
      if (!yustFiles.any((yustFile) {
        var nameEQ = yustFile.name == newFile.name;
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
    var devicePath = await _getDirectory(yustFile);

    yustFile.devicePath = devicePath + '${yustFile.name}';

    await yustFile.file!.copy(yustFile.devicePath!);
    final cachedFileList = getCachedFiles();
    cachedFileList.add(yustFile);
    await _saveCachedFiles(cachedFileList);
    //TODO offline: _saveCachedFile, takes getCachedFiles, use devicePathAttribute!

    //TODO offline: check if List<YustFile> as attribute are necessary
  }

  Future<String> _getDirectory(YustFile yustFile) async {
    final tempDir = await getTemporaryDirectory();

    var devicePath = '${tempDir.path}/${yustFile.storageFolderPath}/';

    if (!Directory(devicePath).existsSync()) {
      await Directory(devicePath).create(recursive: true);
    }

    return devicePath;
  }

  Future<void> _uploadFileToStorage(YustFile yustFile) async {
    if (yustFile.storageFolderPath == null) {
      throw (YustException(
          'Can not upload file. The storage folder path is missing.'));
    }
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw ('No internet connection.');
    }

    if (yustFile.cached) {
      if (await _isFileInCache(yustFile)) {
        yustFile.file = File(yustFile.devicePath!);
      } else {
        //returns without upload, because file is missing in cache
        return;
      }
    }

    final url = await Yust.fileService.uploadFile(
      path: yustFile.storageFolderPath!,
      name: yustFile.name!,
      file: yustFile.file,
      bytes: yustFile.bytes,
    );
    yustFile.url = url;

    if (yustFile.cached) await _updateDocAttribute(yustFile, url);
    // if (onFileUploaded != null) {
    //   onFileUploaded!();
    // }
  }

  Future<void> _updateDocAttribute(YustFile cachedFile, String url) async {
    var attribute = await _getDocAttribute(cachedFile);

    if (attribute is Map) {
      if (attribute['url'] == null) {
        attribute['name'] = cachedFile.name;
        attribute['url'] = url;
      } else {
        // edge case: image picker changes from single- to multi-image view
        attribute = [attribute];
      }
    }
    if (attribute is List) {
      attribute.removeWhere((f) => f['name'] == cachedFile.name);
      attribute.add({'name': cachedFile.name, 'url': url});
    }

    attribute ??= [
      {'name': cachedFile.name, 'url': url}
    ];

    await FirebaseFirestore.instance
        .doc(cachedFile.linkedDocPath!)
        .update({cachedFile.linkedDocAttribute!: attribute});
  }

  Future<dynamic> _getDocAttribute(YustFile yustFile) async {
    // ignore: inference_failure_on_uninitialized_variable
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
      await Yust.fileService
          .deleteFile(path: yustFile.storageFolderPath!, name: yustFile.name!);
      // .timeout(Duration(seconds: 20));
      //TODO offline: Testen ohne TimeOut
    }
  }

  Future<void> _deleteFileFromCache(YustFile yustFile) async {
    var cachedFiles = getCachedFiles();
    if (yustFile.devicePath != null &&
        File(yustFile.devicePath!).existsSync()) {
      await File(yustFile.devicePath!).delete();
    }

    cachedFiles.removeWhere((f) => f.devicePath == yustFile.devicePath);
    await _saveCachedFiles(cachedFiles);
  }

  /// Loads a list of all cached [YustFile]s.
  Future<List<YustFile>> _loadCachedFiles() async {
    var prefs = await SharedPreferences.getInstance();
    var temporaryJsonFiles = prefs.getString('YustCachedFiles') ?? '[]';

    var cachedFiles = <YustFile>[];
    jsonDecode(temporaryJsonFiles).forEach(
        (fileJson) => cachedFiles.add(YustFile.fromLocalJson(fileJson)));

    return cachedFiles;
  }

  /// Saves all cached [YustFile]s.
  Future<void> _saveCachedFiles(List<YustFile> yustFiles) async {
    var prefs = await SharedPreferences.getInstance();
    var jsonFiles = yustFiles.map((file) => file.toLocalJson()).toList();
    await prefs.setString('YustCachedFiles', jsonEncode(jsonFiles));
  }

  Future<void> _launchBrowser(YustFile file) async {
    if (await canLaunch(file.url ?? '')) {
      await launch(file.url ?? '');
    } else {
      throw YustException('Die Datei kann nicht geöffnet werden.');
    }
  }

  /// Checks the cached files for corruption and deletes them if necessary.
  Future<void> _validateCachedFiles() async {
    var cachedFiles = getCachedFiles();
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
    return (reuploadTime * _reuploadFactor) > Duration(minutes: 10)
        ? Duration(minutes: 10)
        : reuploadTime * _reuploadFactor;
  }

  Future<bool> _isFileInCache(YustFile yustFile) async {
    return yustFile.devicePath != null &&
        await File(yustFile.devicePath!).exists();
  }
}
