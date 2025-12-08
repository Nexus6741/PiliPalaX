import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/badge.dart';
import 'package:PiliPalaX/models/pgc/fav_pgc/list.dart';
import 'package:PiliPalaX/models/pgc/pgc_index_result/list.dart';
import 'package:PiliPalaX/models/common/search_type.dart';
import 'package:PiliPalaX/models/bangumi/info.dart';
import 'package:PiliPalaX/http/search.dart';
import 'package:PiliPalaX/utils/utils.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';

// PGC卡片 - 垂直布局
class PgcCardV extends StatelessWidget {
  const PgcCardV({
    super.key,
    this.item,
    this.pgcItem,
    this.longPress,
    this.longPressEnd,
  });

  final PgcIndexItem? item; // 推荐/索引项目
  final FavPgcItemModel? pgcItem; // 追剧项目
  final Function()? longPress;
  final Function()? longPressEnd;

  @override
  Widget build(BuildContext context) {
    // 优先使用 item，如果没有则使用 pgcItem
    final seasonId = item?.seasonId ?? pgcItem?.seasonId;
    final mediaId = item?.mediaId ?? pgcItem?.mediaId;
    final cover = item?.cover ?? pgcItem?.cover;
    final badge = item?.badge ?? pgcItem?.badge;
    final seasonStatus = item?.seasonStatus ?? pgcItem?.seasonStatus;
    final firstEp = item?.firstEp?.epId ?? pgcItem?.firstEp;

    String heroTag = Utils.makeHeroTag(mediaId ?? 0);

    return Card(
      elevation: 0,
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.zero,
      child: GestureDetector(
        child: InkWell(
          onTap: () async {
            // 导航到视频播放页面
            if (seasonId == null) {
              SmartDialog.showToast('资源加载失败');
              return;
            }

            try {
              SmartDialog.showLoading(msg: '资源获取中');

              // 获取番剧信息
              var result = await SearchHttp.bangumiInfo(
                seasonId: seasonId,
                epId: firstEp,
              );

              SmartDialog.dismiss();

              if (result['status']) {
                BangumiInfoModel data = result['data'];
                final episodes = data.episodes;

                if (episodes != null && episodes.isNotEmpty) {
                  // 找到要播放的集数
                  EpisodeItem? episode;
                  if (firstEp != null) {
                    try {
                      episode = episodes.firstWhere(
                        (e) => e.id == firstEp,
                      );
                    } catch (e) {
                      // 如果找不到指定的集数，使用第一集
                      episode = episodes.first;
                    }
                  } else {
                    episode = episodes.first;
                  }

                  // 检查是否有bvid和cid
                  if (episode.bvid == null || episode.cid == null) {
                    SmartDialog.showToast('视频资源不可用');
                    return;
                  }

                  // 导航到视频页面
                  Get.toNamed(
                    '/video?bvid=${episode.bvid}&cid=${episode.cid}&seasonId=$seasonId&epId=${episode.id}',
                    arguments: {
                      'pic': cover,
                      'heroTag': heroTag,
                      'videoType': SearchType.media_bangumi,
                      'bangumiItem': data,
                    },
                  );
                } else {
                  SmartDialog.showToast('暂无可播放内容');
                }
              } else {
                SmartDialog.showToast(result['msg'] ?? '获取视频信息失败');
              }
            } catch (e) {
              SmartDialog.dismiss();
              SmartDialog.showToast('加载失败: $e');
              print('⚠️ PGC卡片导航失败: $e');
            }
          },
          child: Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: StyleString.imgRadius,
                  topRight: StyleString.imgRadius,
                  bottomLeft: StyleString.imgRadius,
                  bottomRight: StyleString.imgRadius,
                ),
                child: AspectRatio(
                  aspectRatio: 0.65,
                  child: LayoutBuilder(builder: (context, boxConstraints) {
                    final double maxWidth = boxConstraints.maxWidth;
                    final double maxHeight = boxConstraints.maxHeight;
                    return Stack(
                      children: [
                        Hero(
                          tag: heroTag,
                          child: NetworkImgLayer(
                            src: cover,
                            width: maxWidth,
                            height: maxHeight,
                          ),
                        ),
                        if (badge != null && badge.isNotEmpty)
                          PBadge(
                              text: badge,
                              top: 6,
                              right: 6,
                              bottom: null,
                              left: null),
                        if (seasonStatus != null)
                          PBadge(
                            text: seasonStatus == 0 ? '连载中' : '已完结',
                            top: null,
                            right: null,
                            bottom: 6,
                            left: 6,
                            type: 'gray',
                          ),
                      ],
                    );
                  }),
                ),
              ),
              PgcContent(item: item, pgcItem: pgcItem)
            ],
          ),
        ),
      ),
    );
  }
}

class PgcContent extends StatelessWidget {
  const PgcContent({super.key, this.item, this.pgcItem});

  final PgcIndexItem? item;
  final FavPgcItemModel? pgcItem;

  @override
  Widget build(BuildContext context) {
    final title = item?.title ?? pgcItem?.title ?? '未知';
    final score = item?.score ?? pgcItem?.rating?.score?.toString();
    final progress = pgcItem?.progress;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 5, 0, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(
                  title,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
              ],
            ),
            const SizedBox(height: 1),
            if (score != null && score.isNotEmpty)
              Text(
                '评分: $score',
                maxLines: 1,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            if (progress != null && progress.isNotEmpty)
              Text(
                progress,
                maxLines: 1,
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
