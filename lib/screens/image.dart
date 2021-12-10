import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

    final urlsArgs = arguments['urls'];
    List<String>? urls;

    if (urlsArgs is List) {
      urls = urlsArgs.whereType<String>().toList();
    }

    if (urls != null) {
      return _buildMultiple(context, urls, url, imageName);
    } else {
      return _buildSingle(context, url!, imageName);
    }
  }

  Widget _buildSingle(BuildContext context, String url, String imageName) {
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
      if (kIsWeb) _buildCloseButton(context),
      _buildShareButton(context, url, imageName),
    ]);
  }

  Widget _buildMultiple(BuildContext context, List<String> urls,
      String? activeUrl, String imageName) {
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
        if (kIsWeb) _buildCloseButton(context),
        _buildShareButton(context, activeUrl!, imageName),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
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
              Navigator.pop(context);
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
                  onPressed: () {
                    Yust.service.downloadAndLaunchFile(
                        context: context, url: url, name: imageName);
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
}
