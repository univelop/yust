import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/util/yust_file_handler.dart';
import 'package:yust/yust.dart';

class YustOfflineCache {
  /// shows if the _uploadFiles-procces is currently running
  static bool _uploadingCachedFiles = false;

  /// Steadily increasing by the [_reconnectionFactor]. Indicates the next upload attempt.
  /// [_reconnectionTime] is reset for each upload
  static Duration _reconnectionTime = new Duration(milliseconds: 250);
  static double _reconnectionFactor = 1.25;

  /// Uploads all cached files. If the upload fails,  a new attempt is made after [_reconnectionTime].
  /// Can be started only once, renewed call only possible after successful upload.
  /// [validateCachedFiles] can delete files added shortly before if they are not yet
  /// entered in the database. Check this before!
  static uploadcachedFiles({bool validateCachedFiles = true}) async {
    final _fileHandler = new YustFileHandler(callback: () {});
    if (!_uploadingCachedFiles) {
      if (validateCachedFiles)
        await YustOfflineCache.validateCachedFiles(_fileHandler);
      _uploadingCachedFiles = true;
      _uploadFiles(_reconnectionTime, _fileHandler);
    }
  }

  static Future<String?> _uploadFiles(
      Duration reconnectionTime, YustFileHandler fileHandler) async {
    var cachedFiles = await fileHandler.getCachedFiles();

    bool uploadError = false;

    for (final cachedFile in cachedFiles) {
      try {
        if (_isFileInCache(cachedFile.devicePath)) {
          final doc = await FirebaseFirestore.instance
              .doc(cachedFile.linkedDocPath!)
              .get();
          if (doc.exists && doc.data() != null) {
            var attribute;
            try {
              attribute = doc.get(cachedFile.linkedDocAttribute!);
            } catch (e) {
              // edge case, image picker allows only one image, attribute must be initialized manually
              attribute = {'name': '', 'url': null};
            }
            String url = await Yust.service.uploadFile(
              path: cachedFile.devicePath!,
              name: cachedFile.name,
              file: File(cachedFile.devicePath!),
            );

            _updateAttribute(attribute, cachedFile, url);
            await fileHandler.deleteFileFromCache(cachedFile);
          } else {
            // It is possible that the upload accesses the database before the searched address is initialized.
            // If the access adress is corrupt, the process 'validateLocalFiles' removes the file.
            throw new Exception(
                'Database entry did not exist. Try again in a moment.');
          }
        } else {
          //removing file data, because file is missing in cache

          await fileHandler.deleteFile(cachedFiles, cachedFile);
        }
      } catch (e) {
        uploadError = true;
      }
    }
    if (!uploadError) {
      _uploadingCachedFiles = false;
    } else {
      Future.delayed(reconnectionTime, () {
        //Limits [reconnectionTime] to 5 minutes
        reconnectionTime = reconnectionTime > Duration(minutes: 5)
            ? Duration(minutes: 5)
            : reconnectionTime * _reconnectionFactor;
        _uploadFiles(reconnectionTime, fileHandler);
      });
    }
  }

  /// Attention! Writes in the local file.url the folder path!
  /// Checks the cached files for corruption and deletes them if necessary.
  static Future<void> validateCachedFiles(YustFileHandler fileHandler) async {
    var cachedFiles = await fileHandler.getCachedFiles();

    var validatedLocalFiles = cachedFiles
        .where((cachedFile) =>
            _isFileInCache(cachedFile.devicePath) && cachedFile.cacheable)
        .toList();

    // save all cached files, which are completely available
    // do not save files whose data no longer exists
    await fileHandler.saveCachedFiles(validatedLocalFiles);

    // Checks if all required database addresses are initialized.
    for (var cachedFile in validatedLocalFiles) {
      final doc =
          await FirebaseFirestore.instance.doc(cachedFile.linkedDocPath!).get();
      if (!doc.exists || doc.data() == null) {
        await fileHandler.deleteFile(validatedLocalFiles, cachedFile);
      }
    }
  }

  static Future<void> _updateAttribute(
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

  static bool _isFileInCache(String? path) {
    return path != null && File(path).existsSync();
  }
}
