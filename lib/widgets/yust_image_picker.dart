import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity/connectivity.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/screens/image.dart';
import 'package:yust/yust.dart';
import 'package:yust/util/list_extension.dart';
import 'package:yust/util/yust_web_helper.dart';

/// See https://pub.dev/packages/image_picker for installation information.
class YustImagePicker extends StatefulWidget {
  final String label;
  final String folderPath;
  final bool multiple;
  final List<Map<String, dynamic>> images;
  final bool zoomable;
  final void Function(List<Map<String, dynamic>> images) onChanged;
  final Widget prefixIcon;

  YustImagePicker({
    Key key,
    this.label,
    this.folderPath,
    this.multiple = false,
    this.images,
    this.zoomable = false,
    this.onChanged,
    this.prefixIcon,
  }) : super(key: key);

  @override
  _YustImagePickerState createState() => _YustImagePickerState();
}

class _YustImagePickerState extends State<YustImagePicker> {
  List<YustFile> _files;
  bool _enabled;

  @override
  void initState() {
    if (widget.images == null) {
      _files = [];
    } else if (widget.images.length == 1 && widget.images.first == null) {
      _files = [];
    } else {
      _files = widget.images
          .map<YustFile>((image) => YustFile.fromJson(image))
          .toList();
    }
    _enabled = widget.onChanged != null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, right: 16.0, bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 2,
                fit: FlexFit.tight,
                child: _buildLabel(context),
              ),
              Flexible(
                flex: 1,
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
    if (!widget.multiple && _files?.firstOrNull != null) {
      return SizedBox.shrink();
    }
    if (kIsWeb) {
      return Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          color: Theme.of(context).accentColor,
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
            color: Theme.of(context).accentColor,
            iconSize: 40,
            icon: Icon(Icons.camera_alt),
            onPressed: _enabled ? () => _pickImages(ImageSource.camera) : null,
          ),
          IconButton(
            color: Theme.of(context).accentColor,
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

  Widget _buildImagePreview(BuildContext context, YustFile file) {
    if (file == null) {
      return SizedBox.shrink();
    }
    Widget preview;
    if (file.file != null) {
      preview = Image.file(file.file, fit: BoxFit.cover);
    } else if (file.bytes != null) {
      preview = Image.memory(file.bytes, fit: BoxFit.cover);
    } else {
      preview = FadeInImage.assetNetwork(
        placeholder: Yust.imagePlaceholderPath,
        image: file.url,
        fit: BoxFit.cover,
      );
    }
    final zoomEnabled = (file.url != null && widget.zoomable);
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: zoomEnabled ? () => _showImages(file) : null,
        child: file.url != null
            ? Hero(
                tag: file.url,
                child: preview,
              )
            : preview,
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, YustFile file) {
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
              style:
                  TextStyle(color: Theme.of(context).accentColor, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context, YustFile file) {
    if (file == null || !_enabled || file.url == null) {
      return SizedBox.shrink();
    }
    return Positioned(
      top: 10,
      right: 10,
      child: CircleAvatar(
        radius: 26,
        backgroundColor: Theme.of(context).accentColor,
        child: IconButton(
          icon: Icon(Icons.clear),
          color: Colors.black,
          onPressed: () => _deleteImage(file),
        ),
      ),
    );
  }

  Future<void> _pickImages(ImageSource imageSource) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      Yust.service.showAlert(context, 'Kein Internet',
          'Für das Hinzufügen von Bildern ist eine Internetverbindung erforderlich.');
    } else {
      if (!kIsWeb) {
        if (widget.multiple && imageSource == ImageSource.gallery) {
          List<Asset> results;
          try {
            results = await MultiImagePicker.pickImages(
              maxImages: 10,
            );
          } on NoImagesSelectedException catch (_) {
            return;
          } on Exception catch (e) {
            Yust.service.showAlert(context, 'Fehler', e.toString());
          }
          if (results != null) {
            for (final asset in results) {
              final byteData = await asset.getByteData(quality: 80);
              final bytes = byteData.buffer.asUint8List();
              Directory tempDir = await getTemporaryDirectory();
              final file = await File(tempDir.path + '/' + asset.name)
                  .writeAsBytes(bytes);
              _uploadFile(path: file.path, file: file, resize: true);
            }
          }
        } else {
          final image = await ImagePicker()
              .getImage(source: imageSource, maxHeight: 800, maxWidth: 800);
          if (image != null) {
            await _uploadFile(path: image.path, file: File(image.path));
          }
        }
      } else {
        if (widget.multiple) {
          final result = await FilePicker.platform
              .pickFiles(type: FileType.image, allowMultiple: true);
          if (result != null) {
            for (final platformFile in result.files) {
              await _uploadFile(
                path: platformFile.name,
                bytes: platformFile.bytes,
                resize: true,
              );
            }
          }
        } else {
          final result =
              await FilePicker.platform.pickFiles(type: FileType.image);
          if (result != null) {
            await _uploadFile(
              path: result.files.single.name,
              bytes: result.files.single.bytes,
              resize: true,
            );
          }
        }
      }
    }
  }

  Future<void> _uploadFile(
      {String path, File file, Uint8List bytes, bool resize = false}) async {
    try {
      final imageName =
          Yust.service.randomString(length: 16) + '.' + path.split('.').last;
      final newFile =
          YustFile(name: imageName, file: file, bytes: bytes, processing: true);
      setState(() {
        _files.add(newFile);
      });

      if (resize) {
        if (file != null) {
          file = await Yust.service.resizeImage(file: file, maxWidth: 800);
          newFile.file = file;
        } else {
          bytes = Yust.service
              .resizeImageBytes(name: path, bytes: bytes, maxWidth: 800);
          newFile.bytes = bytes;
        }
      }

      String url = await Yust.service.uploadFile(
          path: widget.folderPath, name: imageName, file: file, bytes: bytes);
      setState(() {
        newFile.url = url;
        newFile.processing = false;
      });
      widget.onChanged(_files.map((file) => file.toJson()).toList());
    } catch (e) {
      Yust.service.showAlert(context, 'Ups', e.message);
    }
  }

  void _showImages(YustFile activeFile) {
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
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      Yust.service.showAlert(context, 'Kein Internet',
          'Für das Löschen eines Bildes ist eine Internetverbindung erforderlich.');
    } else if (file != null) {
      final confirmed = await Yust.service
          .showConfirmation(context, 'Wirklich löschen', 'Löschen');
      if (confirmed == true) {
        if (!kIsWeb) {
          try {
            await FirebaseStorage()
                .ref()
                .child(widget.folderPath)
                .child(file.name)
                .delete();
          } catch (e) {}
        } else {
          await YustWebHelper.deleteFile(
              path: widget.folderPath, name: file.name);
        }
        setState(() {
          _files.remove(file);
        });
        widget.onChanged(_files.map((file) => file.toJson()).toList());
      }
    }
  }
}
