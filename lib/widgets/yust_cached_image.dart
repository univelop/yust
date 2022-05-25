import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yust/models/yust_file.dart';
import 'package:yust/yust.dart';

class YustCachedImage extends StatelessWidget {
  final YustFile file;
  final String? cacheKey;
  final String? placeholder;
  final BoxFit? fit;
  final double? width;
  final double? height;
  const YustCachedImage({
    Key? key,
    required this.file,
    this.cacheKey,
    this.fit,
    this.height,
    this.width,
    this.placeholder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // define default preview
    Widget preview = Container(
      height: height ?? 150,
      width: width ?? 150,
      color: Colors.grey,
      child: Icon(Icons.question_mark),
    );

    if (file.file != null && file.bytes == null) {
      file.bytes = file.file!.readAsBytesSync();
    }

    if (file.bytes != null) {
      preview = Image.memory(
        file.bytes!,
        width: width,
        height: height,
        fit: fit,
      );
    } else if (file.url != null) {
      preview = CachedNetworkImage(
        // cacheKey is needed for recognizing switch from offline to online connection
        width: width,
        height: height,
        cacheKey: cacheKey,
        imageUrl: file.url!,
        imageBuilder: (context, image) {
          file.key ??= cacheKey;
          return Image(
            image: image,
            fit: fit,
          );
        },
        errorWidget: (context, _, __) =>
            Image.asset(placeholder ?? Yust.imagePlaceholderPath!, fit: fit),
        progressIndicatorBuilder: (context, url, downloadProgress) => Container(
          margin: EdgeInsets.all(50),
          child: CircularProgressIndicator(
            value: downloadProgress.progress,
          ),
        ),
        fit: fit,
      );
    }

    return preview;
  }
}
