import 'package:flutter/material.dart';
import 'package:yust/yust.dart';

typedef TapCallback = void Function();

class YustListTile extends StatelessWidget {
  final String? label;

  /// If navigate is set, the SuffixChild will display a Navigation Icon
  final bool navigate;
  final Widget? suffixChild;
  final TapCallback? onTap;
  final YustInputStyle style;
  final Widget? prefixIcon;
  final Widget? below;
  final bool divider;

  const YustListTile({
    Key? key,
    this.label,
    this.navigate = false,
    this.suffixChild,
    this.onTap,
    this.style = YustInputStyle.normal,
    this.prefixIcon,
    this.below,
    this.divider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (style == YustInputStyle.normal) {
      return Column(
        children: <Widget>[
          _buildInner(context),
          below ?? SizedBox(),
          if (divider) Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
        ],
      );
    } else {
      return Text('Anderer Style');
      // return Container(
      //   decoration: BoxDecoration(
      //     border: Border.all(color: Colors.grey),
      //     borderRadius: BorderRadius.circular(4.0),
      //   ),
      //   child: _buildInner(context),
      // );
    }
  }

  Widget _buildInner(BuildContext context) {
    var padding;
    if (style == YustInputStyle.normal) {
      if (label != null && prefixIcon != null) {
        padding = const EdgeInsets.only(
            left: 8.0, top: 8.0, right: 16.0, bottom: 8.0);
      } else {
        padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
      }
    } else {
      padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0);
    }
    return ListTile(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefixIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, left: 3.0),
              child: prefixIcon,
            ),
          Flexible(
            child: Text(
              label ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      trailing: navigate
          ? Icon(
              Icons.navigate_next,
              color: Theme.of(context).primaryColor,
            )
          : suffixChild,
      onTap: onTap,
      contentPadding: padding,
    );
  }
}
