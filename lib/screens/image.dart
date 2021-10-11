import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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
    if (urls != null) {
      return _buildMultiple(context, urls, url);
    } else {
      return _buildSingle(context, url!);
    }
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
            // backgroundDecoration: widget.backgroundDecoration,
            // onPageChanged: onPageChanged,
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
        if (kIsWeb)
          Container(
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
                },
              ),
            ),
          ),
      ],
    );
  }
}
