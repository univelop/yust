import '../models/yust_file.dart';
import '../util/file_access/yust_cdn_configuration.dart';
import '../util/file_access/yust_file_access_grant.dart';

/// Handles file access and URL signing requests for files and folders.
///
/// This service has functions relevant mostly for the backend as well as some for the client.
///
/// It allows to create signed urls for specific files or generate signed url parts which
/// allow the client to access any file below a given allowed prefix.
///
/// This service can be used to create individual signed urls for files or url parts for folders
/// or directly create a [YustFileAccessGrant] which contains the signed url parts for the original file and its possible thumbnails.
///
/// The backend can generate these grants and pass them to the client.
/// The client should keep them in local state, mirror them to this service and use [YustFile.getOriginalUrl]
/// and [YustFile.getThumbnailUrl] to get the correct urls for the files based on the paths of the files and the currently available grants.
///
/// Validation of the signed urls or signed url parts is not a part of yust and has to be done by the used cdn or storage provider.
abstract interface class IYustFileAccessService {
  /// Base URL for the original files.
  ///
  /// Must end with a trailing slash.
  String? get originalCdnBaseUrl;

  /// Base URL for the thumbnail files.
  ///
  /// Must end with a trailing slash.
  String? get thumbnailCdnBaseUrl;

  /// List of file access grants
  ///
  /// This is mainly used by the client to securely access files.
  ///
  /// The client has to implement its own way to retrieve a list of grants from the trusted backend
  /// and mirror them to yust via the [setGrants] function.
  List<YustFileAccessGrant> get grants;

  /// Callback function which the client can use to generate a download URL for a given file.
  ///
  /// In a typical setup, the application should override this to make an API call to its backend
  /// to authorize the request and create a signed URL which the client can use to download the file.
  ///
  /// The generated URL should not be stored and only be used once for that individual download request.
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
  ///
  /// This is only relevant for the client to keep the grants inside yust in sync with local application state.
  /// The client has implement its own way to retrieve a list of grants from the trusted backend.
  ///
  /// The client then should mirror these local grants to yust via this function.
  /// This allows the client to use e.g. [YustFile.getOriginalUrl] and [YustFile.getThumbnailUrl] to get the correct urls for the files
  /// based on the paths of the files and the currently available grants.
  void setGrants(List<YustFileAccessGrant> grants);

  /// Returns the file access grant for a given file.
  ///
  /// Tries to match the file path to a grant path prefix.
  /// e.g. a file like 'environment1/user/images/picture.jpg' would match the grant with path prefix 'environment1/'.
  ///
  /// This function is mainly used by the client to get the correct local grant for a given file
  /// and then use its original or thumbnail signed url part to display or download the file.
  YustFileAccessGrant? getGrantForFile(YustFile file);

  /// Helper function to create a new file access grant.
  ///
  /// Creates a new file access grant for a given path prefix.
  /// Takes the [originalCdnConfiguration] and [thumbnailCdnConfiguration] to allow the creation
  /// of signed url parts for the original and thumbnail files.
  YustFileAccessGrant createGrant({
    required YustCdnConfiguration originalCdnConfiguration,
    required YustCdnConfiguration thumbnailCdnConfiguration,
    required String pathPrefix,
    required Duration validFor,
  });
}
