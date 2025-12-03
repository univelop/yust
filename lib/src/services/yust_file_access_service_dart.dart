import 'package:collection/collection.dart';

import '../models/yust_file.dart';
import '../util/file_access/yust_cdn_configuration.dart';
import '../util/file_access/yust_file_access_grant.dart';
import '../util/google_cloud_cdn_helper.dart';
import 'yust_file_access_service_interface.dart';

class YustFileAccessService implements IYustFileAccessService {
  @override
  final String? originalCdnBaseUrl;

  @override
  final String? thumbnailCdnBaseUrl;

  @override
  List<YustFileAccessGrant> grants = [];

  @override
  Future<String?> Function(YustFile)? generateDownloadUrl;

  YustFileAccessService({
    required this.originalCdnBaseUrl,
    required this.thumbnailCdnBaseUrl,
  });

  @override
  String createSignedUrlForFile({
    required String path,
    required String name,
    required Duration validFor,
    required YustCdnConfiguration cdnConfiguration,
    Map<String, String>? additionalQueryParams,
  }) {
    final helper = GoogleCloudCdnHelper(
      baseUrl: cdnConfiguration.baseUrl,
      keyName: cdnConfiguration.keyName,
      keyBase64: cdnConfiguration.keyBase64,
    );
    return helper.signFilePath(
      objectPath: '$path/$name',
      validFor: validFor,
      additionalQueryParams: additionalQueryParams,
    );
  }

  @override
  String createSignedUrlPartForFolder({
    required String path,
    required Duration validFor,
    required YustCdnConfiguration cdnConfiguration,
  }) {
    final helper = GoogleCloudCdnHelper(
      baseUrl: cdnConfiguration.baseUrl,
      keyName: cdnConfiguration.keyName,
      keyBase64: cdnConfiguration.keyBase64,
    );
    return helper.signPrefix(prefixPath: path, validFor: validFor);
  }

  @override
  void setGrants(List<YustFileAccessGrant> grants) {
    this.grants = grants;
  }

  @override
  YustFileAccessGrant? getGrantForFile(YustFile file) {
    return grants.firstWhereOrNull(
      (grant) => file.path?.startsWith(grant.pathPrefix) ?? false,
    );
  }
}
