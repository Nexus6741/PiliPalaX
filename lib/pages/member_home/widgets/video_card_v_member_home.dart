import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/badge.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/http/search.dart';
import 'package:PiliPalaX/models/member/space_data.dart';
import 'package:PiliPalaX/utils/id_utils.dart';
import 'package:PiliPalaX/utils/utils.dart';

/// 用户空间主页视频卡片 - 垂直布局
/// 参考PiliPlus的VideoCardVMemberHome
class VideoCardVMemberHome extends StatelessWidget {
  const VideoCardVMemberHome({
    super.key,
    required this.videoItem,
  });

  final SpaceArchiveItem videoItem;

  @override
  Widget build(BuildContext context) {
    // 使用 param (aid) 或 bvid 生成 heroTag
    final String heroTag = Utils.makeHeroTag(videoItem.param ?? videoItem.bvid);

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _onTap(heroTag),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: StyleString.aspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Hero(
                        tag: heroTag,
                        child: NetworkImgLayer(
                          src: videoItem.cover ?? videoItem.pic ?? '',
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                        ),
                      ),
                      // 充电视频或合作视频标识（右上角）
                      Builder(builder: (context) {
                        String? badge;
                        String badgeType = 'primary';

                        // 判断是否为充电视频
                        if (videoItem.ugcPay != null && videoItem.ugcPay! > 0) {
                          badge = '充电专属';
                          badgeType = 'error';
                        }
                        // 判断是否为合作视频（优先级低于充电视频）
                        else if (videoItem.isCooperation == true) {
                          badge = '合作';
                          badgeType = 'primary';
                        }

                        if (badge != null) {
                          return Positioned(
                            top: 6,
                            right: 7,
                            child: PBadge(
                              text: badge,
                              type: badgeType,
                              size: 'small',
                            ),
                          );
                        }
                        return const SizedBox();
                      }),
                      // 时长
                      if (videoItem.duration != null && videoItem.duration! > 0)
                        Positioned(
                          bottom: 6,
                          right: 7,
                          child: PBadge(
                            text: _formatDuration(videoItem.duration!),
                            type: 'gray',
                            size: 'small',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
        child: Text(
          '${videoItem.title ?? ''}\n',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(height: 1.38),
        ),
      ),
    );
  }

  Future<void> _onTap(String heroTag) async {
    // 获取 bvid 和 aid
    String? bvid = videoItem.bvid;
    int? aid;

    if (videoItem.param != null) {
      aid = int.tryParse(videoItem.param!);
    }

    // 如果没有 bvid，尝试从 aid 转换
    if (bvid == null && aid != null) {
      bvid = IdUtils.av2bv(aid);
    }

    if (bvid == null) {
      SmartDialog.showToast('视频信息不完整');
      return;
    }

    try {
      int? cid = videoItem.cid;
      cid ??= await SearchHttp.ab2c(aid: aid, bvid: bvid);

      Get.toNamed(
        '/video?bvid=$bvid&cid=$cid',
        arguments: {
          'heroTag': heroTag,
          'pic': videoItem.cover ?? videoItem.pic,
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
