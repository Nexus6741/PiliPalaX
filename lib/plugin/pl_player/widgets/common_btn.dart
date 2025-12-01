import 'package:flutter/material.dart';

class ComBtn extends StatelessWidget {
  final Widget? icon;
  final Function? fuc;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final double width;
  final double height;
  final String? tooltip;

  const ComBtn({
    this.icon,
    this.fuc,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.width = 34,
    this.height = 34,
    this.tooltip,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: width,
      height: height,
      child: InkWell(
        onTap: () {
          if (fuc != null) fuc!();
          if (onTap != null) onTap!();
        },
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        child: Center(child: icon),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}
