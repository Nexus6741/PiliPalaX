import 'package:flutter/material.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:PiliPalaX/plugin/pl_player/index.dart';
import 'send_danmaku_panel.dart';

/// 弹幕输入框组件 - 显示在视频播放器底部控制栏
class DanmakuInputBar extends StatelessWidget {
  final int cid;
  final String bvid;
  final PlPlayerController controller;
  final Function(DanmakuContentItem) onSendSuccess;

  const DanmakuInputBar({
    super.key,
    required this.cid,
    required this.bvid,
    required this.controller,
    required this.onSendSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDanmakuPanel(context),
      child: Container(
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '发个友善的弹幕见证当下',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDanmakuPanel(BuildContext context) {
    // 记录打开面板前的播放状态
    final bool wasPlaying =
        controller.playerStatus.status.value == PlayerStatus.playing;

    // 如果正在播放，则暂停
    if (wasPlaying) {
      controller.pause();
    }

    // 使用自定义的动画展示弹幕面板
    Navigator.of(context).push(
      DanmakuPanelRoute(
        cid: cid,
        bvid: bvid,
        progress: controller.position.value.inMilliseconds,
        onSendSuccess: onSendSuccess,
        wasPlaying: wasPlaying,
        playerController: controller,
      ),
    );
  }
}

/// 自定义路由动画 - 实现从底部输入框展开的效果
class DanmakuPanelRoute extends PopupRoute<void> {
  final int cid;
  final String bvid;
  final int progress;
  final Function(DanmakuContentItem) onSendSuccess;
  final bool wasPlaying;
  final PlPlayerController playerController;

  DanmakuPanelRoute({
    required this.cid,
    required this.bvid,
    required this.progress,
    required this.onSendSuccess,
    required this.wasPlaying,
    required this.playerController,
  });

  @override
  Color? get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return _DanmakuPanelPage(
      cid: cid,
      bvid: bvid,
      progress: progress,
      onSendSuccess: onSendSuccess,
      wasPlaying: wasPlaying,
      playerController: playerController,
      animation: animation,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class _DanmakuPanelPage extends StatefulWidget {
  final int cid;
  final String bvid;
  final int progress;
  final Function(DanmakuContentItem) onSendSuccess;
  final bool wasPlaying;
  final PlPlayerController playerController;
  final Animation<double> animation;

  const _DanmakuPanelPage({
    required this.cid,
    required this.bvid,
    required this.progress,
    required this.onSendSuccess,
    required this.wasPlaying,
    required this.playerController,
    required this.animation,
  });

  @override
  State<_DanmakuPanelPage> createState() => _DanmakuPanelPageState();
}

class _DanmakuPanelPageState extends State<_DanmakuPanelPage> {
  @override
  void dispose() {
    // 面板关闭时，如果之前是播放状态，则恢复播放
    if (widget.wasPlaying) {
      widget.playerController.play();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: widget.animation,
        builder: (context, child) {
          // 使用曲线动画
          final curvedAnimation = CurvedAnimation(
            parent: widget.animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return Stack(
            children: [
              // 背景遮罩
              Positioned.fill(
                child: FadeTransition(
                  opacity: curvedAnimation,
                  child: Container(color: Colors.transparent),
                ),
              ),
              // 弹幕面板
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(curvedAnimation),
                  child: FadeTransition(
                    opacity: curvedAnimation,
                    child: GestureDetector(
                      onTap: () {}, // 阻止点击穿透
                      child: Material(
                        color: Colors.transparent,
                        child: SendDanmakuPanel(
                          cid: widget.cid,
                          bvid: widget.bvid,
                          progress: widget.progress,
                          onSendSuccess: (item) {
                            widget.onSendSuccess(item);
                            Navigator.of(context).pop();
                          },
                          onPanelOpened: () {},
                          onPanelClosed: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
