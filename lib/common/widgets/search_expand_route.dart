import 'package:flutter/material.dart';
import 'package:PiliPalaX/pages/search/view.dart';

/// 搜索框展开动画路由
/// 从搜索框位置展开成全屏页面
class SearchExpandPageRoute extends PageRouteBuilder<void> {
  final Rect sourceRect;
  final String hintText;
  final bool isCircular; // 是否从圆形图标展开

  SearchExpandPageRoute({
    required this.sourceRect,
    required this.hintText,
    this.isCircular = false,
  }) : super(
          settings: RouteSettings(
            name: '/search',
            arguments: {'hintText': hintText},
          ),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SearchPage(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          opaque: true,
          barrierDismissible: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _SearchExpandTransition(
              animation: animation,
              sourceRect: sourceRect,
              isCircular: isCircular,
              child: child,
            );
          },
        );
}

class _SearchExpandTransition extends StatelessWidget {
  final Animation<double> animation;
  final Rect sourceRect;
  final Widget child;
  final bool isCircular;

  const _SearchExpandTransition({
    required this.animation,
    required this.sourceRect,
    required this.child,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 获取屏幕圆角（通常是设备的物理圆角）
    // 对于大多数现代手机，屏幕圆角约为 30-40px
    const double screenBorderRadius = 35.0;

    // 使用非线性曲线让动画更自然
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      child: RepaintBoundary(child: child),
      builder: (context, cachedChild) {
        final progress = curvedAnimation.value;

        // 计算当前的位置和大小
        // 从搜索框位置/大小 -> 全屏
        final currentLeft = sourceRect.left * (1 - progress);
        final currentTop = sourceRect.top * (1 - progress);
        final currentWidth =
            sourceRect.width + (screenSize.width - sourceRect.width) * progress;
        final currentHeight = sourceRect.height +
            (screenSize.height - sourceRect.height) * progress;

        // 圆角变化：
        // 如果是圆形图标：从圆形(半径=宽度/2) -> 屏幕圆角(35) -> 0
        // 如果是搜索框：从搜索框圆角(25) -> 屏幕圆角(35) -> 0
        double borderRadius;
        final initialRadius = isCircular ? sourceRect.width / 2 : 25.0;

        if (progress < 0.85) {
          // 前85%：从初始圆角过渡到屏幕圆角
          final t = progress / 0.85;
          borderRadius =
              initialRadius + (screenBorderRadius - initialRadius) * t;
        } else {
          // 后15%：从屏幕圆角快速过渡到0
          final t = (progress - 0.85) / 0.15;
          borderRadius = screenBorderRadius * (1 - t);
        }

        // 内容透明度：
        // 展开时：0.0 - 0.7: 完全透明（隐藏内容，避免变形）
        //        0.7 - 1.0: 快速淡入
        // 关闭时：1.0 - 0.2: 保持可见
        //        0.2 - 0.0: 快速淡出（避免黑条效果）
        final contentOpacity = progress < 0.7 ? 0.0 : (progress - 0.7) / 0.3;

        // 整体透明度：在关闭动画的最后阶段淡出
        // 1.0 - 0.15: 完全不透明
        // 0.15 - 0.0: 快速淡出
        final overallOpacity = progress < 0.15 ? progress / 0.15 : 1.0;

        return Stack(
          children: [
            Positioned(
              left: currentLeft,
              top: currentTop,
              width: currentWidth,
              height: currentHeight,
              child: Opacity(
                opacity: overallOpacity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Stack(
                    children: [
                      // 背景色（在内容淡入前显示）
                      Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      // 实际内容（延迟显示）
                      Opacity(
                        opacity: contentOpacity,
                        child: cachedChild!,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
