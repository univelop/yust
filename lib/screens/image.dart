import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageScreen extends StatelessWidget {
  static const String routeName = '/imageScreen';

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context).settings.arguments;
    String url;
    List<String> urls;
    if (arguments is Map) {
      url = arguments['url'];
      urls = arguments['urls'];
    }
    if (url != null) {
      return _buildSingle(context, url);
    } else {
      return _buildMultiple(context, urls);
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
      ),
    );
  }

  Widget _buildMultiple(BuildContext context, List<String> urls) {
    return Container(
      child: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
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
        itemCount: urls.length,
        loadingBuilder: (context, event) => Center(
          child: Container(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes,
            ),
          ),
        ),
        // backgroundDecoration: widget.backgroundDecoration,
        // pageController: widget.pageController,
        // onPageChanged: onPageChanged,
      ),
    );
  }
}
