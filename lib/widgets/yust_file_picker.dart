import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yust/util/yust_exception.dart';
import 'package:yust/widgets/yust_input_tile.dart';

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
    _enabled = widget.onChanged != null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return YustInputTile(
        child: _buildAddButton(context),
        label: widget.label,
        prefixIcon: widget.prefixIcon,
        suffixChild: _buildFiles(context));
  }

  _buildAddButton(BuildContext context) {
    if (!_enabled) {
      return SizedBox.shrink();
    }
    return IconButton(
      icon: Icon(Icons.add, color: Theme.of(context).accentColor),
      onPressed: _enabled ? _pickFiles : null,
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
          Expanded(
            child: Text(file['name'], overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      trailing: _buildDeleteButton(file),
      onTap: () => _showFile(file),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }

  Widget _buildDeleteButton(Map<String, String> file) {
    if (!_enabled) {
      return SizedBox.shrink();
    }
    if (_processing[file['name']] == true) {
      return CircularProgressIndicator();
    }
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: _enabled ? () => _deleteFile(file) : null,
    );
  }

  Future<void> _pickFiles() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      Yust.service.showAlert(context, 'Kein Internet',
          'Für das Hinzufügen einer Datei ist eine Internetverbindung erforderlich.');
    } else {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
        if (_files == null) _files = [];
        for (final platformFile in result.files) {
          var name = platformFile.name.split('/').last;
          final ext = platformFile.extension;
          if (ext != null && name.split('.').last != ext) {
            name += '.' + ext;
          }
          Map<String, String> fileData = {
            'name': name,
          };
          if (_files.any((file) => file['name'] == fileData['name'])) {
            Yust.service.showAlert(context, 'Nicht möglich',
                'Eine Datei mit dem Namen ${fileData['name']} existiert bereits.');
          } else {
            setState(() {
              _files.add(fileData);
              _files.sort((a, b) => a['name'].compareTo(b['name']));
              _processing[fileData['name']] = true;
            });
            File file;
            if (platformFile.path != null) {
              file = File(platformFile.path);
            }
            try {
              fileData['url'] = await Yust.service.uploadFile(
                path: widget.folderPath,
                name: fileData['name'],
                file: file,
                bytes: platformFile.bytes,
              );
            } on YustException catch (e) {
              Yust.service.showAlert(context, 'Ups', e.message);
            } catch (e) {
              Yust.service.showAlert(
                  context, 'Ups', 'Die Datei konnte nicht hochgeladen werden.');
            }
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
  }

  Future<void> _showFile(Map<String, String> file) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      Yust.service.showAlert(context, 'Kein Internet',
          'Für das Anzeigen einer Datei ist eine Internetverbindung erforderlich.');
    } else if (file['name'] != null && _processing[file['name']] != true) {
      if (await canLaunch(file['url'])) {
        await launch(file['url']);
      } else {
        await Yust.service
            .showAlert(context, 'Ups', 'Die Datei kann nicht geöffnet werden.');
      }
    }
  }

  Future<void> _deleteFile(Map<String, String> file) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      Yust.service.showAlert(context, 'Kein Internet',
          'Für das Löschen einer Datei ist eine Internetverbindung erforderlich.');
    } else if (file['name'] != null) {
      final confirmed = await Yust.service
          .showConfirmation(context, 'Wirklich löschen?', 'Löschen');
      if (confirmed == true) {
        try {
          await firebase_storage.FirebaseStorage.instance
              .ref()
              .child(widget.folderPath)
              .child(file['name'])
              .delete();
        } catch (e) {}

        setState(() {
          _files.remove(file);
        });
        widget.onChanged(_files);
      }
    }
  }
}
