import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/screens/image.dart';
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
  final List<Map<String, dynamic>> images;
  final bool zoomable;
  final void Function(List<Map<String, dynamic>> images)? onChanged;
  final Widget? prefixIcon;
  final bool readOnly;
  final String yustQuality;

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
  }) : super(key: key);
  @override
  YustImagePickerState createState() => YustImagePickerState();
}

class YustImagePickerState extends State<YustImagePicker> {
  late List<YustFile> _files;
  late bool _enabled;

  @override
  void initState() {
    _files = widget.images
        .map<YustFile>((image) => YustFile.fromJson(image))
        .toList();
    _enabled = (widget.onChanged != null && !widget.readOnly);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 16.0, bottom: 8.0),
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
    return GridView.extent(
      shrinkWrap: true,
      maxCrossAxisExtent: 180,
      primary: false,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: _files.map((file) {
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
    if (file == null || !_enabled || file.url == null) {
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
    final newFile =
        YustFile(name: imageName, file: file, bytes: bytes, processing: true);
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

      String url = await Yust.service.uploadFile(
          path: widget.folderPath, name: imageName, file: file, bytes: bytes);
      newFile.url = url;
      newFile.processing = false;
      if (mounted) {
        setState(() {});
      }
      widget.onChanged!(_files.map((file) => file.toJson()).toList());
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
    if (connectivityResult == ConnectivityResult.none) {
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
        widget.onChanged!(_files.map((file) => file.toJson()).toList());
      }
    }
  }
}
