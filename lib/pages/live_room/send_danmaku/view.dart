import 'dart:async';
import 'dart:ui';

import 'package:PiliPalaX/http/live.dart';
import 'package:PiliPalaX/models/live/live_danmaku/danmaku_msg.dart';
import 'package:PiliPalaX/models/live_new/live_emote/emoticon.dart';
import 'package:PiliPalaX/pages/live_room/controller.dart';
import 'package:PiliPalaX/pages/live_room/send_danmaku/live_emote_panel.dart';
import 'package:PiliPalaX/pages/video/reply_new/toolbar_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class LiveSendDanmakuPanel extends StatefulWidget {
  final LiveRoomController liveRoomController;
  final bool openEmotePanel;

  const LiveSendDanmakuPanel({
    super.key,
    required this.liveRoomController,
    this.openEmotePanel = false,
  });

  @override
  State<LiveSendDanmakuPanel> createState() => _LiveSendDanmakuPanelState();
}

class _LiveSendDanmakuPanelState extends State<LiveSendDanmakuPanel>
    with WidgetsBindingObserver {
  final TextEditingController _editController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  String? _pureEmoteUnique;
  String? _pureEmoteText;
  Emoticon? _pureEmote;
  double _emoteHeight = 0.0;
  double _keyboardHeight = 0.0;
  final Debouncer _debouncer = Debouncer(milliseconds: 200);
  String _toolbarType = 'input';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_handleFocusChange);
    _toolbarType = widget.openEmotePanel ? 'emote' : 'input';
    if (widget.openEmotePanel) {
      _focusNode.unfocus();
      if (_emoteHeight == 0) {
        _emoteHeight = 240;
      }
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_handleFocusChange);
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _pureEmoteUnique = null;
      _pureEmoteText = null;
      _pureEmote = null;
      return;
    }
    if (_pureEmoteText != null && trimmed != _pureEmoteText) {
      _pureEmoteUnique = null;
      _pureEmoteText = null;
      _pureEmote = null;
    }
  }

  Future<void> _sendDanmaku({
    String? overrideMsg,
    String? emoticonUnique,
    Emoticon? emote,
    bool closePanelOnSuccess = true,
  }) async {
    final msg = overrideMsg ?? _editController.text.trim();
    // 如果不是表情弹幕，检查消息是否为空
    if (msg.isEmpty && emoticonUnique == null) {
      SmartDialog.showToast('请输入弹幕内容');
      return;
    }
    if (_isSending) return;
    setState(() => _isSending = true);

    try {
      final res = await LiveHttp.sendLiveMsg(
        roomId: widget.liveRoomController.roomId,
        msg: msg,
        dmType: emoticonUnique != null ? 1 : null,
        emoticonOptions: emoticonUnique != null ? '[object Object]' : null,
      );
      if (res['status']) {
        if (overrideMsg == null) {
          _editController.clear();
          _pureEmoteUnique = null;
          _pureEmoteText = null;
          _pureEmote = null;
        }
        SmartDialog.showToast('发送成功');
        if (closePanelOnSuccess && mounted) {
          Navigator.pop(context);
        }
      } else {
        SmartDialog.showToast(res['msg'] ?? '发送失败');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _insertEmote(Emoticon emote) {
    final text = _formatEmojiText(emote);
    if (text.isEmpty) return;
    final value = _editController.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final newText =
        value.text.replaceRange(selection.start, selection.end, text);
    final newSelectionIndex = selection.start + text.length;
    _editController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionIndex),
    );
    // 官方默认表情插入输入框后，不设置_pureEmoteUnique
    // 因为它们应该作为普通文本发送，不需要dmType和emoticonOptions
    _pureEmoteUnique = null;
    _pureEmoteText = null;
    _pureEmote = null;
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    setState(() {});
  }

  Future<void> _sendEmoteDirectly(Emoticon emote) async {
    if (_isSending) return;
    final unique = emote.emoticonUnique;
    if (unique == null || unique.isEmpty) {
      SmartDialog.showToast('表情数据异常');
      return;
    }
    // 第三方表情发送时，msg参数直接使用emoticonUnique
    await _sendDanmaku(
      overrideMsg: unique,
      emoticonUnique: unique,
      emote: emote,
      closePanelOnSuccess: false,
    );
  }

  String _formatEmojiText(Emoticon emote) {
    final emoji = emote.emoji?.trim();
    if (emoji == null || emoji.isEmpty) return '';
    if (emoji.startsWith('[') && emoji.endsWith(']')) {
      return emoji;
    }
    return '[$emoji]';
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && _toolbarType != 'input') {
      setState(() {
        _toolbarType = 'input';
      });
    }
  }

  void _toggleToolbar(String type) {
    if (_toolbarType == type) return;
    setState(() {
      _toolbarType = type;
      if (type == 'emote' && _emoteHeight == 0) {
        _emoteHeight = _keyboardHeight > 0 ? _keyboardHeight : 240;
      }
    });
    if (type == 'input') {
      FocusScope.of(context).requestFocus(_focusNode);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewInsets = EdgeInsets.fromViewPadding(
        View.of(context).viewInsets,
        View.of(context).devicePixelRatio,
      );
      _debouncer.run(() {
        if (!mounted) return;
        _keyboardHeight = viewInsets.bottom;
        if (_emoteHeight == 0 && _keyboardHeight > 0) {
          _emoteHeight = _keyboardHeight;
          if (_emoteHeight < 200) {
            _emoteHeight = 200;
          }
        } else if (_emoteHeight == 0) {
          _emoteHeight = 200;
        }
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardHeight = EdgeInsets.fromViewPadding(
      View.of(context).viewInsets,
      View.of(context).devicePixelRatio,
    ).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 200,
                minHeight: 120,
              ),
              child: Container(
                padding: const EdgeInsets.only(
                    top: 12, right: 16, left: 16, bottom: 8),
                child: SingleChildScrollView(
                  child: TextField(
                    controller: _editController,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: null,
                    maxLength: 20,
                    decoration: InputDecoration(
                      hintText: '输入弹幕内容',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: _onTextChanged,
                    onSubmitted: (_) => _sendDanmaku(
                          emoticonUnique: _pureEmoteUnique,
                          emote: _pureEmote,
                        ),
                  ),
                ),
              ),
            ),
            Divider(
              height: 1,
              color: theme.dividerColor.withOpacity(0.1),
            ),
            Container(
              height: 52,
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Row(
                children: [
                  ToolbarIconButton(
                    tooltip: '输入',
                    onPressed: () => _toggleToolbar('input'),
                    icon: const Icon(Icons.keyboard, size: 22),
                    toolbarType: _toolbarType,
                    selected: _toolbarType == 'input',
                  ),
                  const SizedBox(width: 20),
                  ToolbarIconButton(
                    tooltip: '表情',
                    onPressed: () => _toggleToolbar('emote'),
                    icon: const Icon(Icons.emoji_emotions_outlined, size: 22),
                    toolbarType: _toolbarType,
                    selected: _toolbarType == 'emote',
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSending
                        ? null
                        : () => _sendDanmaku(
                              emoticonUnique: _pureEmoteUnique,
                              emote: _pureEmote,
                            ),
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('发送'),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: _toolbarType == 'input' ? keyboardHeight : _emoteHeight,
              child: _toolbarType == 'emote'
                  ? LiveEmotePanel(
                      roomId: widget.liveRoomController.roomId,
                      onInsert: _insertEmote,
                      onSendDirectly: _sendEmoteDirectly,
                    )
                  : const SizedBox.shrink(),
            ),
            if (_toolbarType == 'input' && keyboardHeight == 0.0)
              SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).padding.bottom,
              ),
          ],
        ),
      ),
    );
  }
}

void showLiveSendDanmakuPanel(
  BuildContext context,
  LiveRoomController liveRoomController, {
  bool openEmote = false,
}) {
  if (!liveRoomController.isLogin) {
    SmartDialog.showToast('请先登录');
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => LiveSendDanmakuPanel(
      liveRoomController: liveRoomController,
      openEmotePanel: openEmote,
    ),
  );
}

typedef DebounceCallback = void Function();

class Debouncer {
  DebounceCallback? callback;
  final int? milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds});

  void run(DebounceCallback callback) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds ?? 200), callback);
  }
}
