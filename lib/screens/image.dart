import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../yust.dart';

class ImageScreen extends StatelessWidget {
  static const String routeName = '/imageScreen';

  @override
  Widget build(BuildContext context) {
    final url = ModalRoute.of(context).settings.arguments;

    if (kIsWeb) {
      return _buildBrowser(context, url);
    } else {
      return _buildSmartphone(context, url);
    }
  }

  Widget _buildBrowser(BuildContext context, String url) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: FadeInImage.assetNetwork(
          placeholder: Yust.imagePlaceholderPath,
          image: url,
        ),
      ),
    );
  }

  Widget _buildSmartphone(BuildContext context, String url) {
    return Container(
      child: PhotoView(
        imageProvider: NetworkImage(url),
        minScale: PhotoViewComputedScale.contained,
        onTapUp: (context, details, controllerValue) {
          Navigator.pop(context);
        },
      ),
    );
  }
}
