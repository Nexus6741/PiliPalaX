import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

import '../../common/widgets/network_img_layer.dart';
import '../../common/widgets/rich_text/controller.dart';
import '../../common/widgets/rich_text/models.dart';
import '../../common/widgets/rich_text/text_field.dart';
import '../../http/dynamics.dart';
import '../../models/dynamics/result.dart';
import '../../pages/emote/view.dart';
import '../../pages/video/reply_new/widgets/mention_panel.dart';
import '../../utils/feed_back.dart';
import '../../utils/storage.dart';

class DynamicRepostPage extends StatefulWidget {
  final DynamicItemModel? item;
  final String? dynIdStr;
  final VoidCallback? callback;

  const DynamicRepostPage({
    super.key,
    this.item,
    this.dynIdStr,
    this.callback,
  });

  @override
  State<DynamicRepostPage> createState() => _DynamicRepostPageState();
}

class _DynamicRepostPageState extends State<DynamicRepostPage> {
  late final RichTextEditingController _textController;
  late final FocusNode _focusNode;
  final RxBool _canPublish = false.obs;
  final RxBool _isPublishing = false.obs;
  final RxBool _showPanel = false.obs;
  final RxInt _currentPanelIndex = 0.obs;

  String? _pic;
  String _text = '';
  String? _uname;

  @override
  void initState() {
    super.initState();
    _textController = RichTextEditingController();
    _focusNode = FocusNode();

    // 监听文本变化
    _textController.addListener(_onTextChanged);

    // 初始化转发内容信息
    _initRepostInfo();

    // 转发动态可以不输入内容，默认允许发布
    _canPublish.value = true;
  }

  void _initRepostInfo() {
    final modules = widget.item?.modules;
    final moduleDynamic = modules?.moduleDynamic;
    final major = moduleDynamic?.major;

    _pic = major?.archive?.cover ??
        major?.pgc?.cover ??
        major?.opus?.pics?.firstOrNull?.url;

    _text = major?.opus?.summary?.text ??
        major?.archive?.title ??
        major?.pgc?.title ??
        moduleDynamic?.desc?.text ??
        '';

    _uname = modules?.moduleAuthor?.name;
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // 转发动态可以不输入内容，所以始终允许发布
    _canPublish.value = true;
  }

  void _onMentionUser(String uid, String username) {
    _textController.insertAtUser(username, uid);
    _showPanel.value = false;
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

  void _showPanelAt(int index) {
    _currentPanelIndex.value = index;
    _showPanel.value = !_showPanel.value;
  }

  void _hidePanel() {
    _showPanel.value = false;
  }

  List<Map<String, dynamic>>? _getRepostContent() {
    if (widget.item == null) return null;

    try {
      final item = widget.item!;
      final author = item.modules?.moduleAuthor;
      final desc = item.modules?.moduleDynamic?.desc;

      if (author == null) return null;

      final List<Map<String, dynamic>> content = [
        {'raw_text': '//', 'type': 1, 'biz_id': ''},
        {
          'raw_text': '@${author.name}',
          'type': 2,
          'biz_id': author.mid.toString(),
        },
        {'raw_text': ':', 'type': 1, 'biz_id': ''},
      ];

      // 添加原动态的富文本内容
      if (desc?.richTextNodes != null) {
        for (var node in desc!.richTextNodes!) {
          int type;
          String bizId;

          switch (node.type) {
            case 'RICH_TEXT_NODE_TYPE_EMOJI':
              type = 9;
              bizId = '';
              break;
            case 'RICH_TEXT_NODE_TYPE_AT':
              type = 2;
              bizId = node.rid ?? '';
              break;
            case 'RICH_TEXT_NODE_TYPE_TEXT':
            default:
              type = 1;
              bizId = '';
          }

          content.add({
            'raw_text': node.origText,
            'type': type,
            'biz_id': bizId,
          });
        }
      }

      return content;
    } catch (e) {
      // print('获取转发内容失败: $e');
      return null;
    }
  }

  Future<void> _onPublish() async {
    if (_isPublishing.value) return;

    feedBack();

    _isPublishing.value = true;
    SmartDialog.showLoading(msg: '转发中...');

    try {
      final richItems = _textController.getRichTextItems();

      // 转换富文本项为API格式
      List<Map<String, dynamic>>? richContent;
      if (richItems.isNotEmpty) {
        richContent = richItems.map((item) {
          switch (item.type) {
            case RichTextType.text:
            case RichTextType.common:
              return {
                'raw_text': item.text,
                'type': 1,
                'biz_id': '',
              };
            case RichTextType.at:
              return {
                'raw_text': '@${item.rawText}',
                'type': 2,
                'biz_id': item.id ?? '',
              };
            case RichTextType.emoji:
              return {
                'raw_text': item.rawText,
                'type': 9,
                'biz_id': '',
              };
            default:
              return {
                'raw_text': item.text,
                'type': 1,
                'biz_id': '',
              };
          }
        }).toList();
      } else {
        // 如果没有输入内容，使用默认文本"转发动态"
        richContent = [
          {
            'raw_text': '转发动态',
            'type': 1,
            'biz_id': '',
          }
        ];
      }

      // 获取转发内容
      final repostContent = _getRepostContent();

      // 合并用户输入和转发内容
      if (repostContent != null) {
        richContent.addAll(repostContent);
      }

      // 发布转发
      final result = await DynamicsHttp.createDynamic(
        dynIdStr: widget.item?.idStr ?? widget.dynIdStr,
        richContent: richContent,
      );

      SmartDialog.dismiss();

      if (result['status'] == true) {
        SmartDialog.showToast('转发成功');
        widget.callback?.call();
        Get.back(result: true);
      } else {
        SmartDialog.showToast(result['msg'] ?? '转发失败');
      }
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('转发失败: $e');
    } finally {
      _isPublishing.value = false;
    }
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
                  _buildRefWidget(theme),
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
      title: const Text('转发动态'),
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Get.back(),
      ),
      actions: [
        TextButton(
          onPressed: _onPublish,
          child: Text(
            '转发',
            style: TextStyle(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentInput(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      child: RichTextField(
        controller: _textController,
        focusNode: _focusNode,
        minLines: 5,
        maxLines: null,
        decoration: InputDecoration(
          hintText: '说点什么吧...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: theme.colorScheme.outline),
        ),
        onTap: _hidePanel,
      ),
    );
  }

  Widget _buildRefWidget(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (_pic != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: NetworkImgLayer(
                  width: 50,
                  height: 50,
                  src: _pic!,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_uname?.isNotEmpty == true)
                    Text(
                      '@$_uname',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildToolbarButton(
            icon: Icons.emoji_emotions_outlined,
            onTap: () => _showPanelAt(0),
            theme: theme,
          ),
          const SizedBox(width: 16),
          _buildToolbarButton(
            icon: Icons.alternate_email,
            onTap: () => _showPanelAt(1),
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
      if (!_showPanel.value) {
        return const SizedBox.shrink();
      }

      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Obx(() {
          switch (_currentPanelIndex.value) {
            case 0:
              return EmotePanel(onChoose: _onChooseEmote);
            case 1:
              return MentionPanel(
                onMention: _onMentionUser,
                onClose: _hidePanel,
              );
            default:
              return EmotePanel(onChoose: _onChooseEmote);
          }
        }),
      );
    });
  }
}
