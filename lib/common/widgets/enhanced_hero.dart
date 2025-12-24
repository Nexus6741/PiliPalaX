import 'package:flutter/material.dart';

/// 🔥 性能优化：共享的占位符构建器，避免代码重复
/// 使用 SizedBox 保持布局空间，但不渲染内容
Widget _buildTransparentPlaceholder(
  BuildContext context,
  Size heroSize,
  Widget child,
) {
  return SizedBox(
    width: heroSize.width,
    height: heroSize.height,
    // 🔥 不使用 Opacity(0.0)，直接返回空的 SizedBox 更高效
  );
}

/// 增强的 Hero 动画配置
/// 性能优化版本：移除复杂的变换效果，使用最简洁的实现
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
      // 🔥 性能优化：使用默认的 Hero 动画，不添加额外的变换
      // 移除了 flightShuttleBuilder，减少每帧的计算开销
      placeholderBuilder: _buildTransparentPlaceholder,
      child: child,
    );
  }
}

/// 视频详情页专用的 Hero 动画配置
/// 性能优化版本：移除复杂的变换效果
class VideoHero extends StatelessWidget {
  final String tag;
  final Widget child;

  const VideoHero({
    super.key,
    required this.tag,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      // 🔥 性能优化：使用默认的 Hero 动画
      // 移除了复杂的 flightShuttleBuilder，大幅减少 CPU 开销
      placeholderBuilder: _buildTransparentPlaceholder,
      child: child,
    );
  }
}
