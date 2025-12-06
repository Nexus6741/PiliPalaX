import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:PiliPalaX/http/live.dart';
import 'package:PiliPalaX/pages/live_room/controller.dart';

class LiveSendDanmakuPanel extends StatefulWidget {
  final LiveRoomController liveRoomController;

  const LiveSendDanmakuPanel({
    super.key,
    required this.liveRoomController,
  });

  @override
  State<LiveSendDanmakuPanel> createState() => _LiveSendDanmakuPanelState();
}

class _LiveSendDanmakuPanelState extends State<LiveSendDanmakuPanel> {
  final TextEditingController _editController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendDanmaku() async {
    final msg = _editController.text.trim();
    if (msg.isEmpty) {
      SmartDialog.showToast('请输入弹幕内容');
      return;
    }

    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      final res = await LiveHttp.sendLiveMsg(
        roomId: widget.liveRoomController.roomId,
        msg: msg,
      );
      if (res['status']) {
        _editController.clear();
        SmartDialog.showToast('发送成功');
        if (mounted) Navigator.pop(context);
      } else {
        SmartDialog.showToast(res['msg'] ?? '发送失败');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _editController,
                focusNode: _focusNode,
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
                onSubmitted: (_) => _sendDanmaku(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSending ? null : _sendDanmaku,
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('发送'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showLiveSendDanmakuPanel(
  BuildContext context,
  LiveRoomController liveRoomController,
) {
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
    ),
  );
}
