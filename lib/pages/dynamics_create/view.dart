import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../../common/widgets/rich_text/controller.dart';
import '../../common/widgets/rich_text/text_field.dart';
import '../../common/widgets/rich_text/models.dart';
import '../../models/dynamics/topic_item.dart';
import '../../pages/emote/view.dart';
import '../../utils/feed_back.dart';
import '../../utils/utils.dart';
import 'controller.dart';
import 'widgets/topic_selector.dart';

class CreateDynamicPage extends StatefulWidget {
  const CreateDynamicPage({super.key});

  @override
  State<CreateDynamicPage> createState() => _CreateDynamicPageState();
}

class _CreateDynamicPageState extends State<CreateDynamicPage>
    with TickerProviderStateMixin {
  final CreateDynamicController _controller =
      Get.put(CreateDynamicController());
  late final RichTextEditingController _textController;
  late final TextEditingController _titleController;
  late final FocusNode _focusNode;
  late final TabController _panelTabController;

  @override
  void initState() {
    super.initState();
    _textController = RichTextEditingController();
    _titleController = TextEditingController();
    _focusNode = FocusNode();
    _panelTabController = TabController(length: 3, vsync: this);

    // 监听文本变化
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    _panelTabController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text.trim();
    final hasImages = _controller.selectedImages.isNotEmpty;
    _controller.updatePublishEnabled(text.isNotEmpty || hasImages);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopicSelector(theme),
                  const SizedBox(height: 16),
                  _buildTitleInput(theme),
                  const SizedBox(height: 16),
                  _buildContentInput(theme),
                  const SizedBox(height: 16),
                  _buildImageGrid(theme),
                  const SizedBox(height: 16),
                  _buildOptions(theme),
                ],
              ),
            ),
          ),
          _buildToolbar(theme),
          _buildPanel(theme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('发布动态'),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Get.back(),
      ),
      actions: [
        Obx(() => TextButton(
              onPressed: _controller.canPublish.value ? _onPublish : null,
              child: Text(
                _controller.isScheduled ? '定时发布' : '发布',
                style: TextStyle(
                  color: _controller.canPublish.value
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildTopicSelector(ThemeData theme) {
    return Obx(() {
      final topic = _controller.selectedTopic.value;
      return GestureDetector(
        onTap: _onSelectTopic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border:
                Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tag,
                size: 18,
                color: topic != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                topic?.name ?? '选择话题',
                style: TextStyle(
                  color: topic != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
              if (topic != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _controller.clearTopic(),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTitleInput(ThemeData theme) {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        hintText: '标题（选填，最多20字）',
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: theme.colorScheme.outline,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      maxLength: 20,
      buildCounter: (context,
          {required currentLength, required isFocused, maxLength}) {
        return null; // 隐藏计数器
      },
    );
  }

  Widget _buildContentInput(ThemeData theme) {
    return RichTextField(
      controller: _textController,
      focusNode: _focusNode,
      minLines: 6,
      maxLines: null,
      decoration: InputDecoration(
        hintText: '说点什么吧...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: theme.colorScheme.outline),
      ),
      onTap: () {
        _controller.showKeyboard();
      },
    );
  }

  Widget _buildImageGrid(ThemeData theme) {
    return Obx(() {
      final images = _controller.selectedImages;
      if (images.isEmpty && !_controller.canAddImage) {
        return const SizedBox.shrink();
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: images.length + (_controller.canAddImage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < images.length) {
            return _buildImageItem(images[index], index, theme);
          } else {
            return _buildAddImageButton(theme);
          }
        },
      );
    });
  }

  Widget _buildImageItem(File image, int index, ThemeData theme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _controller.removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton(ThemeData theme) {
    return GestureDetector(
      onTap: _onAddImage,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          Icons.add,
          size: 32,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildOptions(ThemeData theme) {
    return Column(
      children: [
        _buildVisibilityOption(theme),
        const SizedBox(height: 8),
        _buildReplyOption(theme),
        const SizedBox(height: 8),
        _buildScheduleOption(theme),
      ],
    );
  }

  Widget _buildVisibilityOption(ThemeData theme) {
    return Obx(() => Row(
          children: [
            Icon(
              _controller.isPrivate.value
                  ? Icons.visibility_off
                  : Icons.visibility,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _controller.isPrivate.value ? '仅自己可见' : '所有人可见',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            Switch(
              value: _controller.isPrivate.value,
              onChanged: _controller.togglePrivate,
            ),
          ],
        ));
  }

  Widget _buildReplyOption(ThemeData theme) {
    return Obx(() => Row(
          children: [
            Icon(
              _controller.allowReply.value
                  ? Icons.comment
                  : Icons.comments_disabled,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _controller.allowReply.value ? '允许评论' : '关闭评论',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            Switch(
              value: _controller.allowReply.value,
              onChanged: _controller.toggleReply,
            ),
          ],
        ));
  }

  Widget _buildScheduleOption(ThemeData theme) {
    return Obx(() => GestureDetector(
          onTap: _controller.isPrivate.value ? null : _onSchedule,
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 20,
                color: _controller.isPrivate.value
                    ? theme.colorScheme.outline
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _controller.scheduledTime.value != null
                      ? '定时发布: ${Utils.dateFormat(_controller.scheduledTime.value!, formatType: 'detail')}'
                      : '定时发布',
                  style: TextStyle(
                    color: _controller.isPrivate.value
                        ? theme.colorScheme.outline
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (_controller.scheduledTime.value != null)
                GestureDetector(
                  onTap: () => _controller.clearSchedule(),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
        ));
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildToolbarButton(
            icon: Icons.emoji_emotions_outlined,
            onTap: () => _controller.showPanel(0),
            theme: theme,
          ),
          const SizedBox(width: 16),
          _buildToolbarButton(
            icon: Icons.alternate_email,
            onTap: () => _controller.showPanel(1),
            theme: theme,
          ),
          const SizedBox(width: 16),
          _buildToolbarButton(
            icon: Icons.image_outlined,
            onTap: _onAddImage,
            theme: theme,
          ),
          const SizedBox(width: 16),
          _buildToolbarButton(
            icon: Icons.more_horiz,
            onTap: () => _controller.showPanel(2),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 24,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildPanel(ThemeData theme) {
    return Obx(() {
      if (!_controller.showPanelState.value) {
        return const SizedBox.shrink();
      }

      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
        ),
        child: TabBarView(
          controller: _panelTabController,
          children: [
            EmotePanel(onChoose: _onChooseEmote),
            _buildMentionPanel(),
            _buildMorePanel(),
          ],
        ),
      );
    });
  }

  Widget _buildMentionPanel() {
    return const Center(
      child: Text('@提及功能开发中...'),
    );
  }

  Widget _buildMorePanel() {
    return const Center(
      child: Text('更多功能开发中...'),
    );
  }

  void _onChooseEmote(dynamic package, dynamic emote) {
    if (emote.url != null && emote.text != null) {
      final richEmote = Emote(
        url: emote.url!,
        width: 22,
        height: 22,
      );
      _textController.insertEmote(emote.text!, richEmote);
    }
  }

  void _onAddImage() async {
    await _controller.pickImages();
  }

  void _onSelectTopic() async {
    print('=== _onSelectTopic 被调用 ===');
    final result = await Get.to<TopicItem>(
      () => const TopicSelectorPage(),
    );

    print('=== 话题选择结果 ===');
    print('result: $result');

    if (result != null) {
      print('选择的话题ID: ${result.id}');
      print('选择的话题名称: ${result.name}');
      _controller.setTopic(result);
    } else {
      print('未选择话题或取消选择');
    }
  }

  void _onSchedule() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year, now.month, now.day + 7),
    );

    if (selectedDate != null && mounted) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(now.add(const Duration(minutes: 10))),
      );

      if (selectedTime != null) {
        final scheduledDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        if (scheduledDateTime.isBefore(now.add(const Duration(minutes: 5)))) {
          SmartDialog.showToast('定时时间至少需要5分钟后');
          return;
        }

        _controller.setScheduledTime(scheduledDateTime);
      }
    }
  }

  void _onPublish() async {
    feedBack();

    final content = _textController.originalText.trim();
    final title = _titleController.text.trim();

    if (content.isEmpty && _controller.selectedImages.isEmpty) {
      SmartDialog.showToast('请输入内容或添加图片');
      return;
    }

    await _controller.publishDynamic(
      content: content,
      title: title.isNotEmpty ? title : null,
    );
  }
}
