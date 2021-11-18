import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yust/models/yust_doc.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/yust.dart';

class YustOfflineCache {
  /// shows if the _uploadFiles-procces is currently running
  static bool _uploadingTemporaryFiles = false;

  /// Steadily increasing by the [_reconnectionFactor]. Indicates the next upload attempt.
  /// [_reconnectionTime] is reset for each upload
  static Duration _reconnectionTime = new Duration(milliseconds: 250);
  static double _reconnectionFactor = 1.25;

  /// Uploads all local files. If the upload fails,  a new attempt is made after [_reconnectionTime].
  /// Can be started only once, renewed call only possible after successful upload
  static uploadLocalFiles() {
    if (!_uploadingTemporaryFiles) {
      _uploadingTemporaryFiles = true;
      _uploadFiles(_reconnectionTime);
    }
  }

  static Future<String?> _uploadFiles(Duration reconnectionTime) async {
    var localFiles = await _getLocalFiles();
    try {
      for (final localFile in localFiles) {
        if (_isFileInCache(localFile.localPath)) {
          final doc =
              await FirebaseFirestore.instance.doc(localFile.pathToDoc).get();
          if (doc.exists && doc.data() != null) {
            final attribute = doc.get(localFile.docAttribute);

            int index = _getFileIndex(attribute, localFile);

            if (index >= 0) {
              String url = await Yust.service.uploadFile(
                path: localFile.localPath,
                name: localFile.name,
                file: File(localFile.localPath),
              );

              _updateAttribute(attribute, localFile, url, index);

              await deleteLocalFile(localFile.name);
            } else {
              // It is possible that the upload accesses the database before the searched address is initialized.
              // If the access adress is corrupt, the process 'validateLocalFiles' removes the file.
              throw new Exception(
                  'Database entry did not exist. Try again in a moment.');
            }
          } else {
            // It is possible that the upload accesses the database before the searched address is initialized.
            // If the access adress is corrupt, the process 'validateLocalFiles' removes the file.
            throw new Exception(
                'Database entry did not exist. Try again in a moment.');
          }
        } else {
          //removing file data, because file is missing in local cache
          await deleteLocalFile(localFile.name);
        }
      }
      _uploadingTemporaryFiles = false;
    } catch (e) {
      Future.delayed(reconnectionTime, () {
        //Limits [reconnectionTime] to 5 minutes
        reconnectionTime = reconnectionTime > Duration(minutes: 5)
            ? Duration(minutes: 5)
            : reconnectionTime * _reconnectionFactor;
        print('OfflineCache: Next upload in:' + reconnectionTime.toString());
        _uploadFiles(reconnectionTime);
      });
    }
  }

  /// Attention! Writes in the local file.url the folder path!
  /// Checks the local files for corruption and deletes them if necessary.
  static Future<void> validateLocalFiles() async {
    var localFiles = await _getLocalFiles();

    var validatedLocalFiles = localFiles
        .where((localFile) => _isFileInCache(localFile.localPath))
        .toList();

    // save all local files, which are completely available
    // do not save files whose data no longer exists
    _saveLocalFiles(validatedLocalFiles);

    // Checks if all required database addresses are initialized.
    for (var localFile in validatedLocalFiles) {
      final doc =
          await FirebaseFirestore.instance.doc(localFile.pathToDoc).get();
      if (doc.exists && doc.data() != null) {
        final attribute = doc.get(localFile.docAttribute); // as List;
        if (attribute is Map) {
          if (attribute['name'] != localFile.name) {
            deleteLocalFile(localFile.name);
          }
        }
        if (attribute is List) {
          var index = attribute.indexWhere((onlineFile) =>
              YustFile.fromJson(onlineFile).name == localFile.name);
          if (index == -1) {
            deleteLocalFile(localFile.name);
          }
        }
      } else {
        await deleteLocalFile(localFile.name);
        await validateLocalFiles();

        print('OfflineCache: ERROR: File ' +
            localFile.name +
            ' got deleted. Firebase Database adress ' +
            localFile.pathToDoc +
            ' did not exist!');
      }
    }
  }

  /// checks if the loaded [files] are outdated in comparison to [uploadedFiles]
  /// and loads the [files] that are cached locally.
  static Future<List<YustFile>> loadFiles(
      {required List<YustFile> uploadedFiles,
      required List<YustFile> files,
      Future<YustFile> Function(YustFile file)? ifFileIsNotInCache}) async {
    // checks if the loaded [files] are outdated in comparison to [uploadedFiles]
    for (var upFile in uploadedFiles) {
      var uploadedFile =
          files.indexWhere((file) => file.name.substring(5) == upFile.name);
      if (uploadedFile >= 0) {
        files[uploadedFile] = upFile;
      }
    }

    // loads the local files and paths
    // path get saved in url
    for (var file in files) {
      if (YustOfflineCache.isLocalPath(file.url ?? '') || file.url == null) {
        final path = await YustOfflineCache._getLocalPath(file.name);
        if (YustOfflineCache._isFileInCache(path)) {
          file.file = File(path!);
          file.url = path;
        } else {
          if (ifFileIsNotInCache != null) {
            file = await ifFileIsNotInCache(file);
          }
        }
      }
    }
    return files;
  }

  /// returns local path from [file]
  static Future<String> saveFileTemporary({
    required YustFile file,
    required String folderPath,
    required String pathToDoc,
    required String docAttribute,
  }) async {
    final tempDir = await getTemporaryDirectory();
    String path = '${tempDir.path}/${file.name}';
    // save new file in cache
    file.file!.copy(path);

    var localFile = new YustLocalFile(
        name: file.name,
        folderPath: folderPath,
        pathToDoc: pathToDoc,
        docAttribute: docAttribute,
        localPath: path);

    var temporaryFiles = await YustOfflineCache._getLocalFiles();
    temporaryFiles.add(localFile);
    await YustOfflineCache._saveLocalFiles(temporaryFiles);
    return path;
  }

  /// removes the file and the file data from the local cache
  static Future<void> deleteLocalFile(String fileName) async {
    var localFiles = await _getLocalFiles();

    var localFile =
        localFiles.firstWhereOrNull((localFile) => localFile.name == fileName);

    if (localFile != null) {
      if (_isFileInCache(localFile.localPath)) {
        File(localFile.localPath).delete();
      }
      localFiles.remove(localFile);
      await _saveLocalFiles(localFiles);
    }
  }

  /// removes the 'local' tag from name and adds the url
  static Future<void> _updateAttribute(
      attribute, YustLocalFile localFile, String url, int index) async {
    if (attribute is Map) {
      attribute['name'] = localFile.name.substring(5);
      attribute['url'] = url;
    } else if (attribute is List) {
      attribute[index] = {'name': localFile.name.substring(5), 'url': url};
    }

    await FirebaseFirestore.instance
        .doc(localFile.pathToDoc)
        .update({localFile.docAttribute: attribute});
  }

  ///If the file has a valid index, a corresponding instance exists in the database.
  /// returns -1 if the file is not valide
  static int _getFileIndex(attribute, YustLocalFile localFile) {
    int index =
        (attribute is Map && attribute['name'] == localFile.name) ? 0 : -1;
    if (attribute is List) {
      index = attribute.indexWhere(
          (onlineFile) => YustFile.fromJson(onlineFile).name == localFile.name);
    }
    return index;
  }

  /// reads local file cache, returns list with [YustLocalFile]'s
  static Future<List<YustLocalFile>> _getLocalFiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var temporaryJsonFiles = prefs.getString('temporaryFiles');
    List<YustLocalFile> temporaryFiles = [];
    if (temporaryJsonFiles != null &&
        temporaryJsonFiles != '[]' &&
        temporaryJsonFiles != '') {
      temporaryFiles = jsonDecode(temporaryJsonFiles)
          .map<YustLocalFile>((file) => YustLocalFile.fromJson(file))
          .toList();
    }

    return temporaryFiles;
  }

  /// saves the data from files locally
  static Future<void> _saveLocalFiles(List<YustLocalFile> files) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var jsonList = files.map((file) => file.toJson()).toList();
    await prefs.setString('temporaryFiles', jsonEncode(jsonList));
  }

  static bool isLocalPath(String path) {
    return !Uri.parse(path).isAbsolute;
  }

  static bool isLocalFile(String fileName) {
    return fileName.substring(0, 5) == 'local';
  }

  static bool _isFileInCache(String? path) {
    return path != null && File(path).existsSync();
  }

  static Future<String?> _getLocalPath(String fileName) async {
    final localFiles = await YustOfflineCache._getLocalFiles();
    final localFile =
        localFiles.firstWhereOrNull((localFile) => localFile.name == fileName);
    return localFile == null ? null : localFile.localPath;
  }

  static dynamic jsonDecode(String jsonString) {
    if (jsonString == '') {
      return null;
    }
    return json.decode(jsonString, reviver: (key, item) {
      item = decodeDateTime(key, item);
      item = YustDoc.convertTimestamp(item);
      return item;
    });
  }

  static dynamic encodeDateTime(dynamic item) {
    if (item is DateTime) {
      return item.toIso8601String();
    }
    return item;
  }

  static dynamic decodeDateTime(dynamic key, dynamic item) {
    if (item is String) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(item)) {
        final dateTime = DateTime.tryParse(item);
        if (dateTime != null) {
          return dateTime;
        }
      }
    }
    return item;
  }
}
