import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:yust/yust.dart';

class ImageScreen extends StatelessWidget {
  static const String routeName = '/imageScreen';
  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)!.settings.arguments as Map;
    final String? url = arguments['url'];
    String imageName = arguments['name'];
    String? returnLocation = arguments['location'];
    final urlsArgs = arguments['urls'];
    List<String>? urls;

    if (urlsArgs is List) {
      urls = urlsArgs.whereType<String>().toList();
    }

    if (urls != null) {
      return _buildMultiple(context, urls, url, imageName, returnLocation);
    } else {
      return _buildSingle(context, url!, imageName, returnLocation);
    }
  }

  Widget _buildSingle(BuildContext context, String url, String imageName,
      [String? returnLocation]) {
    return Stack(children: [
      Container(
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
      ),
      if (kIsWeb) _buildCloseButton(context, returnLocation),
      _buildShareButton(context, url, imageName),
    ]);
  }

  Widget _buildMultiple(BuildContext context, List<String> urls,
      String? activeUrl, String imageName,
      [String? returnLocation]) {
    int firstPage = 0;
    if (activeUrl != null) {
      firstPage = urls.indexOf(activeUrl);
    }
    PageController _pageController = PageController(initialPage: firstPage);
    return Stack(
      children: [
        Container(
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
          ),
        ),
        if (kIsWeb)
          Container(
            padding: const EdgeInsets.all(20.0),
            alignment: Alignment.centerLeft,
            child: CircleAvatar(
              backgroundColor: Colors.black,
              radius: 25,
              child: IconButton(
                iconSize: 35,
                color: Colors.white,
                icon: Icon(
                  Icons.arrow_back_ios_new,
                ),
                onPressed: () {
                  _pageController.previousPage(
                    duration: new Duration(milliseconds: 500),
                    curve: Curves.easeOutSine,
                  );
                },
              ),
            ),
          ),
        if (kIsWeb)
          Container(
            padding: const EdgeInsets.all(20.0),
            alignment: Alignment.centerRight,
            child: CircleAvatar(
              backgroundColor: Colors.black,
              radius: 25,
              child: IconButton(
                iconSize: 35,
                color: Colors.white,
                icon: Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  _pageController.nextPage(
                    duration: new Duration(milliseconds: 500),
                    curve: Curves.easeOutSine,
                  );
                },
              ),
            ),
          ),
        if (kIsWeb) _buildCloseButton(context, returnLocation),
        _buildShareButton(context, activeUrl!, imageName),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context, [String? returnLocation]) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      alignment: Alignment.topRight,
      child: CircleAvatar(
        backgroundColor: Colors.black,
        radius: 25,
        child: IconButton(
            iconSize: 35,
            color: Colors.white,
            icon: Icon(Icons.close),
            onPressed: () {
              returnLocation == null
                  ? Navigator.pop(context)
                  : Navigator.pushReplacementNamed(context, returnLocation);
            }),
      ),
    );
  }

  Widget _buildShareButton(BuildContext context, String url, String imageName) {
    return Positioned(
      right: kIsWeb ? 80.0 : 0.0,
      child: RepaintBoundary(
        child: Container(
          margin: EdgeInsets.all(20),
          child: CircleAvatar(
            backgroundColor: Colors.black,
            radius: 25,
            child: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  iconSize: 35,
                  color: Colors.white,
                  onPressed: () => {
                    kIsWeb
                        ? _downloadImage(url, imageName)
                        : _shareFile(context, url, imageName)
                  },
                  icon: kIsWeb ? Icon(Icons.download) : Icon(Icons.share),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareFile(
      BuildContext context, String url, String imageName) async {
    final box = context.findRenderObject() as RenderBox?;
    if (true) {
      await EasyLoading.show(status: 'Datei laden...');
      try {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/$imageName';
        await Dio().download(url, path);
        await Share.shareFiles(
          [path],
          subject: imageName,
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );

        await EasyLoading.dismiss();
      } catch (e) {
        await EasyLoading.dismiss();
        await Yust.service.showAlert(context, 'Ups',
            'Die Datei kann nicht geöffnet werden. ${e.toString()}');
      }
    }
  }

  Future<void> _downloadImage(String imageUrl, String imageName) async {
    try {
      final http.Response r = await http.get(
        Uri.parse(imageUrl),
      );

      final data = r.bodyBytes;
      final base64data = base64Encode(data);
      final a = html.AnchorElement(href: 'data:image/;base64,$base64data');
      a.download = imageName;
      a.click();
      a.remove();
    } catch (e) {
      print(e);
    }
  }
}
