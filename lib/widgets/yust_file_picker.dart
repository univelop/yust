import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/util/yust_file_handler.dart';
import 'package:yust/widgets/yust_input_tile.dart';

import '../yust.dart';

class YustFilePicker extends StatefulWidget {
  final String? label;

  final List<Map<String, String?>> files;
  // TODO: Transform to List<YustFile> ?

  /// Path to folder where the files are stored.
  final String folderPath;

  /// [linkedDocPath] and [linkedDocAttribute] are needed for the offline compatibility.
  /// If not given, uploads are only possible with internet connection
  final String? linkedDocPath;

  /// [linkedDocPath] and [linkedDocAttribute] are needed for the offline compatibility.
  /// If not given, uploads are only possible with internet connection
  final String? linkedDocAttribute;

  final void Function(List<Map<String, String?>> files)? onChanged;

  final Widget? prefixIcon;

  final bool readOnly;

  YustFilePicker({
    Key? key,
    this.label,
    required this.files,
    required this.folderPath,
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
  late List<YustFile> _yustFiles;
  late bool _enabled;

  @override
  void initState() {
    _fileHandler = YustFileHandler(
      callback: () {
        _onChanged();
      },
    );
    _yustFiles =
        _fileHandler.yustFilesFromJson(widget.files, widget.folderPath);
    _enabled = (widget.onChanged != null && !widget.readOnly);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _fileHandler.mergeOnlineFiles(_yustFiles, widget.files, widget.folderPath);
    return FutureBuilder(
      future: _fileHandler.mergeCachedFiles(
        _yustFiles,
        widget.linkedDocPath,
        widget.linkedDocAttribute,
      ),
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
    return Column(
      children: _yustFiles.map((file) => _buildFile(context, file)).toList(),
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

  Future<void> _pickFiles() async {
    Yust.service.unfocusCurrent(context);
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      for (final platformFile in result.files) {
        final newYustFile = YustFile(
          name: _getFileName(platformFile),
          file: _platformFileToFile(platformFile),
          bytes: platformFile.bytes,
          storageFolderPath: widget.folderPath,
          linkedDocPath: widget.linkedDocPath,
          linkedDocAttribute: widget.linkedDocAttribute,
        );

        if (_yustFiles.any((file) => file.name == newYustFile.name)) {
          Yust.service.showAlert(context, 'Nicht möglich',
              'Eine Datei mit dem Namen ${newYustFile.name} existiert bereits.');
        } else {
          _yustFiles.add(newYustFile);
          _yustFiles.sort((a, b) => (a.name).compareTo(b.name));
          await _fileHandler.addFile(newYustFile);
        }
        _onChanged();
      }
    }
  }

  Future<void> _deleteFile(YustFile yustFile) async {
    Yust.service.unfocusCurrent(context);
    final confirmed = await Yust.service
        .showConfirmation(context, 'Wirklich löschen?', 'Löschen');
    if (confirmed == true) {
      try {
        await _fileHandler.deleteFile(_yustFiles, yustFile);
      } catch (e) {
        await Yust.service.showAlert(context, 'Ups',
            'Die Datei kann nicht gelöscht werden. ${e.toString()}');
      }
    }
  }

  void _onChanged() {
    final onlineFiles = _yustFiles.where((f) => f.cached == false).toList();
    widget.onChanged!(onlineFiles.map((file) => file.toJson()).toList());
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
    if (platformFile.path != null) {
      return File(platformFile.path!);
    }
  }
}
