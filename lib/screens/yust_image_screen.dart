import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/yust.dart';

class YustImageScreen extends StatefulWidget {
  final List<YustFile> files;

  final int activeImageIndex;

  YustImageScreen({
    Key? key,
    required this.files,
    this.activeImageIndex = 0,
  }) : super(key: key);

  static const String routeName = '/imageScreen';

  @override
  _YustImageScreenState createState() => _YustImageScreenState();
}

class _YustImageScreenState extends State<YustImageScreen> {
  late int activeImageIndex;
  late PageController _pageController;
  @override
  void initState() {
    activeImageIndex = widget.activeImageIndex;
    _pageController = PageController(initialPage: activeImageIndex);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.files.length == 1) {
      return _buildSingle(context);
    } else {
      return _buildMultiple(context);
    }
  }

  Widget _buildSingle(BuildContext context) {
    final file = widget.files.first;
    if (file.url == null) {
      return SizedBox.shrink();
    }
    return Stack(children: [
      Container(
        child: PhotoView(
          imageProvider: NetworkImage(file.url!),
          minScale: PhotoViewComputedScale.contained,
          heroAttributes: PhotoViewHeroAttributes(tag: file.url!),
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
      _buildShareButton(context, file),
    ]);
  }

  Widget _buildMultiple(BuildContext context) {
    return Stack(
      children: [
        Container(
          child: PhotoViewGallery.builder(
            itemCount: widget.files.length,
            scrollPhysics: const BouncingScrollPhysics(),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                activeImageIndex = index;
              });
            },
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(widget.files[index].url ?? ''),
                minScale: PhotoViewComputedScale.contained,
                heroAttributes:
                    PhotoViewHeroAttributes(tag: widget.files[index].url ?? ''),
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
                    duration: Duration(milliseconds: 500),
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
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeOutSine,
                  );
                },
              ),
            ),
          ),
        if (kIsWeb) _buildCloseButton(context),
        _buildShareButton(context, widget.files[activeImageIndex]),
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

  Widget _buildShareButton(BuildContext context, YustFile file) {
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
                    Yust.fileService.downloadAndLaunchFile(
                        context: context, url: file.url!, name: file.name!);
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
