import 'package:collection/collection.dart';

import '../models/yust_file.dart';
import '../util/file_access/yust_cdn_configuration.dart';
import '../util/file_access/yust_file_access_grant.dart';
import '../util/yust_exception.dart';
import 'yust_file_access_service_interface.dart';

/// Mocked file access service.
///
/// Provides basic implementation to prevent errors when not initialized.
class YustFileAccessServiceMocked implements IYustFileAccessService {
  @override
  final String? originalCdnBaseUrl;

  @override
  final String? thumbnailCdnBaseUrl;

  @override
  List<YustFileAccessGrant> grants = [];

  @override
  Future<String?> Function(YustFile)? generateDownloadUrl;

  YustFileAccessServiceMocked({
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
    throw YustException('Not implemented in mocked service');
  }

  @override
  String createSignedUrlPartForFolder({
    required String path,
    required Duration validFor,
    required YustCdnConfiguration cdnConfiguration,
  }) {
    throw YustException('Not implemented in mocked service');
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
