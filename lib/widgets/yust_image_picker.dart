import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yust/screens/image.dart';
import 'package:yust/yust.dart';

/// See https://pub.dev/packages/image_picker for installation information.
class YustImagePicker extends StatefulWidget {
  final String label;
  final String folderPath;
  final String imageId;
  final String imageUrl;
  final bool zoomable;
  final void Function(String imageId, String imageUrl) onChanged;
  final Widget prefixIcon;

  YustImagePicker({
    Key key,
    this.label,
    this.folderPath,
    this.imageId,
    this.imageUrl,
    this.zoomable = false,
    this.onChanged,
    this.prefixIcon,
  }) : super(key: key);

  @override
  _YustImagePickerState createState() => _YustImagePickerState();
}

class _YustImagePickerState extends State<YustImagePicker> {
  String _imageId;
  String _imageUrl;
  File _imageFile;
  Uint8List _imageBytes;
  bool _imageProcessing = false;
  bool _enabled;

  @override
  void initState() {
    _imageId = widget.imageId;
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
    if (_imageId == null && _imageFile == null && _imageBytes == null) {
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
    if (_imageId != null || _imageFile != null || _imageBytes != null) {
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
      padding: const EdgeInsets.all(40),
      decoration: new BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.all(const Radius.circular(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(width: 8),
          Text(
            'Bild hochladen',
            style:
                TextStyle(color: Theme.of(context).accentColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context) {
    if (_imageId == null || !_enabled) {
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
        await _uploadFile(image.path, File(image.path));
      }
    } else {
      Yust.service.showAlert(context, 'Ups',
          'Diese Funktion steht im Browser nicht zur Verfügung.');
    }
  }

  Future<void> _uploadFile(String path, File file) async {
    final imageId =
        Yust.service.randomString(length: 16) + '.' + path.split('.').last;
    setState(() {
      _imageFile = file;
      _imageProcessing = true;
    });

    final StorageReference storageReference =
        FirebaseStorage().ref().child(widget.folderPath).child(imageId);

    StorageUploadTask uploadTask;
    uploadTask = storageReference.putFile(_imageFile);
    // final StreamSubscription<StorageTaskEvent> streamSubscription =
    //     uploadTask.events.listen((event) {
    //   print('EVENT ${event.type}');
    // });
    await uploadTask.onComplete;
    // streamSubscription.cancel();

    final url = await storageReference.getDownloadURL();

    setState(() {
      _imageId = imageId;
      _imageUrl = url;
      _imageProcessing = false;
    });
    widget.onChanged(_imageId, _imageUrl);
  }

  Future<void> _deleteImage() async {
    if (_imageId != null) {
      if (!kIsWeb) {
        try {
          await FirebaseStorage()
              .ref()
              .child(widget.folderPath)
              .child(_imageId)
              .delete();
        } catch (e) {}
      } else {
        Yust.service.showAlert(context, 'Ups',
            'Diese Funktion steht im Browser nicht zur Verfügung.');
      }

      setState(() {
        _imageId = null;
        _imageUrl = null;
        _imageFile = null;
        _imageBytes = null;
      });
      widget.onChanged(null, null);
    }
  }
}
