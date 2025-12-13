import 'dart:ui';
import 'package:flutter/material.dart';

/// 毛玻璃（亚克力）效果容器
/// 提供类似 Windows 11 Acrylic 的视觉效果
class FrostedGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double opacity;

  const FrostedGlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.opacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withOpacity(opacity)
            : Colors.white.withOpacity(opacity));

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: borderRadius,
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 视频卡片专用的半透明渐变效果
/// 针对视频卡片底部信息区域优化，轻量级实现
class VideoCardFrostedGlass extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const VideoCardFrostedGlass({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.65),
                ]
              : [
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.75),
                ],
        ),
      ),
      child: child,
    );
  }
}

/// 轻量级毛玻璃效果
/// 适用于需要更透明、更轻盈的场景
class LightFrostedGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const LightFrostedGlass({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.3),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
