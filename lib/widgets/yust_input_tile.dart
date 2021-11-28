import 'package:flutter/material.dart';
import 'package:yust/widgets/yust_text_field.dart';
import 'package:yust/yust.dart';
import '../yust.dart';

typedef TapCallback = void Function();
typedef DeleteCallback = void Function();

class YustInputTile extends StatefulWidget {
  final String? label;
  final String? text;
  final TextStyle? textStyle;
  final Widget? prefixIcon;
  final Widget? child;
  final YustInputStyle style;
  final TapCallback? onTap;
  final DeleteCallback? onDelete;
  final Widget? suffixChild;

  const YustInputTile({
    Key? key,
    this.label,
    this.text,
    this.textStyle,
    this.prefixIcon,
    this.child,
    this.style = YustInputStyle.normal,
    this.onTap,
    this.onDelete,
    this.suffixChild,
  }) : super(key: key);

  @override
  State<YustInputTile> createState() => _YustInputTileState();
}

class _YustInputTileState extends State<YustInputTile> {
  @override
  Widget build(BuildContext context) {
    if (widget.style == YustInputStyle.normal) {
      return YustTextField(
        label: widget.label,
        value: widget.text,
        textStyle: widget.textStyle,
        readOnly: true,
        prefixIcon: widget.prefixIcon,
        suffixIcon: (widget.onDelete != null && widget.text != '')
            ? IconButton(
                onPressed: widget.onDelete!,
                icon: Icon(
                  Icons.delete,
                  color: Theme.of(context).primaryColor,
                ))
            : SizedBox(),
        onTap: () {
          widget.onTap;
        },
      );
    } else {
      return Text('Nicht normales Feld');
    }
  }

  // Widget build2(BuildContext context) {
  //   if (widget.style == YustInputStyle.normal) {
  //     return Column(
  //       children: [
  //         _buildInner(context),
  //         if (this.widget.suffixChild != null) this.widget.suffixChild!,
  //         Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
  //       ],
  //     );
  //   } else {
  //     return Container(
  //       decoration: BoxDecoration(
  //         border: Border.all(color: Colors.grey),
  //         borderRadius: BorderRadius.circular(4.0),
  //       ),
  //       child: _buildInner(context),
  //     );
  //   }
  // }

  // Widget _buildInner(BuildContext context) {
  //   var padding;
  //   if (widget.style == YustInputStyle.normal) {
  //     if (widget.label != null && widget.prefixIcon != null) {
  //       padding = const EdgeInsets.only(
  //           left: 8.0, top: 8.0, right: 16.0, bottom: 8.0);
  //     } else {
  //       padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
  //     }
  //   } else {
  //     padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0);
  //   }
  //   if (widget.label == null) {
  //     return ListTile(
  //       title: widget.child,
  //       onTap: widget.onTap,
  //       contentPadding: padding,
  //     );
  //   } else {
  //     return LayoutBuilder(builder: (context, constraints) {
  //       if (constraints.maxWidth > 270) {
  //         return ListTile(
  //           title: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               if (widget.prefixIcon != null)
  //                 Padding(
  //                   padding: const EdgeInsets.only(right: 8.0),
  //                   child: widget.prefixIcon,
  //                 ),
  //               Flexible(
  //                 child: Text(
  //                   widget.label ?? '',
  //                   overflow: TextOverflow.clip,
  //                   style: TextStyle(color: Colors.grey[600]),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           trailing: Container(
  //               constraints: BoxConstraints(
  //                   maxWidth: MediaQuery.of(context).size.width - 150),
  //               child: widget.child),
  //           onTap: widget.onTap,
  //           contentPadding: padding,
  //         );
  //       } else {
  //         return Column(
  //           mainAxisAlignment: MainAxisAlignment.start,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             ListTile(
  //               title: Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   if (widget.prefixIcon != null)
  //                     Padding(
  //                       padding: const EdgeInsets.only(right: 8.0),
  //                       child: widget.prefixIcon,
  //                     ),
  //                   Flexible(
  //                     child: Text(
  //                       widget.label ?? '',
  //                       style: TextStyle(color: Colors.grey[600]),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               onTap: widget.onTap,
  //               contentPadding: padding,
  //             ),
  //             Container(
  //                 constraints: BoxConstraints(
  //                     maxWidth: MediaQuery.of(context).size.width - 150),
  //                 child: widget.child),
  //           ],
  //         );
  //       }
  //     });
  //   }
  // }
}
