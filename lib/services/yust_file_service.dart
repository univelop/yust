import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image_lib;
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yust/util/yust_exception.dart';
import 'package:universal_html/html.dart' as html;

import '../yust.dart';

class YustFileService {
  firebase_storage.FirebaseStorage fireStorage;

  YustFileService() : fireStorage = firebase_storage.FirebaseStorage.instance;

  YustFileService.mocked() : fireStorage = MockFirebaseStorage();

  Future<String> uploadFile(
      {required String path,
      required String name,
      File? file,
      Uint8List? bytes}) async {
    try {
      final storageReference = fireStorage.ref().child(path).child(name);
      firebase_storage.UploadTask uploadTask;
      if (file != null) {
        uploadTask = storageReference.putFile(file);
      } else {
        var metadata = firebase_storage.SettableMetadata(
          contentType: lookupMimeType(name),
        );
        uploadTask = storageReference.putData(bytes!, metadata);
      }
      await uploadTask;
      return await storageReference.getDownloadURL();
    } catch (error) {
      throw YustException('Fehler beim Upload: ' + error.toString());
    }
  }

  Future<Uint8List?> downloadFile(
      {required String path, required String name}) async {
    try {
      return await fireStorage
          .ref()
          .child(path)
          .child(name)
          .getData(5 * 1024 * 1024);
    } catch (e) {
      return Uint8List(0);
    }
  }

  /// Shares or downloads a file.
  /// On iOS and Android shows Share-Popup afterwards.
  /// For the browser starts the file download.
  /// Use either [file] or [data].
  Future<void> launchFile({
    required BuildContext context,
    required String name,
    File? file,
    Uint8List? data,
  }) async {
    if (kIsWeb) {
      if (data != null) {
        final base64data = base64Encode(data);
        final a = html.AnchorElement(
            href: 'data:application/octet-stream;base64,$base64data');
        a.download = name;
        a.click();
        a.remove();
      }
    } else {
      if (file == null && data != null) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/$name';
        file = await File(path).create();
        file.writeAsBytesSync(data);
      }
      if (file != null) {
        final size = MediaQuery.of(context).size;
        // Get the Location of the widget (e.g. button), that called the method.
        final box = context.findRenderObject() as RenderBox?;
        final buttonLocation = box!.localToGlobal(Offset.zero) & box.size;

        // Alternatively create a Location in the center of the Screen
        final centerLocation = Rect.fromLTWH(0, 0, size.width, size.height / 2);

        // If we don't have a useful button location, use the center position
        final sharePositionOrigin = buttonLocation.height >= size.height
            ? centerLocation
            : buttonLocation;
        await Share.shareFiles(
          [file.path],
          subject: name,
          sharePositionOrigin: sharePositionOrigin,
        );
      }
    }
  }

  /// Downloads a file. On iOS and Android shows Share-Popup afterwards.
  /// For the browser starts the file download.
  Future<void> downloadAndLaunchFile(
      {required BuildContext context,
      required String url,
      required String name}) async {
    await EasyLoading.show(status: 'Datei laden...');
    try {
      if (kIsWeb) {
        final r = await http.get(
          Uri.parse(url),
        );
        final data = r.bodyBytes;
        await launchFile(context: context, name: name, data: data);
      } else {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/$name';
        await Dio().download(url, path);
        final file = File(path);
        await launchFile(context: context, name: name, file: file);
      }
      await EasyLoading.dismiss();
    } catch (e) {
      await EasyLoading.dismiss();
      await Yust.alertService.showAlert(context, 'Ups',
          'Die Datei kann nicht geöffnet werden. ${e.toString()}');
    }
  }

  Future<void> deleteFile({required String path, required String name}) async {
    try {
      await fireStorage.ref().child(path).child(name).delete();
    } catch (e) {
      throw YustException(e.toString());
    }
  }

  Future<bool> fileExist({required String path, required String name}) async {
    try {
      await fireStorage.ref().child(path).child(name).getDownloadURL();
    } on FirebaseException catch (_) {
      return false;
    }
    return true;
  }

  Future<String> getFileDownloadUrl(
      {required String path, required String name}) async {
    return await fireStorage.ref().child(path).child(name).getDownloadURL();
  }

  Future<File> resizeImage({required File file, int maxWidth = 1024}) async {
    var properties = await FlutterNativeImage.getImageProperties(file.path);
    if (properties.width! > properties.height! &&
        properties.width! > maxWidth) {
      file = await FlutterNativeImage.compressImage(
        file.path,
        quality: 80,
        targetWidth: maxWidth,
        targetHeight:
            (properties.height! * maxWidth / properties.width!).round(),
      );
    } else if (properties.height! > properties.width! &&
        properties.height! > maxWidth) {
      file = await FlutterNativeImage.compressImage(
        file.path,
        quality: 80,
        targetWidth:
            (properties.width! * maxWidth / properties.height!).round(),
        targetHeight: maxWidth,
      );
    }
    return file;
  }

  Uint8List? resizeImageBytes(
      {required String name, required Uint8List bytes, int maxWidth = 1024}) {
    var image = image_lib.decodeNamedImage(bytes, name)!;
    if (image.width > image.height && image.width > maxWidth) {
      image = image_lib.copyResize(image, width: maxWidth);
    } else if (image.height > image.width && image.height > maxWidth) {
      image = image_lib.copyResize(image, height: maxWidth);
    }
    return image_lib.encodeNamedImage(image, name) as Uint8List?;
  }
}
