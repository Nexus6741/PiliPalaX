import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:hive/hive.dart';
import 'package:PiliPalaX/plugin/pl_player/index.dart';
import 'package:PiliPalaX/http/danmaku.dart';
import 'package:PiliPalaX/utils/storage.dart';

/// 弹幕输入框组件 - 显示在视频播放器底部控制栏
class DanmakuInputBar extends StatefulWidget {
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
  State<DanmakuInputBar> createState() => _DanmakuInputBarState();
}

class _DanmakuInputBarState extends State<DanmakuInputBar> {
  final GlobalKey _inputBarKey = GlobalKey();
  bool _isVisible = true;

  void _setVisible(bool visible) {
    if (mounted && _isVisible != visible) {
      setState(() {
        _isVisible = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDanmakuPanel(context),
      child: Opacity(
        opacity: _isVisible ? 1.0 : 0.0,
        child: Container(
          key: _inputBarKey,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '发个友善的弹幕见证当下',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDanmakuPanel(BuildContext context) {
    // 获取输入框的位置和大小
    final RenderBox? renderBox =
        _inputBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    // 记录打开面板前的播放状态
    final bool wasPlaying =
        widget.controller.playerStatus.status.value == PlayerStatus.playing;

    // 如果正在播放，则暂停
    if (wasPlaying) {
      widget.controller.pause();
    }

    // 隐藏底部输入框
    _setVisible(false);

    // 使用自定义的动画展示弹幕面板
    Navigator.of(context).push(
      DanmakuPanelRoute(
        cid: widget.cid,
        bvid: widget.bvid,
        progress: widget.controller.position.value.inMilliseconds,
        onSendSuccess: widget.onSendSuccess,
        wasPlaying: wasPlaying,
        playerController: widget.controller,
        sourcePosition: position,
        sourceSize: size,
        onSourceBarVisibilityChanged: _setVisible,
      ),
    );
  }
}

/// 自定义路由动画 - 实现输入框飞到中央展开的效果
class DanmakuPanelRoute extends PopupRoute<void> {
  final int cid;
  final String bvid;
  final int progress;
  final Function(DanmakuContentItem) onSendSuccess;
  final bool wasPlaying;
  final PlPlayerController playerController;
  final Offset sourcePosition;
  final Size sourceSize;
  final Function(bool)? onSourceBarVisibilityChanged;

  DanmakuPanelRoute({
    required this.cid,
    required this.bvid,
    required this.progress,
    required this.onSendSuccess,
    required this.wasPlaying,
    required this.playerController,
    required this.sourcePosition,
    required this.sourceSize,
    this.onSourceBarVisibilityChanged,
  });

  @override
  Color? get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 800);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 600);

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
      sourcePosition: sourcePosition,
      sourceSize: sourceSize,
      onSourceBarVisibilityChanged: onSourceBarVisibilityChanged,
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
  final Offset sourcePosition;
  final Size sourceSize;
  final Function(bool)? onSourceBarVisibilityChanged;

  const _DanmakuPanelPage({
    required this.cid,
    required this.bvid,
    required this.progress,
    required this.onSendSuccess,
    required this.wasPlaying,
    required this.playerController,
    required this.animation,
    required this.sourcePosition,
    required this.sourceSize,
    this.onSourceBarVisibilityChanged,
  });

  @override
  State<_DanmakuPanelPage> createState() => _DanmakuPanelPageState();
}

class _DanmakuPanelPageState extends State<_DanmakuPanelPage> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  final Box<dynamic> _setting = GStorage.setting;
  bool _shouldRequestFocus = false;
  bool _hasShownSourceBar = false;
  bool _isSending = false;

  // 弹幕设置
  late final RxInt _mode;
  late final RxInt _fontsize;
  late final Rx<Color> _color;
  final RxBool _enableSend = false.obs;

  // 预设颜色列表
  final List<Color> _colorList = [
    Colors.white,
    const Color(0xFFFE0302),
    const Color(0xFFFF7204),
    const Color(0xFFFFAA02),
    const Color(0xFFFFD302),
    const Color(0xFFFFFF00),
    const Color(0xFFA0EE00),
    const Color(0xFF00CD00),
    const Color(0xFF019899),
    const Color(0xFF4266BE),
    const Color(0xFF89D5FF),
    const Color(0xFFCC0273),
  ];

  @override
  void initState() {
    super.initState();
    // 从本地存储读取上次的设置
    _mode = (_setting.get('danmakuMode', defaultValue: 1) as int).obs;
    _fontsize = (_setting.get('danmakuFontsize', defaultValue: 25) as int).obs;
    final colorValue =
        _setting.get('danmakuColor', defaultValue: 0xFFFFFFFF) as int;
    _color = Color(colorValue).obs;

    _textController.addListener(() {
      _enableSend.value = _textController.text.trim().isNotEmpty;
    });

    // 监听动画进度
    widget.animation.addListener(_onAnimationProgress);
    widget.animation.addStatusListener(_onAnimationStatusChanged);
  }

  void _onAnimationProgress() {
    final double progress = widget.animation.value;
    final AnimationStatus status = widget.animation.status;

    // 入场动画：进度达到40%时触发键盘聚焦
    if (status == AnimationStatus.forward &&
        progress >= 0.4 &&
        !_shouldRequestFocus) {
      _shouldRequestFocus = true;
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }

    // 退出动画：进度降到20%以下时（即退出动画进行了80%）显示源输入框
    if (status == AnimationStatus.reverse &&
        progress <= 0.2 &&
        !_hasShownSourceBar) {
      _hasShownSourceBar = true;
      widget.onSourceBarVisibilityChanged?.call(true);
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    // 动画完全结束时的备用处理
    if (status == AnimationStatus.dismissed && !_hasShownSourceBar) {
      _hasShownSourceBar = true;
      widget.onSourceBarVisibilityChanged?.call(true);
    }
  }

  @override
  void dispose() {
    // 保存设置
    _setting.put('danmakuMode', _mode.value);
    _setting.put('danmakuFontsize', _fontsize.value);
    _setting.put('danmakuColor', _color.value.toARGB32());

    widget.animation.removeListener(_onAnimationProgress);
    widget.animation.removeStatusListener(_onAnimationStatusChanged);
    _focusNode.dispose();
    _textController.dispose();
    // 面板关闭时，如果之前是播放状态，则恢复播放
    if (widget.wasPlaying) {
      widget.playerController.play();
    }
    super.dispose();
  }

  Future<void> _sendDanmaku() async {
    final String msg = _textController.text.trim();
    if (msg.isEmpty) {
      SmartDialog.showToast('弹幕内容不能为空');
      return;
    }
    if (msg.length > 100) {
      SmartDialog.showToast('弹幕内容不能超过100个字符');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final dynamic res = await DanmakaHttp.shootDanmaku(
        oid: widget.cid,
        msg: msg,
        bvid: widget.bvid,
        progress: widget.progress,
        type: 1,
        mode: _mode.value,
        fontsize: _fontsize.value,
        color: _color.value.toARGB32() & 0xFFFFFF,
      );

      if (res['status']) {
        // 发送成功，立即添加弹幕到播放器
        final danmakuItem = DanmakuContentItem(
          msg,
          color: _color.value,
          type: _getDanmakuType(_mode.value),
          selfSend: true,
        );

        // 调试日志
        debugPrint('🎯 弹幕发送成功，准备添加到播放器');
        debugPrint('🎯 弹幕内容: $msg');
        debugPrint('🎯 弹幕类型: ${_getDanmakuType(_mode.value)}');
        debugPrint('🎯 selfSend: true');

        // 先添加弹幕
        widget.onSendSuccess(danmakuItem);
        debugPrint('🎯 已调用 onSendSuccess');

        // 显示成功提示
        SmartDialog.showToast('发送成功');

        // 关闭面板
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        SmartDialog.showToast('发送失败：${res['msg']}');
      }
    } catch (e) {
      SmartDialog.showToast('发送失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  DanmakuItemType _getDanmakuType(int mode) {
    switch (mode) {
      case 4:
        return DanmakuItemType.bottom;
      case 5:
        return DanmakuItemType.top;
      default:
        return DanmakuItemType.scroll;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // 目标面板的位置和大小 (增大25%)
    const double panelWidth = 450;
    const double panelHeight = 70; // 初始只显示输入框的高度
    final double targetX = (screenWidth - panelWidth) / 2;
    final double targetY = screenHeight * 0.35; // 屏幕中上部

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

          final double progress = curvedAnimation.value;
          final bool isReversing =
              widget.animation.status == AnimationStatus.reverse;

          // 第一阶段 (0-0.5): 输入框飞到中央
          // 第二阶段 (0.5-1.0): 展开成面板
          final double flyProgress = (progress * 2).clamp(0.0, 1.0);
          final double expandProgress = ((progress - 0.5) * 2).clamp(0.0, 1.0);

          // 计算当前位置 (从源位置飞到目标位置)
          final double currentX = widget.sourcePosition.dx +
              (targetX - widget.sourcePosition.dx) * flyProgress;
          final double currentY = widget.sourcePosition.dy +
              (targetY - widget.sourcePosition.dy) * flyProgress;

          // 计算当前大小 (从源大小变到目标大小)
          final double currentWidth = widget.sourceSize.width +
              (panelWidth - widget.sourceSize.width) * flyProgress;
          final double currentHeight = widget.sourceSize.height +
              (panelHeight - widget.sourceSize.height) * flyProgress;

          // 计算圆角 (从16变到12)
          final double currentRadius = 16 + (12 - 16) * flyProgress;

          // 计算透明度 - 退出动画最后20%时面板渐变消失
          double panelOpacity = 1.0;
          if (isReversing && progress <= 0.1) {
            // 退出动画进行到80%以上时，面板开始渐变消失
            panelOpacity = (progress / 0.1).clamp(0.0, 1.0);
          }

          // 背景遮罩透明度
          final double opacity = progress;

          return Stack(
            children: [
              // 背景遮罩
              Positioned.fill(
                child: Opacity(
                  opacity: opacity * 0.6,
                  child: Container(color: Colors.black),
                ),
              ),
              // 飞行中的输入框/面板
              Positioned(
                left: currentX,
                top: currentY,
                child: GestureDetector(
                  onTap: () {}, // 阻止点击穿透
                  child: Opacity(
                    opacity: panelOpacity,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: currentWidth,
                        constraints: BoxConstraints(
                          minHeight: currentHeight,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(currentRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20 * progress,
                              offset: Offset(0, 10 * progress),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildContent(expandProgress),
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

  Widget _buildContent(double expandProgress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 输入区域 - 始终显示
        _buildInputArea(),
        // 设置面板 - 根据展开进度显示
        if (expandProgress > 0)
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: expandProgress,
              child: _buildSettingsPanel(),
            ),
          ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 设置按钮（颜色预览）
          Obx(() => Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _color.value,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                  ),
                ),
              )),
          const SizedBox(width: 10),
          // 输入框
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLength: 100,
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (_enableSend.value && !_isSending) {
                  _sendDanmaku();
                }
              },
              decoration: InputDecoration(
                hintText: '输入弹幕内容',
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // 清除按钮
          Obx(() => _enableSend.value
              ? GestureDetector(
                  onTap: () => _textController.clear(),
                  child: Icon(
                    Icons.clear,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                )
              : const SizedBox.shrink()),
          const SizedBox(width: 8),
          // 发送按钮
          Obx(() => GestureDetector(
                onTap: _enableSend.value && !_isSending ? _sendDanmaku : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _enableSend.value
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _isSending ? '发送中' : '发送',
                    style: TextStyle(
                      fontSize: 13,
                      color: _enableSend.value
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // 弹幕字号
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '弹幕字号',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildFontSizeItem(18, '小'),
              const SizedBox(width: 6),
              _buildFontSizeItem(25, '标准'),
            ],
          ),
          const SizedBox(height: 10),
          // 弹幕样式
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '弹幕样式',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildModeItem(1, '滚动'),
              const SizedBox(width: 6),
              _buildModeItem(5, '顶部'),
              const SizedBox(width: 6),
              _buildModeItem(4, '底部'),
            ],
          ),
          const SizedBox(height: 10),
          // 弹幕颜色
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '弹幕颜色',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildColorPanel()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeItem(int fontsize, String title) {
    return Obx(
      () => GestureDetector(
        onTap: () => _fontsize.value = fontsize,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _fontsize.value == fontsize
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _fontsize.value == fontsize
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeItem(int mode, String title) {
    return Obx(
      () => GestureDetector(
        onTap: () => _mode.value = mode,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _mode.value == mode
                ? Theme.of(context).colorScheme.secondaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _mode.value == mode
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPanel() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colorList.map((color) => _buildColorItem(color)).toList(),
    );
  }

  Widget _buildColorItem(Color color) {
    return Obx(
      () => GestureDetector(
        onTap: () => _color.value = color,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: _color.value == color
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                  ),
          ),
        ),
      ),
    );
  }
}
