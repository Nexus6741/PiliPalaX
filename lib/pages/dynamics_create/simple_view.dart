import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../../common/widgets/rich_text/controller.dart';
import '../../common/widgets/rich_text/text_field.dart';
import '../../common/widgets/rich_text/models.dart';
import '../../pages/emote/view.dart';
import '../../pages/video/reply_new/widgets/mention_panel.dart';
import '../../utils/feed_back.dart';
import 'simple_controller.dart';

class SimpleDynamicCreatePage extends StatefulWidget {
  const SimpleDynamicCreatePage({super.key});

  @override
  State<SimpleDynamicCreatePage> createState() =>
      _SimpleDynamicCreatePageState();
}

class _SimpleDynamicCreatePageState extends State<SimpleDynamicCreatePage>
    with TickerProviderStateMixin {
  final SimpleDynamicCreateController _controller =
      Get.put(SimpleDynamicCreateController());
  late final RichTextEditingController _textController;
  late final FocusNode _focusNode;
  late final TabController _panelTabController;

  @override
  void initState() {
    super.initState();
    _textController = RichTextEditingController();
    _focusNode = FocusNode();
    _panelTabController = TabController(length: 2, vsync: this);

    // 监听文本变化
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _panelTabController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text.trim();
    _controller.updatePublishEnabled(text.isNotEmpty);
  }

  void _onMentionUser(String uid, String username) {
    // 在当前光标位置插入 @用户
    final selection = _textController.selection;
    if (!selection.isValid) {
      return;
    }

    final oldText = _textController.text;
    final mentionText = '@$username ';
    final newText = oldText.substring(0, selection.start) +
        mentionText +
        oldText.substring(selection.end);

    _textController.value = _textController.value.copyWith(
      text: newText,
      selection:
          TextSelection.collapsed(offset: selection.start + mentionText.length),
    );

    _controller.updatePublishEnabled(newText.trim().isNotEmpty);
    _controller.hidePanel();
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
                '发布',
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

  Widget _buildContentInput(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      child: RichTextField(
        controller: _textController,
        focusNode: _focusNode,
        minLines: 8,
        maxLines: null,
        decoration: InputDecoration(
          hintText: '说点什么吧...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: theme.colorScheme.outline),
        ),
        onTap: () {
          _controller.hidePanel();
        },
      ),
    );
  }

  Widget _buildOptions(ThemeData theme) {
    return Column(
      children: [
        _buildVisibilityOption(theme),
        const SizedBox(height: 8),
        _buildReplyOption(theme),
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
            MentionPanel(
              onMention: _onMentionUser,
              onClose: () => _controller.hidePanel(),
            ),
          ],
        ),
      );
    });
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

  void _onPublish() async {
    feedBack();

    final content = _textController.originalText.trim();

    if (content.isEmpty && _controller.selectedImages.isEmpty) {
      SmartDialog.showToast('请输入内容或添加图片');
      return;
    }

    await _controller.publishDynamic(content: content);
  }
}
