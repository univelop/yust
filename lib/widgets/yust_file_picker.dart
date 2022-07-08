import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/util/yust_file_handler.dart';
import 'package:yust/widgets/yust_list_tile.dart';
import '../yust.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:dotted_border/dotted_border.dart';

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

  final bool enableDropzone;

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
    this.enableDropzone = false,
    this.readOnly = false,
  }) : super(key: key);

  @override
  YustFilePickerState createState() => YustFilePickerState();
}

class YustFilePickerState extends State<YustFilePicker> {
  late YustFileHandler _fileHandler;
  final Map<String?, bool> _processing = {};
  late DropzoneViewController controller;
  var isDragging = false;
  late bool _enabled;

  @override
  void initState() {
    _fileHandler = Yust.fileHandlerManager.createFileHandler(
      storageFolderPath: widget.storageFolderPath,
      linkedDocAttribute: widget.linkedDocAttribute,
      linkedDocPath: widget.linkedDocPath,
      onFileUploaded: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    _enabled = (widget.onChanged != null && !widget.readOnly);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _enabled = widget.onChanged != null && !widget.readOnly;
    return FutureBuilder(
      future: _fileHandler.updateFiles(widget.files),
      builder: (context, snapshot) {
        if (kIsWeb && widget.enableDropzone) {
          return _buildDropzone(context);
        } else {
          return YustListTile(
              suffixChild: _buildAddButton(context),
              label: widget.label,
              prefixIcon: widget.prefixIcon,
              below: _buildFiles(context));
        }
      },
    );
  }

  Widget _buildDropzone(BuildContext context) {
    final _files = _fileHandler.getFiles();
    return Stack(
      children: [
        Positioned.fill(
          child: _buildDropzoneArea(context),
        ),
        YustListTile(
          suffixChild:
              isDragging ? _buildDropzoneInterface() : _buildAddButton(context),
          label: widget.label,
          prefixIcon: widget.prefixIcon,
          below: _buildFiles(context),
        ),
      ],
    );
  }

  /// This widget will accept files from a drag and drop interaction
  Widget _buildDropzoneArea(BuildContext context) => Builder(
        builder: (context) => DropzoneView(
          operation: DragOperation.copy,
          cursor: CursorType.grab,
          onCreated: (ctrl) => controller = ctrl,
          onLoaded: () => null,
          onError: (ev) => null,
          onHover: () {
            setState(() {
              isDragging = true;
            });
          },
          onLeave: () {
            setState(() {
              isDragging = false;
            });
          },
          onDrop: (ev) async {},
          onDropMultiple: (ev) async {
            setState(() {
              isDragging = false;
            });
            for (final file in ev ?? []) {
              final bytes = await controller.getFileData(file);
              await uploadFile(name: file.name, file: null, bytes: bytes);
            }
            ;
          },
        ),
      );

  /// This Widget is a visual drag and drop indicator. It shows a dotted box, an icon as well as a button to manually upload files
  Widget _buildDropzoneInterface() {
    final dropZoneColor =
        isDragging ? Colors.blue : Color.fromARGB(255, 116, 116, 116);
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(100, 2, 2, 2),
        child: DottedBorder(
          borderType: BorderType.RRect,
          radius: Radius.circular(12),
          padding: EdgeInsets.all(6),
          dashPattern: [6, 5],
          strokeWidth: 3,
          strokeCap: StrokeCap.round,
          color: dropZoneColor,
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            child: Container(
              height: 200,
              width: 400,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 35, color: dropZoneColor),
                  Text(
                    'Datei(en) hierher ziehen',
                    style: TextStyle(fontSize: 20, color: dropZoneColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
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
    var _files = _fileHandler.getFiles();
    _files.sort((a, b) => (a.name!).compareTo(b.name!));
    return Column(
      children: _files.map((file) => _buildFile(context, file)).toList(),
    );
  }

  Widget _buildFile(BuildContext context, YustFile file) {
    final isBroken = file.name == null ||
        (file.cached && file.bytes == null && file.file == null) ||
        (kIsWeb && file.url == null && file.bytes == null && file.file == null);
    return ListTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(!isBroken ? Icons.insert_drive_file : Icons.dangerous),
          SizedBox(width: 8),
          Expanded(
            child: Text(isBroken ? 'Fehlerhafte Datei' : file.name!,
                overflow: TextOverflow.ellipsis),
          ),
          _buildCachedIndicator(file),
        ],
      ),
      trailing: _buildDeleteButton(file),
      onTap: () {
        Yust.helperService.unfocusCurrent(context);
        if (!isBroken) {
          _fileHandler.showFile(context, file);
        }
      },
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }

  Widget _buildDeleteButton(YustFile file) {
    if (!_enabled) {
      return SizedBox.shrink();
    }
    if (_processing[file.name] == true) {
      return CircularProgressIndicator();
    }
    return IconButton(
      icon: Icon(Icons.delete),
      color: Theme.of(context).colorScheme.primary,
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
        await Yust.alertService.showAlert(context, 'Lokal gespeicherte Datei',
            'Diese Datei ist noch nicht hochgeladen.');
      },
    );
  }

  Future<void> _pickFiles() async {
    Yust.helperService.unfocusCurrent(context);
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
    _processing[newYustFile.name] = true;

    if (_fileHandler.getFiles().any((file) => file.name == newYustFile.name)) {
      await Yust.alertService.showAlert(context, 'Nicht möglich',
          'Eine Datei mit dem Namen ${newYustFile.name} existiert bereits.');
    } else {
      await _createDatebaseEntry();
      await _fileHandler.addFile(newYustFile);
    }
    _processing[newYustFile.name] = false;
    if (!newYustFile.cached) {
      widget.onChanged!(_fileHandler.getOnlineFiles());
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _createDatebaseEntry() async {
    try {
      if (widget.linkedDocPath != null &&
          !_fileHandler.existsDocData(
              await _fileHandler.getFirebaseDoc(widget.linkedDocPath!))) {
        widget.onChanged!(_fileHandler.getOnlineFiles());
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> _deleteFile(YustFile yustFile) async {
    Yust.helperService.unfocusCurrent(context);
    final confirmed = await Yust.alertService
        .showConfirmation(context, 'Wirklich löschen?', 'Löschen');
    if (confirmed == true) {
      try {
        await _fileHandler.deleteFile(yustFile);
        if (!yustFile.cached) {
          widget.onChanged!(_fileHandler.getOnlineFiles());
        }
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        await Yust.alertService.showAlert(context, 'Ups',
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
    return (!kIsWeb && platformFile.path != null)
        ? File(platformFile.path!)
        : null;
  }
}
