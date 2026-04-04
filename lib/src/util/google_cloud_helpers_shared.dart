import 'package:googleapis_auth/googleapis_auth.dart'
    show ServiceAccountCredentials;

enum GoogleCloudPlatform { cloudRunJob, cloudRunService, cloudFunctions, local }

/// Extension on [ServiceAccountCredentials] to derive the GCP project id
/// from the service account email (`<name>@<project-id>.iam.gserviceaccount.com`).
extension ServiceAccountCredentialsExtension on ServiceAccountCredentials {
  /// The GCP project id derived from the service account email.
  ///
  /// Returns `null` if the email does not follow the standard
  /// `<name>@<project-id>.iam.gserviceaccount.com` format.
  String? get projectId {
    const suffix = '.iam.gserviceaccount.com';
    final atIndex = email.indexOf('@');
    if (atIndex == -1) return null;
    final domain = email.substring(atIndex + 1);
    if (!domain.endsWith(suffix)) return null;
    return domain.substring(0, domain.length - suffix.length);
  }
}
