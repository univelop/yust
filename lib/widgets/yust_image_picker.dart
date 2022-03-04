import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/screens/yust_image_screen.dart';
import 'package:yust/util/yust_exception.dart';
import 'package:yust/widgets/yust_list_tile.dart';
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
  final bool multiple;
  final List<YustFile> images;
  final bool zoomable;
  final void Function(List<YustFile> images)? onChanged;
  final Widget? prefixIcon;
  final bool readOnly;
  final String yustQuality;

  /// default is 15
  final int imageCount;

  YustImagePicker({
    Key? key,
    this.label,
    required this.folderPath,
    this.multiple = false,
    required this.images,
    this.zoomable = false,
    this.onChanged,
    this.prefixIcon,
    this.readOnly = false,
    this.yustQuality = 'medium',
    int? imageCount,
  })  : imageCount = imageCount ?? 15,
        super(key: key);
  @override
  YustImagePickerState createState() => YustImagePickerState();
}

class YustImagePickerState extends State<YustImagePicker> {
  late List<YustFile> _files;
  late bool _enabled;
  late int _currentImageNumber;

  @override
  void initState() {
    _files = widget.images;

    _enabled = (widget.onChanged != null && !widget.readOnly);
    _currentImageNumber = widget.imageCount;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return YustListTile(
      label: widget.label,
      suffixChild: _buildPickButtons(context),
      prefixIcon: widget.prefixIcon,
      below: widget.multiple
          ? _buildGallery(context)
          : Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: _buildSingleImage(context, _files.firstOrNull),
            ),
    );
  }

  Widget _buildPickButtons(BuildContext context) {
    if (!_enabled || (!widget.multiple && _files.firstOrNull != null)) {
      return SizedBox.shrink();
    }

    return SizedBox(
      width: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (!kIsWeb)
            IconButton(
              color: Theme.of(context).colorScheme.primary,
              iconSize: 40,
              icon: Icon(Icons.camera_alt),
              onPressed:
                  _enabled ? () => _pickImages(ImageSource.camera) : null,
            ),
          IconButton(
            color: Theme.of(context).colorScheme.primary,
            iconSize: 40,
            icon: Icon(Icons.image),
            onPressed: _enabled ? () => _pickImages(ImageSource.gallery) : null,
          ),
        ],
      ),
    );
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
        SizedBox(height: 2)
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
        return _buildSingleImage(context, file);
      }).toList(),
    );
  }

  Widget _buildSingleImage(BuildContext context, YustFile? file) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        _buildImagePreview(context, file),
        _buildProgressIndicator(context, file),
        _buildRemoveButton(context, file),
      ],
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
      decoration: BoxDecoration(
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
    if (file == null || !_enabled || file.url == null) {
      return SizedBox.shrink();
    }
    return Positioned(
      top: 10,
      right: 10,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: IconButton(
          icon: Icon(Icons.delete),
          color: Colors.black,
          onPressed: () => _deleteImage(file),
        ),
      ),
    );
  }

  Future<void> _pickImages(ImageSource imageSource) async {
    Yust.helperService.unfocusCurrent(context);
    final size = YustImageQuality[widget.yustQuality]!['size']!.toDouble();
    final quality = YustImageQuality[widget.yustQuality]!['quality']!;
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      await Yust.alertService.showAlert(context, 'Kein Internet',
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
                path: platformFile.name,
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
                path: result.files.single.name,
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
    final imageName = Yust.helperService.randomString(length: 16) +
        '.' +
        path.split('.').last;
    final newFile =
        YustFile(name: imageName, file: file, bytes: bytes, processing: true);
    setState(() {
      _files.add(newFile);
    });
    try {
      if (resize) {
        final size = YustImageQuality[widget.yustQuality]!['size']!;
        if (file != null) {
          file = await Yust.fileService.resizeImage(file: file, maxWidth: size);
          newFile.file = file;
        } else {
          bytes = Yust.fileService
              .resizeImageBytes(name: path, bytes: bytes!, maxWidth: size);
          newFile.bytes = bytes;
        }
      }

      var url = await Yust.fileService.uploadFile(
          path: widget.folderPath, name: imageName, file: file, bytes: bytes);
      newFile.url = url;
      newFile.processing = false;
      if (mounted) {
        setState(() {});
      }
      widget.onChanged!(_files);
      if (_currentImageNumber < _files.length) {
        _currentImageNumber += widget.imageCount;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _files.remove(newFile);
        });
        await Yust.alertService.showAlert(context, 'Ups', e.toString());
      }
    }
  }

  void _showImages(YustFile activeFile) {
    Yust.helperService.unfocusCurrent(context);
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => YustImageScreen(
        files: _files,
        activeImageIndex: _files.indexOf(activeFile),
      ),
    ));
  }

  Future<void> _deleteImage(YustFile file) async {
    Yust.helperService.unfocusCurrent(context);
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      await Yust.alertService.showAlert(context, 'Kein Internet',
          'Für das Löschen eines Bildes ist eine Internetverbindung erforderlich.');
    } else {
      final confirmed = await Yust.alertService
          .showConfirmation(context, 'Wirklich löschen?', 'Löschen');
      if (confirmed == true) {
        try {
          await firebase_storage.FirebaseStorage.instance
              .ref()
              .child(widget.folderPath)
              .child(file.name!)
              .delete();
        } catch (e) {
          YustException(e.toString());
        }
        setState(() {
          _files.remove(file);
        });
        widget.onChanged!(_files);
      }
    }
  }
}
