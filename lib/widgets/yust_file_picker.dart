import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yust/util/yust_exception.dart';
import 'package:dio/dio.dart';
import 'package:yust/widgets/yust_list_tile.dart';
import '../yust.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class YustFilePicker extends StatefulWidget {
  final String? label;
  final String folderPath;
  final List<Map<String, String>> files;
  final void Function(List<Map<String, String>> files)? onChanged;
  final Widget? prefixIcon;
  final bool readOnly;

  YustFilePicker({
    Key? key,
    this.label,
    required this.folderPath,
    required this.files,
    this.onChanged,
    this.prefixIcon,
    this.readOnly = false,
  }) : super(key: key);

  @override
  YustFilePickerState createState() => YustFilePickerState();
}

class YustFilePickerState extends State<YustFilePicker> {
  late List<Map<String, String>> _files;
  Map<String?, bool> _processing = {};
  late bool _enabled;

  @override
  void initState() {
    _files = widget.files;
    _enabled = (widget.onChanged != null && !widget.readOnly);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return YustListTile(
        suffixChild: _buildAddButton(context),
        label: widget.label,
        prefixIcon: widget.prefixIcon,
        below: _buildFiles(context));
  }

  _buildAddButton(BuildContext context) {
    if (!_enabled) {
      return SizedBox.shrink();
    }
    return IconButton(
      iconSize: 40,
      icon:
          Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
      onPressed: _enabled ? _pickFiles : null,
    );
  }

  Widget _buildFiles(BuildContext context) {
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
            child: Text(file['name']!, overflow: TextOverflow.ellipsis),
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
      color: Theme.of(context).colorScheme.primary,
      onPressed: _enabled ? () => _deleteFile(file) : null,
    );
  }

  Future<void> addFile(
      Map<String, String> fileData, File? file, Uint8List? bytes) async {
    setState(() {
      _files.add(fileData);
      _files.sort((a, b) => a['name']!.compareTo(b['name']!));
      _processing[fileData['name']] = true;
    });

    try {
      fileData['url'] = await Yust.service.uploadFile(
        path: widget.folderPath,
        name: fileData['name']!,
        file: file,
        bytes: bytes,
      );
    } on YustException catch (e) {
      if (mounted) {
        Yust.service.showAlert(context, 'Ups', e.message);
      }
    } catch (e) {
      if (mounted) {
        Yust.service.showAlert(
            context, 'Ups', 'Die Datei konnte nicht hochgeladen werden.');
      }
    }
    if (fileData['url'] == null) {
      _files.remove(fileData);
    }
    _processing[fileData['name']] = false;
    if (mounted) {
      setState(() {});
    }
    widget.onChanged!(_files);
  }

  Future<void> _pickFiles() async {
    Yust.service.unfocusCurrent(context);
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      Yust.service.showAlert(context, 'Kein Internet',
          'Für das Hinzufügen einer Datei ist eine Internetverbindung erforderlich.');
    } else {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
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
            File? file;
            if (!kIsWeb && platformFile.path != null) {
              file = File(platformFile.path!);
            }
            await addFile(fileData, file, platformFile.bytes);
          }
          widget.onChanged!(_files);
        }
      }
    }
  }

  Future<void> _showFile(Map<String, String> file) async {
    Yust.service.unfocusCurrent(context);
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      Yust.service.showAlert(context, 'Kein Internet',
          'Für das Anzeigen einer Datei ist eine Internetverbindung erforderlich.');
      // is it a valid file?
    } else if (file['name'] != null && _processing[file['name']] != true) {
      // is the process running on mobile?
      if (!kIsWeb) {
        await EasyLoading.show(status: 'Datei laden...');
        try {
          final tempDir = await getTemporaryDirectory();
          await Dio().download(file['url']!, '${tempDir.path}/${file['name']}');
          var result = await OpenFile.open('${tempDir.path}/${file['name']}');
          // if cant open file type, tries via browser
          if (result.type != ResultType.done) {
            _launchBrowser(file);
          }

          await EasyLoading.dismiss();
        } catch (e) {
          await EasyLoading.dismiss();
          await Yust.service.showAlert(context, 'Ups',
              'Die Datei kann nicht geöffnet werden. ${e.toString()}');
        }
      } else {
        await EasyLoading.show(status: 'Datei laden...');
        _launchBrowser(file);
        await EasyLoading.dismiss();
      }
    }
  }

  Future<void> _launchBrowser(Map<String, String> file) async {
    if (await canLaunch(file['url']!)) {
      await launch(file['url']!);
    } else {
      await Yust.service
          .showAlert(context, 'Ups', 'Die Datei kann nicht geöffnet werden.');
    }
  }

  Future<void> _deleteFile(Map<String, String> file) async {
    Yust.service.unfocusCurrent(context);
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
              .child(file['name']!)
              .delete();
        } catch (e) {}

        setState(() {
          _files.remove(file);
        });
        widget.onChanged!(_files);
      }
    }
  }
}
