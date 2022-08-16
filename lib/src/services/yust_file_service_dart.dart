import 'dart:io';
import 'dart:typed_data';

class YustFileService {
  YustFileService();

  YustFileService.mocked();

  Future<String> uploadFile(
      {required String path,
      required String name,
      File? file,
      Uint8List? bytes}) async {
    return 'url';
  }

  Future<Uint8List?> downloadFile(
      {required String path, required String name, int? maxSize}) async {
    return null;
  }

  Future<void> deleteFile({required String path, String? name}) async {}

  Future<bool> fileExist({required String path, required String name}) async {
    return false;
  }

  Future<String> getFileDownloadUrl(
      {required String path, required String name}) async {
    return 'url';
  }
}
