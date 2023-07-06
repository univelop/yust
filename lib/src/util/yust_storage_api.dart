import 'dart:core';

import 'package:googleapis/storage/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

class YustStorageApi {
  static StorageApi? instance;
  static String? rootUrl;
  static String? bucketName;
  static AuthClient? httpClient;

  static void initialize(AuthClient httpClient, String rootUrl, {String? projectId}) {
    YustStorageApi.httpClient = httpClient;
    YustStorageApi.rootUrl = rootUrl;
    YustStorageApi.bucketName = '${projectId ?? 'univelop-dev'}.appspot.com';
    YustStorageApi.instance = StorageApi(httpClient, rootUrl: rootUrl);
  }
}
