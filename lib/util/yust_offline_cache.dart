import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/src/iterable_extensions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yust/models/yust_doc.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/models/yust_local_file.dart';
import 'package:yust/yust.dart';

class YustOfflineCache {
  /// shows if the _uploadFiles-procces is currently running
  static bool _uploadingTemporaryFiles = false;

  /// Steadily increasing by the [_reconnectionFactor]. Indicates the next upload attempt.
  /// [_reconnectionTime] is reset for each upload
  static Duration _reconnectionTime = new Duration(milliseconds: 250);
  static double _reconnectionFactor = 1.25;

  /// Uploads all local files. If the upload fails,  a new attempt is made after [_reconnectionTime].
  /// Can be started only once, renewed call only possible after successful upload.
  /// [validateLocalFiles] can delete files added shortly before if they are not yet
  /// entered in the database. Check this before!
  static uploadLocalFiles({bool validateLocalFiles = true}) async {
    if (!_uploadingTemporaryFiles) {
      if (validateLocalFiles) await YustOfflineCache.validateLocalFiles();
      _uploadingTemporaryFiles = true;
      _uploadFiles(_reconnectionTime);
    }
  }

  static Future<String?> _uploadFiles(Duration reconnectionTime) async {
    var localFiles = await getLocalFiles();
    bool uploadError = false;

    //TODO yust_file_handler - merging of file and image picker inkl. callbacks

    for (final localFile in localFiles) {
      try {
        if (_isFileInCache(localFile.devicePath)) {
          final doc = await FirebaseFirestore.instance
              .doc(localFile.linkedDocPath)
              .get();
          if (doc.exists && doc.data() != null) {
            final attribute = doc.get(localFile.linkedDocAttribute);
            //TODO offline wenn image Picker nur ein Bild erlaubt, funktionier der Upload nicht da Attribut an Stelle [localFile.docAttribute] fehlt.

            String url = await Yust.service.uploadFile(
              path: localFile.devicePath,
              name: localFile.name,
              file: File(localFile.devicePath),
            );

            _updateAttribute(attribute, localFile, url);

            await deleteLocalFile(localFile.name);
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
      } catch (e) {
        uploadError = true;
      }
    }
    if (!uploadError) {
      _uploadingTemporaryFiles = false;
    } else {
      Future.delayed(reconnectionTime, () {
        //Limits [reconnectionTime] to 5 minutes
        reconnectionTime = reconnectionTime > Duration(minutes: 5)
            ? Duration(minutes: 5)
            : reconnectionTime * _reconnectionFactor;
        _uploadFiles(reconnectionTime);
      });
    }
  }

  /// Attention! Writes in the local file.url the folder path!
  /// Checks the local files for corruption and deletes them if necessary.
  static Future<void> validateLocalFiles() async {
    var localFiles = await getLocalFiles();

    var validatedLocalFiles = localFiles
        .where((localFile) => _isFileInCache(localFile.devicePath))
        .toList();

    // save all local files, which are completely available
    // do not save files whose data no longer exists
    _saveLocalFiles(validatedLocalFiles);

    // Checks if all required database addresses are initialized.
    for (var localFile in validatedLocalFiles) {
      final doc =
          await FirebaseFirestore.instance.doc(localFile.linkedDocPath).get();
      if (!doc.exists || doc.data() == null) {
        await deleteLocalFile(localFile.name);
        await validateLocalFiles();
      }
    }
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
        storageFolderPath: folderPath,
        linkedDocPath: pathToDoc,
        linkedDocAttribute: docAttribute,
        devicePath: path);

    var temporaryFiles = await YustOfflineCache.getLocalFiles();
    temporaryFiles.add(localFile);
    await YustOfflineCache._saveLocalFiles(temporaryFiles);
    return path;
  }

  /// removes the file and the file data from the local cache
  static Future<void> deleteLocalFile(String fileName) async {
    var localFiles = await getLocalFiles();

    var localFile =
        localFiles.firstWhereOrNull((localFile) => localFile.name == fileName);

    if (localFile != null) {
      if (_isFileInCache(localFile.devicePath)) {
        File(localFile.devicePath).delete();
      }
      localFiles.remove(localFile);
      await _saveLocalFiles(localFiles);
    }
  }

  static Future<void> _updateAttribute(
      attribute, YustLocalFile localFile, String url) async {
    if (attribute is Map) {
      attribute['name'] = localFile.name;
      attribute['url'] = url;
    } else if (attribute is List) {
      attribute.add({'name': localFile.name, 'url': url});
    }

    await FirebaseFirestore.instance
        .doc(localFile.linkedDocPath)
        .update({localFile.linkedDocAttribute: attribute});
  }

  /// reads local file cache, returns list with [YustLocalFile]'s
  static Future<List<YustLocalFile>> getLocalFiles() async {
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

  static bool _isFileInCache(String? path) {
    return path != null && File(path).existsSync();
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
