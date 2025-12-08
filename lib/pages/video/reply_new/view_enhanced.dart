import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:PiliPalaX/common/widgets/rich_text/controller.dart';
import 'package:PiliPalaX/common/widgets/rich_text/models.dart' as rich_models;
import 'package:PiliPalaX/http/video.dart';
import 'package:PiliPalaX/http/msg.dart';
import 'package:PiliPalaX/models/common/reply_type.dart';
import 'package:PiliPalaX/models/video/reply/emote.dart' as emote_model;
import 'package:PiliPalaX/models/video/reply/item.dart';
import 'package:PiliPalaX/pages/emote/index.dart';
import 'package:PiliPalaX/plugin/pl_player/controller.dart';
import 'package:PiliPalaX/utils/feed_back.dart';
import 'package:easy_debounce/easy_throttle.dart';

import 'toolbar_icon_button.dart';
import 'widgets/image_preview_list.dart';
import 'widgets/mention_panel.dart';
import 'widgets/insert_content_search.dart';

class VideoReplyNewDialogEnhanced extends StatefulWidget {
  final int? oid;
  final int? root;
  final int? parent;
  final ReplyType? replyType;
  final ReplyItemModel? replyItem;

  const VideoReplyNewDialogEnhanced({
    super.key,
    this.oid,
    this.root,
    this.parent,
    this.replyType,
    this.replyItem,
  });

  @override
  State<VideoReplyNewDialogEnhanced> createState() =>
      _VideoReplyNewDialogEnhancedState();
}

class _VideoReplyNewDialogEnhancedState
    extends State<VideoReplyNewDialogEnhanced> with WidgetsBindingObserver {
  late final RichTextEditingController _replyContentController =
      RichTextEditingController();
  late final FocusNode replyContentFocusNode = FocusNode();
  late final RxList<String> pathList = <String>[].obs;
  late double emoteHeight = 0.0;
  double keyboardHeight = 0.0;
  final _debouncer = _EnhancedDebouncer(milliseconds: 200);
  String toolbarType = 'input';
  final int imageLimit = 9;
  late final RxBool enablePublish = false.obs;
  late final RxBool syncToDynamic = false.obs;

  @override
  void initState() {
    super.initState();
    print('🎯 使用增强版评论对话框 VideoReplyNewDialogEnhanced');
    WidgetsBinding.instance.addObserver(this);
    _autoFocus();
    _focusListener();
    _contentListener();
  }

  _autoFocus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (context.mounted) {
      FocusScope.of(context).requestFocus(replyContentFocusNode);
    }
  }

  _focusListener() {
    replyContentFocusNode.addListener(() {
      if (replyContentFocusNode.hasFocus) {
        setState(() {
          toolbarType = 'input';
        });
      }
    });
  }

  _contentListener() {
    _replyContentController.addListener(() {
      _updatePublishButtonState();
    });
    pathList.listen((_) {
      _updatePublishButtonState();
    });
  }

  void _updatePublishButtonState() {
    final hasContent = _replyContentController.text.trim().isNotEmpty;
    final hasImages = pathList.isNotEmpty;
    enablePublish.value = hasContent || hasImages;
  }

  Future<void> onPickImage() async {
    EasyThrottle.throttle(
      'imagePicker',
      const Duration(milliseconds: 500),
      () async {
        try {
          // 检查图片数量限制
          if (pathList.length >= imageLimit) {
            SmartDialog.showToast('最多只能选择${imageLimit}张图片');
            return;
          }

          // 使用 image_picker 选择图片
          final ImagePicker picker = ImagePicker();
          final List<XFile> images = await picker.pickMultiImage(
            imageQuality: 85,
          );

          if (images.isEmpty) return;

          // 检查总数量
          final remainingSlots = imageLimit - pathList.length;
          final imagesToAdd = images.take(remainingSlots).toList();

          if (images.length > remainingSlots) {
            SmartDialog.showToast('只能再选择${remainingSlots}张图片');
          }

          // 添加图片路径
          for (var image in imagesToAdd) {
            pathList.add(image.path);
          }

          _updatePublishButtonState();
        } catch (e) {
          SmartDialog.showToast('选择图片失败: $e');
        }
      },
    );
  }

  Future<void> onCropImage(int index) async {
    // TODO: 实现图片裁剪功能
    // 需要添加 image_cropper 依赖
    SmartDialog.showToast('图片裁剪功能开发中');
  }

  void onDeleteImage(int index) {
    final path = pathList.removeAt(index);
    File(path).delete().catchError((e) {
      // 忽略删除错误
      return File(path);
    });
  }

  void onPreviewImage(int index) {
    // TODO: 实现图片预览功能
  }

  void onInsertVideoProgress() {
    print('📍 [视频进度] 开始插入视频进度');

    try {
      // 检查 PlPlayerController 实例是否存在
      if (!PlPlayerController.instanceExists()) {
        print('❌ [视频进度] PlPlayerController 实例不存在');
        SmartDialog.showToast('播放器未初始化，请等待视频加载');
        return;
      }

      // 直接获取 PlPlayerController 实例
      final plPlayerController = PlPlayerController.getInstance();
      print('✅ [视频进度] 成功获取 PlPlayerController 实例');

      // 获取播放器的当前位置（position 是 Rx<Duration> 类型）
      final currentPosition = plPlayerController.position.value;
      print('📍 [视频进度] 当前播放位置: ${currentPosition.inSeconds}秒');

      final timeStr = _formatDuration(currentPosition);
      print('📍 [视频进度] 格式化时间: $timeStr');

      // 在前后加上空格，防止文字干扰
      final progressText = ' $timeStr ';

      final int cursorPosition = _replyContentController.selection.baseOffset;
      final String currentText = _replyContentController.text;
      final String newText = currentText.substring(0, cursorPosition) +
          progressText +
          currentText.substring(cursorPosition);

      _replyContentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: cursorPosition + progressText.length),
      );
      enablePublish.value = true;
      print('✅ [视频进度] 成功插入视频进度: $timeStr');
      SmartDialog.showToast('已插入视频进度: $timeStr');
    } catch (e, stackTrace) {
      print('❌ [视频进度] 发生错误: $e');
      print('❌ [视频进度] 堆栈跟踪: $stackTrace');
      SmartDialog.showToast('获取视频进度失败: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> onInsertScreenshot() async {
    print('📸 [视频截图] 开始截图');

    try {
      SmartDialog.showLoading(msg: '正在截图...');

      // 检查 PlPlayerController 实例是否存在
      if (!PlPlayerController.instanceExists()) {
        print('❌ [视频截图] PlPlayerController 实例不存在');
        SmartDialog.dismiss();
        SmartDialog.showToast('播放器未初始化，请等待视频加载');
        return;
      }

      // 直接获取 PlPlayerController 实例
      final plPlayerController = PlPlayerController.getInstance();
      print('✅ [视频截图] 成功获取 PlPlayerController 实例');

      // 检查图片数量限制
      if (pathList.length >= imageLimit) {
        print('⚠️ [视频截图] 图片数量已达上限: ${pathList.length}/$imageLimit');
        SmartDialog.dismiss();
        SmartDialog.showToast('最多只能添加$imageLimit张图片');
        return;
      }

      print('📸 [视频截图] 开始调用 screenshot() 方法');
      // 获取当前视频画面
      // 使用播放器的截图功能
      final screenshot = await plPlayerController.screenshot();

      if (screenshot == null) {
        print('❌ [视频截图] screenshot() 返回 null');
        SmartDialog.dismiss();
        SmartDialog.showToast('截图失败: 无法获取视频画面');
        return;
      }

      print('✅ [视频截图] 成功获取截图数据，大小: ${screenshot.length} bytes');

      // 保存截图到临时文件
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final screenshotFile = File('${tempDir.path}/screenshot_$timestamp.png');
      print('📸 [视频截图] 保存路径: ${screenshotFile.path}');

      await screenshotFile.writeAsBytes(screenshot);
      print('✅ [视频截图] 成功保存截图文件');

      // 添加到图片列表
      pathList.add(screenshotFile.path);
      _updatePublishButtonState();
      print('✅ [视频截图] 成功添加到图片列表，当前数量: ${pathList.length}');

      SmartDialog.dismiss();
      SmartDialog.showToast('截图成功，已添加到图片列表');
    } catch (e, stackTrace) {
      print('❌ [视频截图] 发生错误: $e');
      print('❌ [视频截图] 堆栈跟踪: $stackTrace');
      SmartDialog.dismiss();
      SmartDialog.showToast('截图失败: $e');
    }
  }

  void onChooseEmote(dynamic package, emote_model.Emote emote) {
    // 使用富文本控制器插入表情
    if (emote.text == null || emote.url == null) {
      return;
    }

    // 创建表情对象
    final richEmote = rich_models.Emote(
      url: emote.url!,
      width: 22,
      height: 22,
    );

    // 插入表情（在输入框中显示为图片）
    _replyContentController.insertEmote(emote.text!, richEmote);
    enablePublish.value = true;
  }

  void onMentionUser(String uid, String username) {
    // 在当前光标位置插入 @用户
    final selection = _replyContentController.selection;
    if (!selection.isValid) {
      return;
    }

    final oldText = _replyContentController.text;
    final mentionText = '@$username ';
    final newText = oldText.substring(0, selection.start) +
        mentionText +
        oldText.substring(selection.end);

    _replyContentController.value = TextEditingValue(
      text: newText,
      selection:
          TextSelection.collapsed(offset: selection.start + mentionText.length),
    );
    enablePublish.value = true;
  }

  void _closeMentionPanel() {
    setState(() {
      toolbarType = 'input';
    });
    FocusScope.of(context).requestFocus(replyContentFocusNode);
  }

  void onGoToDynamics() {
    syncToDynamic.value = !syncToDynamic.value;
    final status = syncToDynamic.value ? '已启用' : '已禁用';
    SmartDialog.showToast('转发到动态: $status');
  }

  Future<void> onInsertContent() async {
    final result = await Get.to<Map<String, String>>(
      const InsertContentSearchPage(),
    );

    if (result != null) {
      final url = result['url'] ?? '';

      if (url.isNotEmpty) {
        final int cursorPosition = _replyContentController.selection.baseOffset;
        final String currentText = _replyContentController.text;
        final String insertText = '$url ';

        final String newText = currentText.substring(0, cursorPosition) +
            insertText +
            currentText.substring(cursorPosition);

        _replyContentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
              offset: cursorPosition + insertText.length),
        );
        enablePublish.value = true;
        SmartDialog.showToast('已插入链接');
      }
    }
  }

  Widget _buildMorePanel() {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    Widget _buildMoreItem({
      required VoidCallback onTap,
      required IconData icon,
      required String title,
    }) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.onInverseSurface,
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 28, color: color),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
        children: [
          _buildMoreItem(
            onTap: onInsertContent,
            icon: Icons.post_add,
            title: '插入内容',
          ),
          _buildMoreItem(
            onTap: () {
              onInsertVideoProgress();
            },
            icon: Icons.access_time,
            title: '视频进度',
          ),
          _buildMoreItem(
            onTap: () {
              onInsertScreenshot();
            },
            icon: Icons.camera_alt_outlined,
            title: '视频截图',
          ),
        ],
      ),
    );
  }

  Future submitReplyAdd() async {
    feedBack();

    // 上传图片
    List<Map<String, dynamic>>? pictures;
    if (pathList.isNotEmpty) {
      SmartDialog.showLoading(msg: '正在上传图片...');
      try {
        pictures = await Future.wait<Map<String, dynamic>>(
          pathList.map((path) async {
            Map result = await MsgHttp.uploadBfs(
              path: path,
              category: 'daily',
              biz: 'reply',
            );
            if (!result['status']) {
              throw Exception(result['msg']);
            }
            final data = result['data'];
            return {
              'img_src': data['image_url'],
              'img_width': data['image_width'],
              'img_height': data['image_height'],
              'img_size': (data['img_size'] as num?)?.toDouble() ?? 0.0,
            };
          }),
        );
        SmartDialog.dismiss();
      } catch (e) {
        SmartDialog.dismiss();
        SmartDialog.showToast('图片上传失败: $e');
        return;
      }
    }

    // 发送评论（使用 originalText 获取原始表情文本）
    String message = _replyContentController.originalText;
    var result = await VideoHttp.replyAdd(
      type: widget.replyType ?? ReplyType.video,
      oid: widget.oid!,
      root: widget.root!,
      parent: widget.parent!,
      message: widget.replyItem != null && widget.replyItem!.root != 0
          ? ' 回复 @${widget.replyItem!.member!.uname!} : $message'
          : message,
      pictures: pictures,
      syncToDynamic: syncToDynamic.value,
    );
    if (result['status']) {
      SmartDialog.showToast(result['data']['success_toast']);
      Get.back(result: {
        'data': ReplyItemModel.fromJson(result['data']['reply'], ''),
      });
    } else {
      SmartDialog.showToast(result['msg']);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewInsets = EdgeInsets.fromViewPadding(
          View.of(context).viewInsets, View.of(context).devicePixelRatio);
      _debouncer.run(() {
        if (!mounted) return;
        if (keyboardHeight == 0 && emoteHeight == 0) {
          emoteHeight = keyboardHeight =
              keyboardHeight == 0.0 ? viewInsets.bottom : keyboardHeight;
          if (emoteHeight < 200) emoteHeight = 200;
          setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _replyContentController.dispose();
    replyContentFocusNode.removeListener(() {});
    replyContentFocusNode.dispose();
    for (var path in pathList) {
      File(path).delete().catchError((e) {
        // 忽略删除错误
        return File(path);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double keyboardHeight = EdgeInsets.fromViewPadding(
            View.of(context).viewInsets, View.of(context).devicePixelRatio)
        .bottom;
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图片预览列表
          ImagePreviewList(
            pathList: pathList,
            onDelete: onDeleteImage,
            onCrop: onCropImage,
            onPreview: onPreviewImage,
          ),
          // 输入框
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 200,
              minHeight: 120,
            ),
            child: Container(
              padding: const EdgeInsets.only(
                  top: 12, right: 15, left: 15, bottom: 10),
              child: SingleChildScrollView(
                child: TextField(
                  controller: _replyContentController,
                  focusNode: replyContentFocusNode,
                  minLines: 1,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: "输入回复内容",
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          // 工具栏
          Container(
            height: 52,
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Row(
              children: [
                // 表情按钮
                ToolbarIconButton(
                  tooltip: '表情',
                  onPressed: () {
                    setState(() {
                      toolbarType = toolbarType == 'emote' ? 'input' : 'emote';
                    });
                    FocusScope.of(context).unfocus();
                  },
                  icon: const Icon(Icons.emoji_emotions, size: 22),
                  toolbarType: toolbarType,
                  selected: toolbarType == 'emote',
                ),
                const SizedBox(width: 4),
                // 图片按钮
                ToolbarIconButton(
                  tooltip: '图片',
                  onPressed: onPickImage,
                  icon: const Icon(Icons.image_outlined, size: 22),
                  toolbarType: toolbarType,
                  selected: false,
                ),
                const SizedBox(width: 4),
                // @提及按钮
                ToolbarIconButton(
                  tooltip: '@提及',
                  onPressed: () {
                    setState(() {
                      toolbarType =
                          toolbarType == 'mention' ? 'input' : 'mention';
                    });
                    FocusScope.of(context).unfocus();
                  },
                  icon: const Icon(Icons.alternate_email, size: 22),
                  toolbarType: toolbarType,
                  selected: toolbarType == 'mention',
                ),
                const SizedBox(width: 4),
                // 更多按钮
                ToolbarIconButton(
                  tooltip: toolbarType == 'more' ? '输入' : '更多',
                  onPressed: () {
                    if (toolbarType == 'more') {
                      setState(() {
                        toolbarType = 'input';
                      });
                      FocusScope.of(context)
                          .requestFocus(replyContentFocusNode);
                    } else {
                      setState(() {
                        toolbarType = 'more';
                      });
                      FocusScope.of(context).unfocus();
                    }
                  },
                  icon: toolbarType == 'more'
                      ? const Icon(Icons.keyboard, size: 22)
                      : const Icon(Icons.add_circle_outline, size: 22),
                  toolbarType: toolbarType,
                  selected: toolbarType == 'more',
                ),
                const SizedBox(width: 4),
                // 转到动态按钮（复选框）
                Obx(
                  () => GestureDetector(
                    onTap: onGoToDynamics,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          syncToDynamic.value
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 22,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '转到动态',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                    onPressed: () => Get.back(),
                    child: Text('取消',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary))),
                const SizedBox(width: 10),
                Obx(
                  () => TextButton(
                    onPressed: enablePublish.value ? submitReplyAdd : null,
                    child: const Text('发送'),
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: toolbarType == 'input' ? keyboardHeight : emoteHeight,
            child: toolbarType == 'mention'
                ? MentionPanel(
                    onMention: onMentionUser,
                    onClose: _closeMentionPanel,
                  )
                : toolbarType == 'more'
                    ? _buildMorePanel()
                    : EmotePanel(
                        onChoose: onChooseEmote,
                      ),
          ),
          if (toolbarType == 'input' && keyboardHeight == 0.0)
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).padding.bottom,
            )
        ],
      ),
    );
  }
}

typedef _EnhancedDebounceCallback = void Function();

class _EnhancedDebouncer {
  _EnhancedDebounceCallback? callback;
  final int? milliseconds;
  Timer? _timer;

  _EnhancedDebouncer({this.milliseconds});

  run(_EnhancedDebounceCallback callback) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds!), () {
      callback();
    });
  }
}
