import 'package:flutter/material.dart';

/// 增强的 Hero 动画配置
/// 提供更流畅灵动的退出动画效果
class EnhancedHero extends StatelessWidget {
  final String tag;
  final Widget child;
  final bool enabled;

  const EnhancedHero({
    super.key,
    required this.tag,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Hero(
      tag: tag,
      // 自定义飞行动画构建器
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        // 根据飞行方向选择不同的动画效果
        if (flightDirection == HeroFlightDirection.pop) {
          // 退出时的动画：缩放 + 淡出 + 轻微偏移
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              // 🔥 优化：分段淡出，更自然
              // 前60%保持完全可见，60-85%缓慢淡出，最后15%快速淡出
              final opacity = animation.value < 0.6
                  ? 1.0
                  : animation.value < 0.85
                      ? 1.0 - ((animation.value - 0.6) / 0.25) * 0.4
                      : 0.6 - ((animation.value - 0.85) / 0.15) * 0.6;

              // 🔥 优化：使用更流畅的缩放曲线
              final curvedValue =
                  Curves.easeInOutCubic.transform(animation.value);
              final scale = 1.0 - (curvedValue * 0.06); // 增加缩放幅度

              // 🔥 新增：轻微的Y轴偏移，增加灵动感
              final translateY =
                  animation.value > 0.65 ? (animation.value - 0.65) * 15 : 0.0;

              return Transform.translate(
                offset: Offset(0, translateY),
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                ),
              );
            },
            child: Material(
              type: MaterialType.transparency,
              child: toHeroContext.widget,
            ),
          );
        } else {
          // 进入时的动画：使用默认效果
          return Material(
            type: MaterialType.transparency,
            child: toHeroContext.widget,
          );
        }
      },
      // 自定义占位符构建器，避免闪烁
      placeholderBuilder: (context, heroSize, child) {
        return SizedBox(
          width: heroSize.width,
          height: heroSize.height,
          child: Opacity(
            opacity: 0.0,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// 创建自定义的页面路由过渡动画
/// 配合 Hero 使用，提供更流畅的整体过渡效果
class EnhancedPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration transitionDuration;
  final Duration reverseTransitionDuration;

  EnhancedPageRoute({
    required this.page,
    RouteSettings? settings,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 250),
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: transitionDuration,
          reverseTransitionDuration: reverseTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 进入动画：淡入 + 轻微缩放
            if (secondaryAnimation.status == AnimationStatus.dismissed) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.03),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            }

            // 退出动画：快速淡出
            return FadeTransition(
              opacity: Tween<double>(
                begin: 1.0,
                end: 0.0,
              ).animate(CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeIn,
              )),
              child: child,
            );
          },
        );
}

/// 视频详情页专用的 Hero 动画配置
class VideoHero extends StatelessWidget {
  final String tag;
  final Widget child;
  final double? width;
  final double? height;

  const VideoHero({
    super.key,
    required this.tag,
    required this.child,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      // 🔥 优化：创建退出时的过渡动画，避免播放器干扰
      createRectTween: (Rect? begin, Rect? end) {
        return RectTween(begin: begin, end: end);
      },
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        if (flightDirection == HeroFlightDirection.pop) {
          // 🔥 优化：退出动画使用更灵动的淡出和缩放效果
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              // 🔥 优化：分段淡出策略，更自然流畅
              // 前50%保持完全可见，50-85%缓慢淡出，最后15%快速淡出
              // final opacity = animation.value < 0.5
              //     ? 1.0
              //     : animation.value < 0.85
              //         ? 1.0 - ((animation.value - 0.5) / 0.35) * 0.3
              //         : 0.7 - ((animation.value - 0.85) / 0.15) * 0.7;

              // 🔥 优化：使用更有弹性的缩放曲线，增加灵动感
              // 使用 easeOutBack 曲线，在退出时有轻微的"回弹"效果
              final scaleValue = animation.value < 0.6
                  ? animation.value
                  : 0.6 + (animation.value - 0.6) * 1.5; // 后40%加速

              final curvedScale =
                  Curves.easeInOutCubic.transform(scaleValue.clamp(0.0, 1.0));
              final scale = 1.0 - (curvedScale * 0.05); // 轻微缩小

              // 🔥 新增：轻微的Y轴偏移，让退出更有层次感
              final translateY = animation.value > 0.7
                  ? (animation.value - 0.7) * 20 // 最后30%向下偏移
                  : 0.0;

              return Transform.translate(
                offset: Offset(0, translateY),
                child: Opacity(
                  opacity: 1,
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                ),
              );
            },
            // 🔥 优化：使用静态图片而不是实际的播放器组件
            child: Material(
              type: MaterialType.transparency,
              child: toHeroContext.widget,
            ),
          );
        }

        // 进入动画：标准效果
        return DefaultTextStyle(
          style: DefaultTextStyle.of(toHeroContext).style,
          child: toHeroContext.widget,
        );
      },
      // 🔥 优化：占位符使用透明度为0，避免闪烁
      placeholderBuilder: (context, heroSize, child) {
        return SizedBox(
          width: heroSize.width,
          height: heroSize.height,
          child: Opacity(
            opacity: 0.0,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
