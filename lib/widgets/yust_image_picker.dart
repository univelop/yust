import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/screens/image.dart';
import 'package:yust/util/yust_offlineCache.dart';
import 'package:yust/yust.dart';
import 'package:yust/util/list_extension.dart';

final Map<String, Map<String, int>> YustImageQuality = {
  'original': {'quality': 100, 'size': 5000},
  'high': {'quality': 100, 'size': 2000},
  'medium': {'quality': 90, 'size': 1200},
  'low': {'quality': 80, 'size': 800},
};

class YustImagePicker extends StatefulWidget {
  final String? label;
  final String folderPath;
  final String pathToDoc;
  final String docAttribute;
  final bool multiple;
  final List<Map<String, dynamic>> images;
  final bool zoomable;
  final void Function(List<Map<String, dynamic>> images)? onChanged;
  final void Function(String url, YustFile localFile)? onUploaded;
  final Widget? prefixIcon;
  final bool readOnly;
  final String yustQuality;

  /// default is 15
  final int imageCount;

  YustImagePicker({
    Key? key,
    this.label,
    required this.folderPath,
    required this.pathToDoc,
    required this.docAttribute,
    this.multiple = false,
    required this.images,
    this.zoomable = false,
    this.onChanged,
    this.onUploaded,
    this.prefixIcon,
    this.readOnly = false,
    this.yustQuality = 'medium',
    int? imageCount,
  })  : this.imageCount = imageCount ?? 15,
        super(key: key);
  @override
  YustImagePickerState createState() => YustImagePickerState();
}

class YustImagePickerState extends State<YustImagePicker> {
  static bool uploadingTemporaryFiles = false;
  static List<YustFile> uploadingFiles = [];

  late List<YustFile> _files;
  late bool _enabled;
  late int _currentImageNumber;

  @override
  void initState() {
    _files = widget.images
        .map<YustFile>((image) => YustFile.fromJson(image))
        .toList();
    _enabled = (widget.onChanged != null && !widget.readOnly);
    _currentImageNumber = widget.imageCount;
    offlineCache.validateLocalFiles();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadLocalImages(),
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 8.0, right: 16.0, bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 1,
                    fit: FlexFit.loose,
                    child: _buildLabel(context),
                  ),
                  Flexible(
                    flex: 2,
                    fit: FlexFit.tight,
                    child: Stack(
                      alignment: AlignmentDirectional.center,
                      children: [
                        if (!widget.multiple)
                          _buildImagePreview(context, _files.firstOrNull),
                        if (!widget.multiple)
                          _buildProgressIndicator(context, _files.firstOrNull),
                        _buildPickButtons(context),
                        if (!widget.multiple)
                          _buildRemoveButton(context, _files.firstOrNull),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.multiple) _buildGallery(context),
            Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
          ],
        );
      },
    );
  }

  Widget _buildLabel(BuildContext context) {
    var padding;
    if (widget.label != null && widget.prefixIcon != null) {
      padding = EdgeInsets.only(left: 8.0);
    } else {
      padding = EdgeInsets.only(left: 16.0);
    }
    return ListTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.prefixIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: widget.prefixIcon,
            ),
          Flexible(
            child: Text(
              widget.label ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      contentPadding: padding,
    );
  }

  Widget _buildPickButtons(BuildContext context) {
    if (!_enabled || (!widget.multiple && _files.firstOrNull != null)) {
      return SizedBox.shrink();
    }
    if (kIsWeb) {
      return Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          color: Theme.of(context).colorScheme.secondary,
          iconSize: 40,
          icon: Icon(Icons.image),
          onPressed: _enabled ? () => _pickImages(ImageSource.gallery) : null,
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          IconButton(
            color: Theme.of(context).colorScheme.secondary,
            iconSize: 40,
            icon: Icon(Icons.camera_alt),
            onPressed: _enabled ? () => _pickImages(ImageSource.camera) : null,
          ),
          IconButton(
            color: Theme.of(context).colorScheme.secondary,
            iconSize: 40,
            icon: Icon(Icons.image),
            onPressed: _enabled ? () => _pickImages(ImageSource.gallery) : null,
          ),
        ],
      );
    }
  }

  Widget _buildGallery(BuildContext context) {
    if (_files.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildGalleryView(context),
        if (_files.length > _currentImageNumber)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                primary: Theme.of(context).primaryIconTheme.color,
                onPrimary: Theme.of(context).backgroundColor,
              ),
              onPressed: () {
                _currentImageNumber += widget.imageCount;
                setState(() {
                  _buildGallery(context);
                });
              },
              icon: Icon(Icons.refresh),
              label: Text('mehr laden'),
            ),
          ),
      ],
    );
  }

  GridView _buildGalleryView(
    BuildContext context,
  ) {
    var pictureFiles = _files.length > _currentImageNumber
        ? _files.sublist(0, _currentImageNumber)
        : _files;

    return GridView.extent(
      shrinkWrap: true,
      maxCrossAxisExtent: 180,
      primary: false,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: pictureFiles.map((file) {
        return Stack(
          alignment: AlignmentDirectional.center,
          children: [
            _buildImagePreview(context, file),
            _buildProgressIndicator(context, file),
            _buildRemoveButton(context, file),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildImagePreview(BuildContext context, YustFile? file) {
    if (file == null) {
      return SizedBox.shrink();
    }
    Widget preview;
    if (file.file != null) {
      preview = Image.file(file.file!, fit: BoxFit.cover);
    } else if (file.bytes != null) {
      preview = Image.memory(file.bytes!, fit: BoxFit.cover);
    } else {
      preview = FadeInImage.assetNetwork(
        placeholder: Yust.imagePlaceholderPath!,
        image: file.url ?? '',
        fit: BoxFit.cover,
      );
    }
    final zoomEnabled = (file.url != null && widget.zoomable);
    if (widget.multiple) {
      return AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onTap: zoomEnabled ? () => _showImages(file) : null,
          child: file.url != null
              ? Hero(
                  tag: file.url!,
                  child: preview,
                )
              : preview,
        ),
      );
    } else {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 300, maxWidth: 400),
        child: GestureDetector(
          onTap: zoomEnabled ? () => _showImages(file) : null,
          child: file.url != null
              ? Hero(
                  tag: file.url!,
                  child: preview,
                )
              : preview,
        ),
      );
    }
  }

  Widget _buildProgressIndicator(BuildContext context, YustFile? file) {
    if (file?.processing != true) {
      return SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: new BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.all(const Radius.circular(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Bild hochladen',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context, YustFile? file) {
    // file.url can be null, if the file is local
    if (file == null ||
        !_enabled ||
        (file.url == null && !_isLocalFile(file.name))) {
      return SizedBox.shrink();
    }
    return Positioned(
      top: 10,
      right: 10,
      child: CircleAvatar(
        radius: 26,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: IconButton(
          icon: Icon(Icons.clear),
          color: Colors.black,
          onPressed: () => _deleteImage(file),
        ),
      ),
    );
  }

  Future<void> _pickImages(ImageSource imageSource) async {
    Yust.service.unfocusCurrent(context);
    final size = YustImageQuality[widget.yustQuality]!['size']!.toDouble();
    final quality = YustImageQuality[widget.yustQuality]!['quality']!;
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      Yust.service.showAlert(context, 'Kein Internet',
          'Für das Hinzufügen von Bildern ist eine Internetverbindung erforderlich.');
    } else {
      if (!kIsWeb) {
        final picker = ImagePicker();
        if (widget.multiple && imageSource == ImageSource.gallery) {
          final images = await picker.pickMultiImage(
              maxHeight: size, maxWidth: size, imageQuality: quality);
          if (images != null) {
            for (final image in images) {
              await uploadFile(
                  path: image.path,
                  file: File(image.path),
                  yustQuality: widget.yustQuality);
            }
          }
        } else {
          final image = await picker.pickImage(
              source: imageSource,
              maxHeight: size,
              maxWidth: size,
              imageQuality: quality);
          if (image != null) {
            await uploadFile(
                path: image.path,
                file: File(image.path),
                yustQuality: widget.yustQuality);
          }
        }
      } else {
        if (widget.multiple) {
          final result = await FilePicker.platform
              .pickFiles(type: FileType.image, allowMultiple: true);
          if (result != null) {
            for (final platformFile in result.files) {
              await uploadFile(
                path: platformFile.name!,
                bytes: platformFile.bytes,
                resize: true,
                yustQuality: widget.yustQuality,
              );
            }
          }
        } else {
          final result =
              await FilePicker.platform.pickFiles(type: FileType.image);
          if (result != null) {
            await uploadFile(
                path: result.files.single.name!,
                bytes: result.files.single.bytes,
                resize: true,
                yustQuality: widget.yustQuality);
          }
        }
      }
    }
  }

  Future<void> uploadFile({
    required String path,
    File? file,
    Uint8List? bytes,
    bool resize = false,
    required String yustQuality,
  }) async {
    final imageName =
        Yust.service.randomString(length: 16) + '.' + path.split('.').last;
    final newFile = YustFile(
      name: 'local' + imageName,
      file: file,
      bytes: bytes,
      processing: true,
    );
    setState(() {
      _files.add(newFile);
    });
    try {
      if (resize) {
        final size = YustImageQuality[widget.yustQuality]!['size']!;
        if (file != null) {
          file = await Yust.service.resizeImage(file: file, maxWidth: size);
          newFile.file = file;
        } else {
          bytes = Yust.service
              .resizeImageBytes(name: path, bytes: bytes!, maxWidth: size);
          newFile.bytes = bytes;
        }
      }

      newFile.processing = false;
      if (file != null) {
        newFile.url = await _saveImageTemporary(newFile);
      }

      if (mounted) {
        setState(() {});
      }
      _onChanged();

      if (_currentImageNumber < _files.length) {
        _currentImageNumber += widget.imageCount;
      }
      offlineCache.uploadLocalFiles();
    } catch (e) {
      if (mounted) {
        setState(() {
          _files.remove(newFile);
        });
        Yust.service.showAlert(context, 'Ups', e.toString());
      }
    }
  }

  void _showImages(YustFile activeFile) {
    Yust.service.unfocusCurrent(context);
    if (widget.multiple) {
      Navigator.pushNamed(context, ImageScreen.routeName, arguments: {
        'urls': _files.map((file) => file.url).toList(),
        'url': activeFile.url,
      });
    } else {
      Navigator.pushNamed(context, ImageScreen.routeName, arguments: {
        'url': activeFile.url,
      });
    }
  }

  Future<void> _deleteImage(YustFile file) async {
    Yust.service.unfocusCurrent(context);
    final connectivityResult = await Connectivity().checkConnectivity();
    if (file.url == null) {
      final confirmed = await Yust.service
          .showConfirmation(context, 'Wirklich löschen', 'Löschen');
      if (confirmed == true) {
        try {
          await offlineCache.delteLocalFile(file.name);
        } catch (e) {}
        setState(() {
          _files.remove(file);
        });
        _onChanged();
      }
    } else if (connectivityResult == ConnectivityResult.none) {
      Yust.service.showAlert(context, 'Kein Internet',
          'Für das Löschen eines Bildes ist eine Internetverbindung erforderlich.');
    } else {
      final confirmed = await Yust.service
          .showConfirmation(context, 'Wirklich löschen', 'Löschen');
      if (confirmed == true) {
        try {
          await firebase_storage.FirebaseStorage.instance
              .ref()
              .child(widget.folderPath)
              .child(file.name)
              .delete();
        } catch (e) {}
        setState(() {
          _files.remove(file);
        });
        _onChanged();
      }
    }
  }

  void _onChanged() {
    List<YustFile> _onlineFiles = List.from(_files);
    for (var file in _onlineFiles) {
      if (_isLocalPath(file.url ?? '')) {
        file.url = null;
      }
    }

    widget.onChanged!(_onlineFiles.map((file) => file.toJson()).toList());
  }

  Future<List<YustFile>> _loadLocalImages() async {
    for (var file in _files) {
      if (file.file == null) {
        if (_isLocalPath(file.url ?? '') || file.url == null) {
          final path = await _getLocalPath(file.name);
          if (offlineCache.isFileInCache(path)) {
            file.file = File(path!);
            file.url = path;
          } else {
            //TODO: offline: warum wird imagePlaceholderPath nicht als gültiges Bild akzeptiert?
            file.file = File(Yust.imageGetUploadedPath);
            file.url = Yust.imageGetUploadedPath;
          }
        }
      }
    }
    return _files;
  }

  /// returns local path from [localFile]
  Future<String> _saveImageTemporary(YustFile file) async {
    final tempDir = await getTemporaryDirectory();
    String path = '${tempDir.path}/${file.name}';
    // save new image in cache
    file.file!.copy(path);

    var localFile = new YustLocalFile(
        name: file.name,
        folderPath: widget.folderPath,
        pathToDoc: widget.pathToDoc,
        docAttribute: widget.docAttribute,
        localPath: path);

    var temporaryFiles = await offlineCache.getLocalFiles();
    temporaryFiles.add(localFile);
    await offlineCache.saveLocalFiles(temporaryFiles);
    return path;
  }

  Future<String?> _getLocalPath(String fileName) async {
    final localFiles = await offlineCache.getLocalFiles();
    final localFile =
        localFiles.firstWhereOrNull((localFile) => localFile.name == fileName);
    return localFile == null ? null : localFile.localPath;
  }

  bool _isLocalFile(String fileName) {
    return fileName.substring(0, 5) == 'local';
  }

  bool _isLocalPath(String path) {
    return !Uri.parse(path).isAbsolute;
  }
}
