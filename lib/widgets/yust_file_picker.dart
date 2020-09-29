import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yust/util/yust_web_helper.dart';

import '../yust.dart';

class YustFilePicker extends StatefulWidget {
  final String label;
  final String folderPath;
  final List<Map<String, String>> files;
  final void Function(List<Map<String, String>> files) onChanged;
  final Widget prefixIcon;

  YustFilePicker({
    Key key,
    this.label,
    this.folderPath,
    this.files,
    this.onChanged,
    this.prefixIcon,
  }) : super(key: key);

  @override
  _YustFilePickerState createState() => _YustFilePickerState();
}

class _YustFilePickerState extends State<YustFilePicker> {
  List<Map<String, String>> _files;
  Map<String, bool> _processing = {};
  bool _enabled;

  @override
  void initState() {
    _files = widget.files;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _enabled = widget.onChanged != null;
    var padding;
    if (widget.label != null && widget.prefixIcon != null) {
      padding =
          const EdgeInsets.only(left: 8.0, top: 8.0, right: 16.0, bottom: 8.0);
    } else {
      padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
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
          trailing: IconButton(
            icon: Icon(Icons.add),
            onPressed: _enabled ? _pickFiles : null,
          ),
          contentPadding: padding,
        ),
        _buildFiles(context),
        Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
      ],
    );
  }

  Widget _buildFiles(BuildContext context) {
    if (_files == null) {
      return SizedBox.shrink();
    }
    return Column(
      children: _files.map((file) => _buildFile(context, file)).toList(),
    );
  }

  Widget _buildFile(BuildContext context, Map<String, String> file) {
    if (file['name'] == null) {
      return SizedBox.shrink();
    }
    return ListTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file),
          SizedBox(width: 8),
          Text(file['name']),
        ],
      ),
      trailing: _processing[file['name']] == true
          ? CircularProgressIndicator()
          : IconButton(
              icon: Icon(Icons.delete),
              onPressed: _enabled ? () => _deleteFile(file) : null,
            ),
      onTap: _enabled ? () => _showFile(file) : null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      for (final platformFile in result.files) {
        Map<String, String> fileData = {
          'name': platformFile.name,
        };
        if (_files.any((file) => file['name'] == fileData['name'])) {
          Yust.service.showAlert(context, 'Nicht möglich',
              'Eine Datei mit dem Namen ${fileData['name']} existiert bereits.');
        } else {
          setState(() {
            if (_files == null) _files = [];
            _files.add(fileData);
            _processing[fileData['name']] = true;
          });
          File file = File(platformFile.path);
          fileData['url'] =
              await _uploadFile(fileName: fileData['name'], file: file);
          if (fileData['url'] == null) {
            _files.remove(fileData);
          }
          setState(() {
            _processing[fileData['name']] = false;
          });
        }
      }
      widget.onChanged(_files);
    }
  }

  Future<String> _uploadFile(
      {String fileName, File file, Uint8List bytes}) async {
    if (!kIsWeb) {
      final StorageReference storageReference =
          FirebaseStorage().ref().child(widget.folderPath).child(fileName);

      try {
        StorageUploadTask uploadTask;
        if (file != null) {
          uploadTask = storageReference.putFile(file);
        } else {
          uploadTask = storageReference.putData(bytes);
        }
        await uploadTask.onComplete;
        return await storageReference.getDownloadURL();
      } catch (error) {
        await Yust.service.showAlert(
            context, 'Ups', 'Fehler beim Upload: ' + error.toString());
        return null;
      }
    } else {
      return await YustWebHelper.uploadFile(
          path: widget.folderPath, name: fileName, bytes: bytes);
    }
  }

  Future<void> _showFile(Map<String, String> file) async {
    if (file['name'] != null && _processing[file['name']] != true) {
      if (await canLaunch(file['url'])) {
        await launch(file['url']);
      } else {
        await Yust.service
            .showAlert(context, 'Ups', 'Die Datei kann nicht geöffnet werden.');
      }
    }
  }

  Future<void> _deleteFile(Map<String, String> file) async {
    if (file['name'] != null) {
      final confirmed = await Yust.service
          .showConfirmation(context, 'Wirklich löschen?', 'Löschen');
      if (confirmed == true) {
        if (!kIsWeb) {
          try {
            await FirebaseStorage()
                .ref()
                .child(widget.folderPath)
                .child(file['name'])
                .delete();
          } catch (e) {}
        } else {
          await YustWebHelper.deleteFile(
              path: widget.folderPath, name: file['name']);
        }

        setState(() {
          _files.remove(file);
        });
        widget.onChanged(_files);
      }
    }
  }
}
