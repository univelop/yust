import '../models/yust_file.dart';
import '../util/file_access/yust_cdn_configuration.dart';
import '../util/file_access/yust_file_access_grant.dart';

/// Handles file access URL signing requests.
abstract interface class IYustFileAccessService {
  /// Base URL for the original files.
  String? get originalCdnBaseUrl;

  /// Base URL for the thumbnail files.
  String? get thumbnailCdnBaseUrl;

  /// List of file access grants
  List<YustFileAccessGrant> get grants;

  Future<String?> Function(YustFile)? generateDownloadUrl;

  /// Creates a signed URL for a file at the given [path] and [name].
  /// The [validFor] parameter limits the validity of the URL.
  String createSignedUrlForFile({
    required String path,
    required String name,
    required Duration validFor,
    required YustCdnConfiguration cdnConfiguration,
    Map<String, String>? additionalQueryParams,
  });

  /// Creates a signed URL Part for a folder at the given [path], using URLPrefix signing.
  ///
  /// Returns only the query string to append to the requested file url.
  /// e.g. `URLPrefix=...`
  String createSignedUrlPartForFolder({
    required String path,
    required Duration validFor,
    required YustCdnConfiguration cdnConfiguration,
  });

  /// Sets the list of file access grants.
  void setGrants(List<YustFileAccessGrant> grants);

  /// Returns the file access grant for a given file.
  ///
  /// Tries to match the file path to a grant path prefix.
  YustFileAccessGrant? getGrantForFile(YustFile file);
}
