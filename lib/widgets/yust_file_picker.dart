import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/util/yust_file_handler.dart';
import 'package:yust/util/yust_offline_cache.dart';
import 'package:yust/widgets/yust_input_tile.dart';
import 'package:dio/dio.dart';
import '../yust.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class YustFilePicker extends StatefulWidget {
  final String? label;
  final String folderPath;

  /// [pathToDoc] and [docAttribute] are needed for the offline compatibility.
  /// If not given, uploads are only possible with internet connection
  final String? pathToDoc;

  /// [pathToDoc] and [docAttribute] are needed for the offline compatibility.
  /// If not given, uploads are only possible with internet connection
  final String? docAttribute;
  final List<Map<String, String?>> files;
  final void Function(List<Map<String, String?>> files)? onChanged;
  final Widget? prefixIcon;
  final bool readOnly;

  YustFilePicker({
    Key? key,
    this.label,
    required this.folderPath,
    this.pathToDoc,
    this.docAttribute,
    required this.files,
    this.onChanged,
    this.prefixIcon,
    this.readOnly = false,
  }) : super(key: key);

  @override
  YustFilePickerState createState() => YustFilePickerState();
}

class YustFilePickerState extends State<YustFilePicker> {
  late List<YustFile> _files;
  late bool _enabled;
  late YustFileHandler fileHandler;

  @override
  void initState() {
    _files =
        widget.files.map<YustFile>((file) => YustFile.fromJson(file)).toList();

    _enabled = (widget.onChanged != null && !widget.readOnly);
    fileHandler = YustFileHandler(
      files: _files,
      folderPath: widget.folderPath,
      docAttribute: widget.docAttribute,
      pathToDoc: widget.pathToDoc,
      onChanged: _onChanged,
      changeCallback: (files) {
        setState(
          () {
            _files = files;
          },
        );
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: fileHandler.loadFiles(
          widget.files
              .map<YustFile>((file) => YustFile.fromJson(file))
              .toList(),
        ),
        builder: (context, snapshot) {
          _files = fileHandler.files;
          if (snapshot.connectionState != ConnectionState.done) {
            return SizedBox.shrink();
          }
          return YustInputTile(
              child: _buildAddButton(context),
              label: widget.label,
              prefixIcon: widget.prefixIcon,
              suffixChild: _buildFiles(context));
        });
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
        ],
      ),
      trailing: _buildDeleteButton(file),
      onTap: () => _showFile(file),
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
      onPressed: _enabled ? () => fileHandler.deleteFile(file, context) : null,
    );
  }

  Future<void> _pickFiles() async {
    Yust.service.unfocusCurrent(context);
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none &&
        !_isOfflineUploadPossible()) {
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

          if (_files.any((file) => file.name == name)) {
            Yust.service.showAlert(context, 'Nicht möglich',
                'Eine Datei mit dem Namen ${name} existiert bereits.');
          } else {
            File? file;
            if (platformFile.path != null) {
              file = File(platformFile.path!);
            }

            await fileHandler.uploadFile(
              name: name,
              file: file,
              bytes: platformFile.bytes,
              mounted: mounted,
              context: context,
            );

            setState(() {
              _files.sort((a, b) => (a.name).compareTo(b.name));
            });
          }

          _onChanged(_files);
        }
      }
    }
  }

  Future<void> _showFile(YustFile file) async {
    Yust.service.unfocusCurrent(context);
    final connectivityResult = await Connectivity().checkConnectivity();
    if (file.file == null && YustOfflineCache.isLocalPath(file.url ?? '')) {
      Yust.service.showAlert(context, 'Nicht vorhanden',
          'Die ausgewählte Date wird soeben von einem anderem Gerät hochgeladen. Versuche es später nocheinmal.');
    } else if (connectivityResult == ConnectivityResult.none) {
      Yust.service.showAlert(context, 'Kein Internet',
          'Für das Anzeigen einer Datei ist eine Internetverbindung erforderlich.');
      // is it a valid file?
    } else if (file.processing == false) {
      // is the process running on mobile?
      if (!kIsWeb) {
        await EasyLoading.show(status: 'Datei laden...');
        try {
          final tempDir = await getTemporaryDirectory();
          await Dio().download(file.url!, '${tempDir.path}/${file.name}');
          var result = await OpenFile.open('${tempDir.path}/${file.name}');
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

  Future<void> _launchBrowser(YustFile file) async {
    if (await canLaunch(file.url!)) {
      await launch(file.url!);
    } else {
      await Yust.service
          .showAlert(context, 'Ups', 'Die Datei kann nicht geöffnet werden.');
    }
  }

  /// removes file.urls that are paths to a folder
  void _onChanged(List<YustFile> onlineFiles) {
    onlineFiles
        .removeWhere((file) => YustOfflineCache.isLocalPath(file.url ?? ''));

    widget.onChanged!(onlineFiles.map((file) => file.toJson()).toList());
  }

  bool _isOfflineUploadPossible() {
    return widget.docAttribute != null && widget.pathToDoc != null;
  }
}
