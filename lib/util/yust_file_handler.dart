import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
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
  bool _uploadingCachedFiles = false;

  /// Steadily increasing by the [_reuploadFactor]. Indicates the next upload attempt.
  /// [_reuploadTime] is reset for each upload
  final Duration _reuploadTime = Duration(milliseconds: 250);
  final double _reuploadFactor = 1.25;

  final List<YustFile> _yustFiles = [];

  final List<YustFile> _recentlyUploadedFiles = [];

  final List<YustFile> _recentlyDeletedFiles = [];

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
    _removeLocalDeletedFiles(onlineFiles);
    _removeOnlineDeletedFiles(onlineFiles);

    _mergeOnlineFiles(_yustFiles, onlineFiles, storageFolderPath);
    await _mergeCachedFiles(_yustFiles, linkedDocPath, linkedDocAttribute);

    if (loadFiles) _loadFiles();
  }

  void _removeOnlineDeletedFiles(List<YustFile> onlineFiles) {
    // to be up to date with the storage files, onlineFiles get merged which file that are:
    // 1. cached
    // 2. recently uploaded and not in the [onlineFiles]
    // 3. recently added and not cached (url == null)
    getOnlineFiles().forEach((file) {
      if (onlineFiles.any((oFile) => oFile.name == file.name)) {
        _recentlyUploadedFiles.remove(file);
      } else if (!file.cached &&
          file.url != null &&
          !_recentlyUploadedFiles.contains(file)) {
        _yustFiles.remove(file);
      }
    });
  }

  void _removeLocalDeletedFiles(List<YustFile> onlineFiles) {
    var _copyRecentlyDeletedFiles = _recentlyDeletedFiles;
    onlineFiles.removeWhere((f) {
      if (_recentlyDeletedFiles
          .any((deletedFile) => deletedFile.url == f.url)) {
        _copyRecentlyDeletedFiles.remove(f);
        return true;
      }
      return false;
    });
    _recentlyDeletedFiles
        .removeWhere((f) => !_copyRecentlyDeletedFiles.contains(f));
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
      var cachedFiles = await loadCachedFiles();
      cachedFiles = cachedFiles
          .where((yustFile) =>
              yustFile.linkedDocPath == linkedDocPath &&
              yustFile.linkedDocAttribute == linkedDocAttribute)
          .toList();

      _mergeIntoYustFiles(yustFiles, cachedFiles);
    }
  }

  Future<void> addFile(YustFile yustFile) async {
    if (yustFile.name == null || yustFile.storageFolderPath == null) {
      throw ('The file needs a name and a storageFolderPath to perform an upload!');
    }

    _yustFiles.add(yustFile);
    if (!kIsWeb && yustFile.cacheable) {
      await _saveFileOnDevice(yustFile);
      startUploadingCachedFiles();
    } else {
      await _uploadFileToStorage(yustFile);
    }
  }

  /// if online files get deleted while the device is offline, error is thrown
  Future<void> deleteFile(YustFile yustFile) async {
    if (yustFile.cached) {
      await _deleteCachedInformations(yustFile);
    } else {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw ('No internet connection.');
      }
      try {
        await _deleteFileFromStorage(yustFile);
        _recentlyDeletedFiles.add(yustFile);
        // ignore: empty_catches
      } catch (e) {}
    }
    _yustFiles.removeWhere((f) => f.name == yustFile.name);
  }

  void startUploadingCachedFiles() {
    if (!_uploadingCachedFiles) {
      _uploadingCachedFiles = true;
      _uploadCachedFiles(_reuploadTime);
    }
  }

  Future<void> _uploadCachedFiles(Duration reuploadTime) async {
    await _validateCachedFiles();
    var cachedFiles = getCachedFiles();
    var length = cachedFiles.length;
    var uploadedFiles = 0;
    var uploadError = false;
    for (final yustFile in cachedFiles) {
      yustFile.lastError = null;
      try {
        await _uploadFileToStorage(yustFile);
        uploadedFiles++;
        await _deleteCachedInformations(yustFile);
        if (onFileUploaded != null) onFileUploaded!();
      } catch (error) {
        print(error.toString());
        yustFile.lastError = error.toString();
        uploadError = true;
      }
    }

    if (length < uploadedFiles + getCachedFiles().length) {
      // retry upload with reseted uploadTime, because new files where added
      uploadError = true;
      reuploadTime = _reuploadTime;
    }

    if (!uploadError) {
      _uploadingCachedFiles = false;
    } else {
      // saving cachedFiles, to store error log messages
      await _saveCachedFiles();

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

  /// works for cacheable and non-cacheable files
  void _mergeIntoYustFiles(List<YustFile> yustFiles, List<YustFile> newFiles) {
    for (final newFile in newFiles) {
      if (!yustFiles.any((yustFile) => _equalFiles(yustFile, newFile))) {
        yustFiles.add(newFile);
      }
    }
  }

  bool _equalFiles(YustFile yustFile, YustFile newFile) {
    var nameEQ = yustFile.name == newFile.name;
    if (yustFile.cacheable && newFile.cacheable) {
      return nameEQ &&
          yustFile.linkedDocPath == newFile.linkedDocPath &&
          yustFile.linkedDocAttribute == newFile.linkedDocAttribute;
    }
    return nameEQ;
  }

  Future<void> _saveFileOnDevice(YustFile yustFile) async {
    var devicePath = await _getDirectory(yustFile);

    yustFile.devicePath = devicePath + '${yustFile.name}';

    if (yustFile.bytes != null) {
      yustFile.file =
          await File(yustFile.devicePath!).writeAsBytes(yustFile.bytes!);
    } else if (yustFile.file != null) {
      await yustFile.file!.copy(yustFile.devicePath!);
    }

    await _saveCachedFiles();
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
    _recentlyUploadedFiles.add(yustFile);
  }

  Future<void> _updateDocAttribute(YustFile cachedFile, String url) async {
    var attribute = await _getDocAttribute(cachedFile);

    var fileData = _getFileData(cachedFile.name!, attribute);
    fileData = Map<String, dynamic>.from(mergeMaps(
        fileData, cachedFile.additionalDocAttributeData ?? {}, value: (m0, m1) {
      return m1;
    }));

    fileData['name'] = cachedFile.name;
    fileData['url'] = url;

    if (attribute is Map) {
      if (attribute['url'] == null) {
        attribute = fileData;
      } else {
        // edge case: image picker changes from single- to multi-image view
        attribute = [fileData];
      }
    }
    if (attribute is List) {
      attribute.removeWhere((f) => f['name'] == cachedFile.name);
      attribute.add(fileData);
    }

    attribute ??= [fileData];

    await FirebaseFirestore.instance
        .doc(cachedFile.linkedDocPath!)
        .update({cachedFile.linkedDocAttribute!: attribute});
  }

  Map<dynamic, dynamic> _getFileData(String fileName, dynamic attribute) {
    if (attribute is Map) {
      return attribute;
    }
    if (attribute is List) {
      var result = attribute.firstWhereOrNull((f) {
        if (f['name'] == null) {
          return false;
        }
        return f['name'] == fileName;
      });
      return result ?? {};
    }
    return {};
  }

  Future<dynamic> _getDocAttribute(YustFile yustFile) async {
    // ignore: inference_failure_on_uninitialized_variable
    var attribute;
    final doc = await getFirebaseDoc(yustFile.linkedDocPath!);

    if (existsDocData(doc)) {
      try {
        attribute = doc.get(yustFile.linkedDocAttribute!);
      } catch (e) {
        // edge case, image picker allows only one image, attribute must be initialized manually
        attribute = {'name': yustFile.name, 'url': null};
      }
    }
    return attribute;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getFirebaseDoc(
      String linkedDocPath) async {
    return await FirebaseFirestore.instance
        .doc(linkedDocPath)
        .get(GetOptions(source: Source.server));
  }

  bool existsDocData(DocumentSnapshot<Map<String, dynamic>> doc) {
    return doc.exists && doc.data() != null;
  }

  Future<void> _deleteFileFromStorage(YustFile yustFile) async {
    if (yustFile.storageFolderPath != null) {
      await Yust.fileService
          .deleteFile(path: yustFile.storageFolderPath!, name: yustFile.name!);
    }
  }

  /// deletes cached file and devicepath. File is no longer cached
  Future<void> _deleteCachedInformations(YustFile yustFile) async {
    if (yustFile.devicePath != null &&
        File(yustFile.devicePath!).existsSync()) {
      await File(yustFile.devicePath!).delete();
    }
    yustFile.devicePath = null;
    yustFile.file = null;

    await _saveCachedFiles();
  }

  /// Loads a list of all cached [YustFile]s.
  static Future<List<YustFile>> loadCachedFiles() async {
    var prefs = await SharedPreferences.getInstance();
    var temporaryJsonFiles = prefs.getString('YustCachedFiles') ?? '[]';

    var cachedFiles = <YustFile>[];
    jsonDecode(temporaryJsonFiles).forEach((dynamic fileJson) =>
        cachedFiles.add(YustFile.fromLocalJson(fileJson)));

    return cachedFiles;
  }

  /// Saves all cached [YustFile]s.
  Future<void> _saveCachedFiles() async {
    var yustFiles = getCachedFiles();
    var cachedFiles = await loadCachedFiles();

    // only change the files from THIS filehandler (identity: linkedDocPath and -Attribute)
    cachedFiles.removeWhere(((yustFile) =>
        yustFile.linkedDocPath == linkedDocPath &&
        yustFile.linkedDocAttribute == linkedDocAttribute));
    cachedFiles.addAll(yustFiles);

    var jsonFiles = cachedFiles.map((file) => file.toLocalJson()).toList();

    var prefs = await SharedPreferences.getInstance();
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
        await deleteFile(cachedFile);
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
