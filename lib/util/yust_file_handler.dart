import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/util/yust_offline_cache.dart';
import 'package:yust/yust.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class YustFileHandler {
  final String folderPath;
  List<YustFile> _files;
  final void Function(List<YustFile> images) onChanged;
  final Function(List<YustFile>) changeCallback;
  YustFileHandler(
    this._files,
    this.folderPath,
    this.onChanged,
    this.changeCallback,
  );

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
        _files.remove(file);

        changeCallback(_files);
        onChanged(_files);
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
        _files.remove(file);
        changeCallback(_files);
        onChanged(_files);
      }
    }
  }
}
