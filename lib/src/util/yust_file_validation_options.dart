import '../models/yust_file.dart';
import 'yust_exception.dart';

/// Options for validating files before upload.
///
/// Used by file/image pickers and share intent handling.
class YustFileValidationOptions {
  final num numberOfFiles;
  final bool overwriteSingleFile;
  final num? maximumFileSizeInKiB;
  final List<String>? allowedExtensions;

  const YustFileValidationOptions({
    this.numberOfFiles = 1,
    this.overwriteSingleFile = false,
    this.maximumFileSizeInKiB,
    this.allowedExtensions,
  });

  /// Validates a new file against all constraints.
  ///
  /// Throws typed [YustFileValidationException] subclasses on failure.
  /// [newFile] is the file to validate.
  /// [existingFiles] is the list of files already present.
  /// [newFileSizeInKiB] is the size of the new file in KiB. If not provided,
  /// the size is calculated from [newFile.bytes] or [newFile.file].
  void validateFile({
    required YustFile newFile,
    required List<YustFile> existingFiles,
    int? newFileSizeInKiB,
  }) {
    _checkFileCount(existingFiles);
    _checkFileExtension(newFile);
    _checkFileSize(newFile, newFileSizeInKiB);
    _checkExistingFileNames(newFile, existingFiles);
  }

  void _checkFileCount(List<YustFile> existingFiles) {
    if (!overwriteSingleFile && existingFiles.length >= numberOfFiles) {
      throw YustFileLimitExceededException(
        'File limit of $numberOfFiles reached.',
        limit: numberOfFiles,
      );
    }

    if (overwriteSingleFile && existingFiles.length > 1) {
      throw YustFileLimitExceededException(
        'File limit of $numberOfFiles reached.',
        limit: numberOfFiles,
      );
    }

    if (overwriteSingleFile && existingFiles.isNotEmpty) {
      throw YustFileOverwriteRequiredException(
        'A file already exists and will be overwritten.',
        existingFile: existingFiles.first,
      );
    }
  }

  void _checkFileExtension(YustFile newFile) {
    if (allowedExtensions == null || allowedExtensions!.isEmpty) return;

    final extension = newFile.getFilenameExtension().toLowerCase();
    if (!allowedExtensions!.contains(extension)) {
      throw YustFileExtensionNotAllowedException(
        'File extension "$extension" is not allowed.',
        extension: extension,
        allowedExtensions: allowedExtensions!,
      );
    }
  }

  void _checkFileSize(YustFile newFile, int? newFileSizeInKiB) {
    if (maximumFileSizeInKiB == null) return;

    final int fileSizeInKiB;
    if (newFileSizeInKiB != null) {
      fileSizeInKiB = newFileSizeInKiB;
    } else if (newFile.bytes != null) {
      fileSizeInKiB = newFile.bytes!.length ~/ 1024;
    } else if (newFile.file != null) {
      fileSizeInKiB = newFile.file!.lengthSync() ~/ 1024;
    } else {
      return;
    }

    if (fileSizeInKiB > maximumFileSizeInKiB!) {
      throw YustFileSizeExceededException(
        'File "${newFile.name}" exceeds the maximum size of $maximumFileSizeInKiB KiB.',
        fileSizeInKiB: fileSizeInKiB,
        maximumFileSizeInKiB: maximumFileSizeInKiB!,
      );
    }
  }

  void _checkExistingFileNames(
    YustFile newFile,
    List<YustFile> existingFiles,
  ) {
    if (existingFiles.any((file) => file.name == newFile.name)) {
      throw YustFileAlreadyExistsException(
        'File "${newFile.name}" already exists.',
        fileName: newFile.name ?? '',
      );
    }
  }
}

/// Base exception for file validation failures.
class YustFileValidationException extends YustException {
  YustFileValidationException(super.message);
}

/// Thrown when the file size exceeds the maximum allowed size.
class YustFileSizeExceededException extends YustFileValidationException {
  final int fileSizeInKiB;
  final num maximumFileSizeInKiB;

  YustFileSizeExceededException(
    super.message, {
    required this.fileSizeInKiB,
    required this.maximumFileSizeInKiB,
  });
}

/// Thrown when the file extension is not in the allowed list.
class YustFileExtensionNotAllowedException
    extends YustFileValidationException {
  final String extension;
  final List<String> allowedExtensions;

  YustFileExtensionNotAllowedException(
    super.message, {
    required this.extension,
    required this.allowedExtensions,
  });
}

/// Thrown when the file limit has been reached.
class YustFileLimitExceededException extends YustFileValidationException {
  final num limit;

  YustFileLimitExceededException(
    super.message, {
    required this.limit,
  });
}

/// Thrown when a file with the same name already exists.
///
/// This is a soft validation — callers may choose to confirm with the user
/// and proceed by deleting the existing file.
class YustFileAlreadyExistsException extends YustFileValidationException {
  final String fileName;

  YustFileAlreadyExistsException(
    super.message, {
    required this.fileName,
  });
}

/// Thrown when overwrite is enabled and an existing file needs to be replaced.
///
/// This is a soft validation — callers should confirm with the user before
/// proceeding to overwrite.
class YustFileOverwriteRequiredException extends YustFileValidationException {
  final YustFile existingFile;

  YustFileOverwriteRequiredException(
    super.message, {
    required this.existingFile,
  });
}
