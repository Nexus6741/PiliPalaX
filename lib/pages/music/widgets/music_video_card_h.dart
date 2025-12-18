import 'package:PiliPalaX/common/widgets/badge.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/http/search.dart';
import 'package:PiliPalaX/models/music/bgm_recommend_list.dart';
import 'package:PiliPalaX/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

/// 音乐推荐视频横向卡片
class MusicVideoCardH extends StatelessWidget {
  final BgmRecommend videoItem;

  const MusicVideoCardH({
    super.key,
    required this.videoItem,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final String bvid = videoItem.bvid ?? '';
          final int? cid = videoItem.cid;
          final int? aid = videoItem.aid;

          if (bvid.isEmpty) {
            return;
          }

          try {
            // 如果没有cid，通过API获取
            final int finalCid =
                cid ?? await SearchHttp.ab2c(aid: aid, bvid: bvid);
            final String heroTag = Utils.makeHeroTag(finalCid);

            // 不传videoItem，只传必要的字段（参考PiliPlus的toVideoPage方法）
            Get.toNamed(
              '/video?bvid=$bvid&cid=$finalCid',
              arguments: {
                'heroTag': heroTag,
                'cover': videoItem.cover,
                'title': videoItem.title,
              },
            );
          } catch (err) {
            SmartDialog.showToast(err.toString());
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCover(context),
              const SizedBox(width: 10),
              Expanded(child: _buildContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    return SizedBox(
      width: 160,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            double maxWidth = boxConstraints.maxWidth;
            double maxHeight = boxConstraints.maxHeight;
            return Stack(
              children: [
                Hero(
                  tag: 'music_video_${videoItem.bvid}',
                  child: NetworkImgLayer(
                    src: videoItem.cover ?? '',
                    width: maxWidth,
                    height: maxHeight,
                  ),
                ),
                if (videoItem.duration != null)
                  PBadge(
                    text: _formatDuration(videoItem.duration!),
                    right: 6.0,
                    bottom: 6.0,
                    type: 'gray',
                    size: 'small',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          videoItem.title ?? '',
          textAlign: TextAlign.start,
          style: const TextStyle(
            letterSpacing: 0.3,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 14,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              _formatNumber(videoItem.play ?? 0),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chat_bubble_outline,
              size: 14,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 4),
            Text(
              _formatNumber(videoItem.danmu ?? 0),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (videoItem.labelList != null && videoItem.labelList!.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: videoItem.labelList!
                .map((label) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label.name ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ))
                .toList(),
          ),
        const SizedBox(height: 4),
        Text(
          videoItem.upNickName ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  String _formatNumber(int num) {
    if (num >= 10000) {
      return '${(num / 10000).toStringAsFixed(1)}万';
    }
    return num.toString();
  }
}
