import 'package:flutter/material.dart';

import '../yust.dart';

class YustInputTile extends StatelessWidget {
  final String? label;
  final Widget? prefixIcon;
  final Widget child;
  final YustInputStyle style;
  final void Function()? onTap;
  final Widget? suffixChild;

  const YustInputTile({
    Key? key,
    this.label,
    this.prefixIcon,
    required this.child,
    this.style = YustInputStyle.normal,
    this.onTap,
    this.suffixChild,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (style == YustInputStyle.normal) {
      return Column(
        children: [
          _buildInner(context),
          if (this.suffixChild != null) this.suffixChild!,
          Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
        ],
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: _buildInner(context),
      );
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
    if (label == null) {
      return ListTile(
        title: child,
        onTap: onTap,
        contentPadding: padding,
      );
    } else {
      return LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 270) {
          return ListTile(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prefixIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: prefixIcon,
                  ),
                Flexible(
                  child: Text(
                    label ?? '',
                    overflow: TextOverflow.clip,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            trailing: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 150),
                child: child),
            onTap: onTap,
            contentPadding: padding,
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prefixIcon != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
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
                onTap: onTap,
                contentPadding: padding,
              ),
              Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 150),
                  child: child),
            ],
          );
        }
      });
    }
  }
}
