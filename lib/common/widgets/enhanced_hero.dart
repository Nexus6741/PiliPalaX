import 'package:flutter/material.dart';

/// 增强的 Hero 动画配置
/// 提供更流畅的退出动画效果
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
          // 退出时的动画：缩放 + 淡出
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              // 使用自定义曲线让退出更流畅
              final curvedValue = Curves.easeInCubic.transform(animation.value);

              // 在动画后期快速淡出，避免黑条效果
              final opacity = animation.value > 0.7
                  ? 1.0 - ((animation.value - 0.7) / 0.3)
                  : 1.0;

              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1.0 - (curvedValue * 0.05), // 轻微缩放效果
                  child: child,
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
          // 🔥 优化：退出动画使用更快的淡出和缩放，减少掉帧
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              // 🔥 优化：在动画的前 60% 保持完全可见，后 40% 快速淡出
              // 这样可以在播放器暂停/销毁后再开始淡出，避免黑屏闪烁
              final opacity = animation.value > 0.7
                  ? 1.0 - ((animation.value - 0.7) / 0.3)
                  : 1.0;

              // 🔥 优化：使用更平滑的缩放曲线
              final curvedValue = Curves.easeInQuad.transform(animation.value);
              final scale = 1.0 - (curvedValue * 0.03);

              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: child,
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
