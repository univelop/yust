import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yust/screens/image.dart';
import 'package:yust/yust.dart';
import 'package:yust/util/yust_web_helper.dart';

/// See https://pub.dev/packages/image_picker for installation information.
class YustImagePicker extends StatefulWidget {
  final String label;
  final String folderPath;
  final String imageName;
  final String imageUrl;
  final bool zoomable;
  final void Function(String imageName, String imageUrl) onChanged;
  final Widget prefixIcon;

  YustImagePicker({
    Key key,
    this.label,
    this.folderPath,
    this.imageName,
    this.imageUrl,
    this.zoomable = false,
    this.onChanged,
    this.prefixIcon,
  }) : super(key: key);

  @override
  _YustImagePickerState createState() => _YustImagePickerState();
}

class _YustImagePickerState extends State<YustImagePicker> {
  String _imageName;
  String _imageUrl;
  File _imageFile;
  Uint8List _imageBytes;
  bool _imageProcessing = false;
  bool _enabled;

  @override
  void initState() {
    _imageName = widget.imageName;
    _imageUrl = widget.imageUrl;
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
                    _buildImagePreview(context),
                    _buildProgressIndicator(context),
                    _buildPickButtons(context),
                    _buildRemoveButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildImagePreview(BuildContext context) {
    if (_imageName == null && _imageFile == null && _imageBytes == null) {
      return SizedBox.shrink();
    }
    Widget preview;
    if (_imageFile != null) {
      preview = Image.file(_imageFile, fit: BoxFit.cover);
    } else if (_imageBytes != null) {
      preview = Image.memory(_imageBytes, fit: BoxFit.cover);
    } else {
      preview = FadeInImage.assetNetwork(
        placeholder: Yust.imagePlaceholderPath,
        image: widget.imageUrl,
        fit: BoxFit.cover,
      );
    }
    final zoomEnabled = (_imageUrl != null && widget.zoomable);
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: zoomEnabled
            ? () => Navigator.pushNamed(context, ImageScreen.routeName,
                arguments: _imageUrl)
            : null,
        child: preview,
      ),
    );
  }

  Widget _buildPickButtons(BuildContext context) {
    if (_imageName != null || _imageFile != null || _imageBytes != null) {
      return SizedBox.shrink();
    }
    if (kIsWeb) {
      return Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          color: Theme.of(context).accentColor,
          iconSize: 40,
          icon: Icon(Icons.image),
          onPressed: _enabled ? () => _pickImage(ImageSource.gallery) : null,
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
            onPressed: _enabled ? () => _pickImage(ImageSource.camera) : null,
          ),
          SizedBox(width: 16),
          IconButton(
            color: Theme.of(context).accentColor,
            iconSize: 40,
            icon: Icon(Icons.image),
            onPressed: _enabled ? () => _pickImage(ImageSource.gallery) : null,
          ),
        ],
      );
    }
  }

  Widget _buildProgressIndicator(BuildContext context) {
    if (_imageProcessing == false) {
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

  Widget _buildRemoveButton(BuildContext context) {
    if (_imageName == null || !_enabled) {
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
          onPressed: _deleteImage,
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource imageSource) async {
    if (!kIsWeb) {
      final image = await ImagePicker().getImage(source: imageSource);
      if (image != null) {
        await _uploadFile(path: image.path, file: File(image.path));
      }
    } else {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        await _uploadFile(
            path: result.files.single.name, bytes: result.files.single.bytes);
      }
    }
  }

  Future<void> _uploadFile({String path, File file, Uint8List bytes}) async {
    final imageName =
        Yust.service.randomString(length: 16) + '.' + path.split('.').last;
    setState(() {
      _imageFile = file;
      _imageBytes = bytes;
      _imageProcessing = true;
    });

    String url;
    if (!kIsWeb) {
      final StorageReference storageReference =
          FirebaseStorage().ref().child(widget.folderPath).child(imageName);

      StorageUploadTask uploadTask;
      uploadTask = storageReference.putFile(_imageFile);
      // final StreamSubscription<StorageTaskEvent> streamSubscription =
      //     uploadTask.events.listen((event) {
      //   print('EVENT ${event.type}');
      // });
      await uploadTask.onComplete;
      // streamSubscription.cancel();

      url = await storageReference.getDownloadURL();
    } else {
      url = await YustWebHelper.uploadFile(
          path: widget.folderPath, name: imageName, bytes: bytes);
    }

    setState(() {
      _imageName = imageName;
      _imageUrl = url;
      _imageProcessing = false;
    });
    widget.onChanged(_imageName, _imageUrl);
  }

  Future<void> _deleteImage() async {
    if (_imageName != null) {
      final confirmed = await Yust.service
          .showConfirmation(context, 'Wirklich löschen', 'Löschen');
      if (confirmed == true) {
        if (!kIsWeb) {
          try {
            await FirebaseStorage()
                .ref()
                .child(widget.folderPath)
                .child(_imageName)
                .delete();
          } catch (e) {}
        } else {
          await YustWebHelper.deleteFile(
              path: widget.folderPath, name: _imageName);
        }

        setState(() {
          _imageName = null;
          _imageUrl = null;
          _imageFile = null;
          _imageBytes = null;
        });
        widget.onChanged(null, null);
      }
    }
  }
}
