import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/models/video/video_tag.dart';

/// 视频标签显示组件
/// 用于在视频简介区域显示视频的分类标签、话题标签和BGM标签
class TagsWidget extends StatelessWidget {
  final List<VideoTag> tags;

  const TagsWidget({
    super.key,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    // 空列表时不显示
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) => _buildTagItem(context, tag)).toList(),
      ),
    );
  }

  /// 构建单个标签项
  Widget _buildTagItem(BuildContext context, VideoTag tag) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _handleTagTap(tag),
      onLongPress: () => _handleTagLongPress(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildTagContent(tag),
      ),
    );
  }

  /// 构建标签内容（包含图标和文本）
  Widget _buildTagContent(VideoTag tag) {
    if (tag.tagType == 'bgm') {
      // BGM标签: 显示音乐图标 + 文本
      String text = tag.tagName?.replaceFirst('发现', 'BGM：') ?? '';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_note, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      );
    } else if (tag.tagType == 'topic') {
      // 话题标签: 添加"#"前缀
      return Text('#${tag.tagName ?? ''}',
          style: const TextStyle(fontSize: 13));
    } else {
      // 普通标签: 直接显示标签名称
      return Text(tag.tagName ?? '', style: const TextStyle(fontSize: 13));
    }
  }

  /// 处理标签点击事件
  void _handleTagTap(VideoTag tag) {
    switch (tag.tagType) {
      case 'bgm':
        // BGM标签: 跳转到音乐详情页
        if (tag.musicId != null && tag.musicId!.isNotEmpty) {
          Get.toNamed('/musicDetail', parameters: {'musicId': tag.musicId!});
        }
        break;
      case 'topic':
        // 话题标签: 跳转到动态话题页
        if (tag.tagId != null) {
          Get.toNamed('/dynamicsTopic', parameters: {
            'id': tag.tagId!.toString(),
            'name': tag.tagName ?? '',
          });
        }
        break;
      default:
        // 普通标签: 直接跳转到搜索结果页,不经过搜索页以避免污染搜索历史
        if (tag.tagName != null && tag.tagName!.isNotEmpty) {
          Get.toNamed('/searchResult', parameters: {
            'keyword': tag.tagName!,
            'searchType': 'tag' // 标记这是从标签跳转的,不是用户主动搜索
          });
        }
        break;
    }
  }

  /// 处理标签长按事件
  void _handleTagLongPress(VideoTag tag) {
    String text;
    if (tag.tagType == 'bgm') {
      text = tag.tagName?.replaceFirst('发现', 'BGM：') ?? '';
    } else if (tag.tagType == 'topic') {
      text = '#${tag.tagName ?? ''}';
    } else {
      text = tag.tagName ?? '';
    }

    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      SmartDialog.showToast('已复制: $text');
    }
  }
}
