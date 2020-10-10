import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final List<Map<String, String>> images;
  final bool zoomable;
  final void Function(List<Map<String, String>> images) onChanged;
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
                    _buildImagePreview(context, _files.firstOrNull),
                    _buildProgressIndicator(context, _files.firstOrNull),
                    _buildPickButtons(context),
                    _buildRemoveButton(context, _files.firstOrNull),
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
        onTap: zoomEnabled
            ? () =>
                Navigator.pushNamed(context, ImageScreen.routeName, arguments: {
                  'url': file.url,
                })
            : null,
        child: file.url != null
            ? Hero(
                tag: file.url,
                child: preview,
              )
            : preview,
      ),
    );
  }

  Widget _buildPickButtons(BuildContext context) {
    if (_files?.firstOrNull != null) {
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
          onPressed: () => _deleteImage(_files.firstOrNull),
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
    final newFile =
        YustFile(name: imageName, file: file, bytes: bytes, processing: true);
    setState(() {
      _files.add(newFile);
    });

    String url;
    if (!kIsWeb) {
      final StorageReference storageReference =
          FirebaseStorage().ref().child(widget.folderPath).child(imageName);

      StorageUploadTask uploadTask;
      uploadTask = storageReference.putFile(file);
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
      newFile.url = url;
      newFile.processing = false;
    });
    widget.onChanged(_files.map((file) => file.toJson()).toList());
  }

  Future<void> _deleteImage(YustFile file) async {
    if (file != null) {
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
