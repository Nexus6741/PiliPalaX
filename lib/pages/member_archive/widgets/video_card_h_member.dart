import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/badge.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/http/search.dart';
import 'package:PiliPalaX/models/space_archive/space_archive_item.dart';
import 'package:PiliPalaX/utils/utils.dart';

/// 用户空间投稿视频卡片 - 水平布局
/// 参考PiliPlus的VideoCardHMemberVideo
class VideoCardHMember extends StatelessWidget {
  const VideoCardHMember({
    super.key,
    required this.videoItem,
    this.onTap,
  });

  final SpaceArchiveItem videoItem;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String heroTag = Utils.makeHeroTag(videoItem.aid);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap ?? () => _onTap(context, heroTag),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: StyleString.safeSpace,
            vertical: 5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面
              AspectRatio(
                aspectRatio: StyleString.aspectRatio,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Hero(
                          tag: heroTag,
                          child: NetworkImgLayer(
                            src: videoItem.cover ?? '',
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          ),
                        ),
                        // 时长
                        if (videoItem.duration > 0)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: PBadge(
                              text: _formatDuration(videoItem.duration),
                              type: 'gray',
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Expanded(
                      child: Text(
                        videoItem.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: theme.textTheme.bodyMedium!.fontSize,
                          height: 1.42,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    // 发布时间
                    Text(
                      videoItem.publishTimeText ?? '',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // 播放量和弹幕数
                    Row(
                      children: [
                        _StatWidget(
                          icon: Icons.play_arrow_outlined,
                          value: videoItem.stat.view ?? 0,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        _StatWidget(
                          icon: Icons.subtitles_outlined,
                          value: videoItem.stat.danmu ?? 0,
                          color: theme.colorScheme.outline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, String heroTag) async {
    if (videoItem.bvid == null) {
      SmartDialog.showToast('视频信息不完整');
      return;
    }

    try {
      int? cid = videoItem.cid;
      cid ??= await SearchHttp.ab2c(aid: videoItem.aid, bvid: videoItem.bvid!);
      Get.toNamed(
        '/video?bvid=${videoItem.bvid}&cid=$cid',
        arguments: {
          'heroTag': heroTag,
          'pic': videoItem.cover,
        },
      );
    } catch (err) {
      SmartDialog.showToast(err.toString());
    }
  }

  String _formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// 统计数据组件
class _StatWidget extends StatelessWidget {
  const _StatWidget({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        Text(
          _numFormat(value),
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  String _numFormat(int num) {
    if (num >= 10000) {
      return '${(num / 10000).toStringAsFixed(1)}万';
    }
    return num.toString();
  }
}
