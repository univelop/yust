import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share/share.dart';
import 'package:yust/yust.dart';

class ImageScreen extends StatelessWidget {
  static const String routeName = '/imageScreen';

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)!.settings.arguments;
    String? url;
    List<String>? urls;
    if (arguments is Map) {
      url = arguments['url'];
      final urlsArgs = arguments['urls'];
      if (urlsArgs is List) {
        urls = urlsArgs.whereType<String>().toList();
      }
    }
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.black,
          actionsIconTheme:
              IconThemeData(color: Theme.of(context).primaryColor, size: 30.0),
          actions: [
            (kIsWeb)
                ? IconButton(
                    onPressed: () => OpenFile.open('url'),
                    icon: Icon(Icons.download))
                : IconButton(
                    onPressed: () => (_shareFile(context, url!)),
                    icon: Icon(Icons.share),
                  )
          ]),
      body: (urls != null)
          ? _buildMultiple(context, urls, url)
          : _buildSingle(context, url!),
    );
  }

  Widget _buildSingle(BuildContext context, String url) {
    return Container(
      child: PhotoView(
        imageProvider: NetworkImage(url),
        minScale: PhotoViewComputedScale.contained,
        heroAttributes: PhotoViewHeroAttributes(tag: url),
        onTapUp: (context, details, controllerValue) {
          Navigator.pop(context);
        },
        loadingBuilder: (context, event) => Center(
          child: Container(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiple(
      BuildContext context, List<String> urls, String? activeUrl) {
    int firstPage = 0;
    if (activeUrl != null) {
      firstPage = urls.indexOf(activeUrl);
    }
    PageController _pageController = PageController(initialPage: firstPage);
    return Container(
      child: PhotoViewGallery.builder(
        itemCount: urls.length,
        scrollPhysics: const BouncingScrollPhysics(),
        pageController: _pageController,
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(urls[index]),
            minScale: PhotoViewComputedScale.contained,
            heroAttributes: PhotoViewHeroAttributes(tag: urls[index]),
            onTapUp: (context, details, controllerValue) {
              Navigator.pop(context);
            },
          );
        },
        loadingBuilder: (context, event) => Center(
          child: Container(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(),
          ),
        ),
        // backgroundDecoration: widget.backgroundDecoration,
        // onPageChanged: onPageChanged,
      ),
    );
  }

  Future<void> _shareFile(BuildContext context, String url) async {
    final String name = Yust.service.randomString();
    if (true) {
      await EasyLoading.show(status: 'Datei laden...');
      try {
        final tempDir = await getTemporaryDirectory();
        await Dio().download(url, '${tempDir.path}/' + name);
        await Share.shareFiles(['${tempDir.path}/' + name], subject: name);
        await EasyLoading.dismiss();
      } catch (e) {
        await EasyLoading.dismiss();
        await Yust.service.showAlert(context, 'Ups',
            'Die Datei kann nicht geöffnet werden. ${e.toString()}');
      }
    }
  }
}
