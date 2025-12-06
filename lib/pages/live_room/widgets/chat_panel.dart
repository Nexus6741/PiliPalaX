import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/models/live/live_danmaku/danmaku_msg.dart';
import 'package:PiliPalaX/pages/live_room/controller.dart';
import 'package:PiliPalaX/pages/live_room/send_danmaku/view.dart';
import 'package:PiliPalaX/utils/storage.dart';

class LiveRoomChatPanel extends StatelessWidget {
  const LiveRoomChatPanel({
    super.key,
    required this.roomId,
    required this.liveRoomController,
  });

  final int roomId;
  final LiveRoomController liveRoomController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.surface.withOpacity(0.9);
    final nameColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;
    final systemColor = theme.colorScheme.secondary;
    const giftColor = Colors.orange;

    return Column(
      children: [
        // 消息列表
        Expanded(
          child: Stack(
            children: [
              Obx(
                () => liveRoomController.messages.isEmpty
                    ? Center(
                        child: Text(
                          '暂无弹幕消息',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      )
                    : ListView.separated(
                        key: const PageStorageKey('live-chat'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        controller: liveRoomController.dmScrollController,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 6),
                        itemCount: liveRoomController.messages.length,
                        physics: const ClampingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = liveRoomController.messages[index];
                          return _buildMessageItem(
                            item,
                            bgColor,
                            nameColor,
                            textColor,
                            systemColor,
                            giftColor,
                          );
                        },
                      ),
              ),
              // 回到底部按钮
              Positioned(
                right: 12,
                bottom: 12,
                child: Obx(
                  () => liveRoomController.disableAutoScroll.value
                      ? FloatingActionButton.small(
                          onPressed: () {
                            liveRoomController.disableAutoScroll.value = false;
                            liveRoomController.scrollToBottom();
                          },
                          child: const Icon(Icons.arrow_downward),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
        // 发送弹幕输入区
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withOpacity(0.2),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Obx(() {
                  final enableShowDanmaku =
                      liveRoomController.plPlayerController.isOpenDanmu.value;
                  return IconButton(
                    tooltip: enableShowDanmaku ? '关闭弹幕' : '开启弹幕',
                    icon: Icon(
                      enableShowDanmaku ? Icons.subtitles : Icons.subtitles_off,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                    onPressed: () {
                      final newVal = !enableShowDanmaku;
                      liveRoomController.plPlayerController.isOpenDanmu.value =
                          newVal;
                      GStorage.setting.put(
                        SettingBoxKey.enableShowLiveDanmaku,
                        newVal,
                      );
                    },
                  );
                }),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => showLiveSendDanmakuPanel(
                      context,
                      liveRoomController,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '发送弹幕...',
                            style: TextStyle(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return Material(
                      type: MaterialType.transparency,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          InkWell(
                            customBorder: const CircleBorder(),
                            onTapDown: liveRoomController.onLikeTapDown,
                            onTapUp: (_) => liveRoomController.onLikeTapUp(),
                            onTapCancel: liveRoomController.onLikeTapUp,
                            child: const SizedBox.square(
                              dimension: 36,
                              child: Icon(
                                Icons.thumb_up_off_alt,
                                color: Color(0xFFEEEEEE),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -10,
                            top: -8,
                            child: Obx(() {
                              final likeTimes =
                                  liveRoomController.likeClickTime.value;
                              if (likeTimes == 0) {
                                return const SizedBox.shrink();
                              }
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 160),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                                child: Text(
                                  key: ValueKey(likeTimes),
                                  'x$likeTimes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.brightness ==
                                            Brightness.dark
                                        ? colorScheme.primary
                                        : colorScheme.inversePrimary,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: '表情',
                  icon: const Icon(
                    Icons.emoji_emotions_outlined,
                    color: Color(0xFFEEEEEE),
                  ),
                  onPressed: () =>
                      showLiveSendDanmakuPanel(context, liveRoomController),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(
    DanmakuMsg item,
    Color bgColor,
    Color nameColor,
    Color textColor,
    Color systemColor,
    Color giftColor,
  ) {
    Color msgColor = textColor;
    if (item.isSystem) {
      msgColor = systemColor;
    } else if (item.isGift) {
      msgColor = giftColor;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${item.name ?? '用户'}: ',
                style: TextStyle(
                  color: nameColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                recognizer: item.uid == null || item.uid == 0
                    ? null
                    : (TapGestureRecognizer()
                      ..onTap = () => Get.toNamed('/member?mid=${item.uid}')),
              ),
              TextSpan(
                text: item.text ?? '',
                style: TextStyle(
                  color: msgColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
