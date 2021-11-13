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
  static bool uploadingTemporaryFiles = false;
  static Duration reconnectionTime = new Duration(milliseconds: 250);
  static uploadLocalFiles() {
    if (!uploadingTemporaryFiles) {
      uploadingTemporaryFiles = true;
      _uploadFiles(reconnectionTime);
    }
  }

  static Future<String?> _uploadFiles(Duration reconnectionTime) async {
    var localFiles = await getLocalFiles();
    try {
      for (final localFile in localFiles) {
        // is there a fitting picture in the local cache?
        if (isFileInCache(localFile.localPath)) {
          final doc =
              await FirebaseFirestore.instance.doc(localFile.pathToDoc).get();
          if (doc.exists && doc.data() != null) {
            final attribute = doc.get(localFile.docAttribute);

            // Attribute can be list or map, that is why the complex query is used
            bool valideFile = false;
            int? index = null;
            valideFile =
                (attribute is Map && attribute['name'] == localFile.name);
            if (!valideFile && attribute is List) {
              index = attribute.indexWhere((onlineFile) =>
                  YustFile.fromJson(onlineFile).name == localFile.name);
              if (index >= 0) valideFile = true;
            }
            if (valideFile) {
              String url = await Yust.service.uploadFile(
                path: localFile.localPath,
                name: localFile.name,
                file: File(localFile.localPath),
              );

              // removes the 'local' tag from name and adds url
              if (attribute is Map) {
                attribute['name'] = localFile.name.substring(5);
                attribute['url'] = url;
              } else if (attribute is List) {
                attribute[index!] = {
                  'name': localFile.name.substring(5),
                  'url': url
                };
              }
              await FirebaseFirestore.instance
                  .doc(localFile.pathToDoc)
                  .update({localFile.docAttribute: attribute});

              // File was uploaded successfully. Remove file from cache.
              await deleteLocalFile(localFile.name);
            } else {
              throw new Exception();
            }
          } else {
            throw new Exception(
                'database entry did not exist. Try again in a moment.');
          }
        } else {
          //removing file data, because file is missing in local cache
          await deleteLocalFile(localFile.name);
        }
      }
      uploadingTemporaryFiles = false;
    } catch (e) {
      Future.delayed(reconnectionTime, () {
        reconnectionTime = reconnectionTime > Duration(minutes: 5)
            ? Duration(minutes: 5)
            : reconnectionTime * 1.25;
        print('next upload in:' + reconnectionTime.toString());
        _uploadFiles(reconnectionTime);
      });
    }
  }

  static Future<void> validateLocalFiles() async {
    var localFiles = await getLocalFiles();

    var validatedLocalFiles = localFiles
        .where((localFile) => isFileInCache(localFile.localPath))
        .toList();

    // overriding the old informations
    saveLocalFiles(validatedLocalFiles);

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
        // removes file data, because pathToDoc in Database didnt exist
        //TODO: offline: Files die auf eine ungültige Addresse in der DB schreiben wollen, werden gelöscht?
        await deleteLocalFile(localFile.name);
        await validateLocalFiles();
        throw new Exception(
            'FirebaseException: Cannot find the expected DocumentSnapshot!');
      }
    }
  }

  /// reads local file cache, returns list with files or null
  static Future<List<YustLocalFile>> getLocalFiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var temporaryJsonFiles = prefs.getString('temporaryImages');
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

  /// saves the data from images locally
  static Future<void> saveLocalFiles(List<YustLocalFile> files) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var jsonList = files.map((file) => file.toJson()).toList();
    await prefs.setString('temporaryImages', jsonEncode(jsonList));
  }

  /// returns local path from [localFile]
  static Future<String> saveFileTemporary({
    required YustFile file,
    required String folderPath,
    required String pathToDoc,
    required String docAttribute,
  }) async {
    final tempDir = await getTemporaryDirectory();
    String path = '${tempDir.path}/${file.name}';
    // save new image in cache
    file.file!.copy(path);

    var localFile = new YustLocalFile(
        name: file.name,
        folderPath: folderPath,
        pathToDoc: pathToDoc,
        docAttribute: docAttribute,
        localPath: path);

    var temporaryFiles = await YustOfflineCache.getLocalFiles();
    temporaryFiles.add(localFile);
    await YustOfflineCache.saveLocalFiles(temporaryFiles);
    return path;
  }

  /// removes the image and the image data from the local cache
  static Future<void> deleteLocalFile(String fileName) async {
    var localFiles = await getLocalFiles();

    //removing image
    var localFile =
        localFiles.firstWhereOrNull((localFile) => localFile.name == fileName);
    if (localFile != null) {
      if (isFileInCache(localFile.localPath)) {
        File(localFile.localPath).delete();
      }
      //removing image data
      localFiles.remove(localFile);
      await saveLocalFiles(localFiles);
    }
  }

  static bool isFileInCache(String? path) {
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

  static bool isLocalPath(String path) {
    return !Uri.parse(path).isAbsolute;
  }

  static bool isLocalFile(String fileName) {
    return fileName.substring(0, 5) == 'local';
  }

  static Future<String?> getLocalPath(String fileName) async {
    final localFiles = await YustOfflineCache.getLocalFiles();
    final localFile =
        localFiles.firstWhereOrNull((localFile) => localFile.name == fileName);
    return localFile == null ? null : localFile.localPath;
  }
}
