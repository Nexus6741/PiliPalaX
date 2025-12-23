import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:PiliPalaX/http/danmaku.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:hive/hive.dart';

class SendDanmakuPanel extends StatefulWidget {
  final int cid;
  final String bvid;
  final int progress;
  final Function(DanmakuContentItem) onSendSuccess;
  final VoidCallback? onPanelOpened;
  final VoidCallback? onPanelClosed;

  const SendDanmakuPanel({
    super.key,
    required this.cid,
    required this.bvid,
    required this.progress,
    required this.onSendSuccess,
    this.onPanelOpened,
    this.onPanelClosed,
  });

  @override
  State<SendDanmakuPanel> createState() => _SendDanmakuPanelState();
}

class _SendDanmakuPanelState extends State<SendDanmakuPanel> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Box<dynamic> setting = GStorage.setting;

  late final RxInt _mode;
  late final RxInt _fontsize;
  late final Rx<Color> _color;
  final RxBool _enableSend = false.obs;
  bool _isSending = false;
  bool _showSettings = false;

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
    const Color(0xFF222222),
    const Color(0xFF9B9B9B),
  ];

  @override
  void initState() {
    super.initState();
    // 从本地存储读取上次的设置
    _mode = (setting.get('danmakuMode', defaultValue: 1) as int).obs;
    _fontsize = (setting.get('danmakuFontsize', defaultValue: 25) as int).obs;
    final colorValue =
        setting.get('danmakuColor', defaultValue: 0xFFFFFFFF) as int;
    _color = Color(colorValue).obs;

    _textController.addListener(() {
      _enableSend.value = _textController.text.trim().isNotEmpty;
    });

    // 通知面板已打开
    widget.onPanelOpened?.call();

    // 自动聚焦
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    // 保存设置
    setting.put('danmakuMode', _mode.value);
    setting.put('danmakuFontsize', _fontsize.value);
    setting.put('danmakuColor', _color.value.value);

    // 通知面板已关闭
    widget.onPanelClosed?.call();

    _textController.dispose();
    _focusNode.dispose();
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
        color: _color.value.value & 0xFFFFFF,
      );

      if (res['status']) {
        // 发送成功，立即添加弹幕到播放器
        final danmakuItem = DanmakuContentItem(
          msg,
          color: _color.value,
          type: _getDanmakuType(_mode.value),
          selfSend: true,
        );

        // 先添加弹幕
        widget.onSendSuccess(danmakuItem);

        // 显示成功提示
        SmartDialog.showToast('发送成功');
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInputArea(),
          if (_showSettings) _buildSettingsPanel(),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 设置按钮
          IconButton(
            icon: Icon(
              Icons.text_format,
              color: _showSettings
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
              if (!_showSettings) {
                _focusNode.requestFocus();
              }
            },
            tooltip: '弹幕样式',
          ),
          const SizedBox(width: 8),
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
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
          // 清除按钮
          Obx(() => _enableSend.value
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _textController.clear();
                  },
                )
              : const SizedBox.shrink()),
          const SizedBox(width: 8),
          // 发送按钮
          Obx(() => IconButton(
                icon: Icon(
                  Icons.send,
                  color: _enableSend.value
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                onPressed:
                    _enableSend.value && !_isSending ? _sendDanmaku : null,
                tooltip: '发送',
              )),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 弹幕字号
          Row(
            children: [
              Text(
                '弹幕字号',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              _buildFontSizeItem(18, '小'),
              const SizedBox(width: 8),
              _buildFontSizeItem(25, '标准'),
            ],
          ),
          const SizedBox(height: 12),
          // 弹幕样式
          Row(
            children: [
              Text(
                '弹幕样式',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              _buildPositionItem(1, '滚动'),
              const SizedBox(width: 8),
              _buildPositionItem(5, '顶部'),
              const SizedBox(width: 8),
              _buildPositionItem(4, '底部'),
            ],
          ),
          const SizedBox(height: 12),
          // 弹幕颜色
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '弹幕颜色',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildColorPanel()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeItem(int fontsize, String title) {
    return Obx(
      () => Expanded(
        child: GestureDetector(
          onTap: () => _fontsize.value = fontsize,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _fontsize.value == fontsize
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.onInverseSurface,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: _fontsize.value == fontsize
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionItem(int mode, String title) {
    return Obx(
      () => Expanded(
        child: GestureDetector(
          onTap: () => _mode.value = mode,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _mode.value == mode
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.onInverseSurface,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: _mode.value == mode
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPanel() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 36,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _colorList.length,
      itemBuilder: (context, index) {
        return _buildColorItem(_colorList[index]);
      },
    );
  }

  Widget _buildColorItem(Color color) {
    return GestureDetector(
      onTap: () => _color.value = color,
      child: Obx(
        () => Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            border: _color.value == color
                ? Border.all(
                    width: 2,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : Border.all(
                    width: 1,
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
          ),
        ),
      ),
    );
  }
}
