import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/util/yust_file_handler.dart';
import 'package:yust/widgets/yust_input_tile.dart';

import '../yust.dart';

class YustFilePicker extends StatefulWidget {
  final String? label;

  final List<YustFile> files;

  /// Path to folder where the files are stored.
  final String storageFolderPath;

  /// [linkedDocPath] and [linkedDocAttribute] are needed for the offline compatibility.
  /// If not given, uploads are only possible with internet connection
  final String? linkedDocPath;

  /// [linkedDocPath] and [linkedDocAttribute] are needed for the offline compatibility.
  /// If not given, uploads are only possible with internet connection
  final String? linkedDocAttribute;

  final void Function(List<YustFile> files)? onChanged;

  final Widget? prefixIcon;

  final bool readOnly;

  YustFilePicker({
    Key? key,
    this.label,
    required this.files,
    required this.storageFolderPath,
    this.linkedDocPath,
    this.linkedDocAttribute,
    this.onChanged,
    this.prefixIcon,
    this.readOnly = false,
  }) : super(key: key);

  @override
  YustFilePickerState createState() => YustFilePickerState();
}

class YustFilePickerState extends State<YustFilePicker> {
  late YustFileHandler _fileHandler;

  late bool _enabled;

  @override
  void initState() {
    _fileHandler = YustFileHandler(
      storageFolderPath: widget.storageFolderPath,
      linkedDocAttribute: widget.linkedDocAttribute,
      linkedDocPath: widget.linkedDocPath,
    );
    _enabled = (widget.onChanged != null && !widget.readOnly);

    if (widget.files.isEmpty && _enabled) {
      widget.onChanged!([]);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fileHandler.updateFiles(widget.files),
      builder: (context, snapshot) {
        return YustInputTile(
            child: _buildAddButton(context),
            label: widget.label,
            prefixIcon: widget.prefixIcon,
            suffixChild: _buildFiles(context));
      },
    );
  }

  _buildAddButton(BuildContext context) {
    if (!_enabled) {
      return SizedBox.shrink();
    }
    return IconButton(
      icon: Icon(Icons.add, color: Theme.of(context).colorScheme.secondary),
      onPressed: _enabled ? _pickFiles : null,
    );
  }

  Widget _buildFiles(BuildContext context) {
    List<YustFile> _files = _fileHandler.getFiles();
    _files.sort((a, b) => (a.name).compareTo(b.name));
    return Column(
      children: _files.map((file) => _buildFile(context, file)).toList(),
    );
  }

  Widget _buildFile(BuildContext context, YustFile file) {
    return ListTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file),
          SizedBox(width: 8),
          Expanded(
            child: Text(file.name, overflow: TextOverflow.ellipsis),
          ),
          _buildCachedIndicator(file),
        ],
      ),
      trailing: _buildDeleteButton(file),
      onTap: () {
        Yust.service.unfocusCurrent(context);
        _fileHandler.showFile(context, file);
      },
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }

  Widget _buildDeleteButton(YustFile file) {
    if (!_enabled) {
      return SizedBox.shrink();
    }
    if (file.processing == true) {
      return CircularProgressIndicator();
    }
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: _enabled ? () => _deleteFile(file) : null,
    );
  }

  Widget _buildCachedIndicator(YustFile file) {
    if (!file.cached || !_enabled) {
      return SizedBox.shrink();
    }
    if (file.processing == true) {
      return CircularProgressIndicator();
    }
    return IconButton(
      icon: Icon(Icons.cloud_upload_outlined),
      color: Colors.black,
      onPressed: () async {
        await Yust.service.showAlert(context, 'Lokal gespeicherte Datei',
            'Diese Datei ist noch nicht hochgeladen.');
      },
    );
  }

  Future<void> _pickFiles() async {
    Yust.service.unfocusCurrent(context);
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      for (final platformFile in result.files) {
        await uploadFile(
          name: _getFileName(platformFile),
          file: _platformFileToFile(platformFile),
          bytes: platformFile.bytes,
        );
      }
    }
  }

  Future<void> uploadFile({
    required String name,
    File? file,
    Uint8List? bytes,
  }) async {
    final newYustFile = YustFile(
      name: name,
      file: file,
      bytes: bytes,
      storageFolderPath: widget.storageFolderPath,
      linkedDocPath: widget.linkedDocPath,
      linkedDocAttribute: widget.linkedDocAttribute,
    );

    if (_fileHandler.getFiles().any((file) => file.name == newYustFile.name)) {
      Yust.service.showAlert(context, 'Nicht möglich',
          'Eine Datei mit dem Namen ${newYustFile.name} existiert bereits.');
    } else {
      await _fileHandler.addFile(newYustFile);
    }
    if (!newYustFile.cached) {
      widget.onChanged!(_fileHandler.getOnlineFiles());
    } else {
      setState(() {});
    }
  }

  Future<void> _deleteFile(YustFile yustFile) async {
    Yust.service.unfocusCurrent(context);
    final confirmed = await Yust.service
        .showConfirmation(context, 'Wirklich löschen?', 'Löschen');
    if (confirmed == true) {
      try {
        await _fileHandler.deleteFile(yustFile);
        if (!yustFile.cached) {
          widget.onChanged!(_fileHandler.getOnlineFiles());
        } else {
          setState(() {});
        }
      } catch (e) {
        await Yust.service.showAlert(context, 'Ups',
            'Die Datei kann nicht gelöscht werden. ${e.toString()}');
      }
    }
  }

  String _getFileName(PlatformFile platformFile) {
    var name = platformFile.name.split('/').last;
    final ext = platformFile.extension;
    if (ext != null && name.split('.').last != ext) {
      name += '.' + ext;
    }
    return name;
  }

  File? _platformFileToFile(PlatformFile platformFile) {
    if (!kIsWeb && platformFile.path != null) {
      return File(platformFile.path!);
    }
  }
}
