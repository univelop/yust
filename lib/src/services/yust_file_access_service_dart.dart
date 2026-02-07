import 'package:collection/collection.dart';

import '../models/yust_file.dart';
import '../util/file_access/yust_cdn_configuration.dart';
import '../util/file_access/yust_file_access_grant.dart';
import '../util/google_cloud_cdn_helper.dart';
import '../util/yust_exception.dart';
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
    required String? originalCdnBaseUrl,
    required String? thumbnailCdnBaseUrl,
  }) : originalCdnBaseUrl = _tryAppendTrailingSlash(originalCdnBaseUrl),
       thumbnailCdnBaseUrl = _tryAppendTrailingSlash(thumbnailCdnBaseUrl);

  static String? _tryAppendTrailingSlash(String? url) {
    if (url == null || url.isEmpty) return url;
    return url.endsWith('/') ? url : '$url/';
  }

  @override
  String createSignedUrlForFile({
    required String path,
    required String name,
    required Duration validFor,
    required YustCdnConfiguration cdnConfiguration,
    Map<String, String>? additionalQueryParams,
  }) {
    if (path.endsWith('/')) {
      throw YustException('Path must not end with a trailing slash: $path');
    }
    if (name.startsWith('/')) {
      throw YustException('Name must not start with a leading slash: $name');
    }

    final helper = GoogleCloudCdnHelper.fromCdnConfiguration(cdnConfiguration);
    return helper.signFilePath(
      path: '$path/$name',
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
    final helper = GoogleCloudCdnHelper.fromCdnConfiguration(cdnConfiguration);
    return helper.signPrefix(path: path, validFor: validFor);
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

  @override
  YustFileAccessGrant createGrant({
    required YustCdnConfiguration originalCdnConfiguration,
    required YustCdnConfiguration thumbnailCdnConfiguration,
    required String pathPrefix,
    required Duration validFor,
  }) => YustFileAccessGrant(
    pathPrefix: pathPrefix,
    originalSignedUrlPart: createSignedUrlPartForFolder(
      path: pathPrefix,
      validFor: validFor,
      cdnConfiguration: originalCdnConfiguration,
    ),
    thumbnailSignedUrlPart: createSignedUrlPartForFolder(
      path: pathPrefix,
      validFor: validFor,
      cdnConfiguration: thumbnailCdnConfiguration,
    ),
  );
}
