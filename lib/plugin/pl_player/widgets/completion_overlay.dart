import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/http/search.dart';
import 'package:PiliPalaX/pages/video/introduction/bangumi/controller.dart';
import 'package:PiliPalaX/pages/video/introduction/detail/controller.dart';
import 'package:PiliPalaX/pages/video/related/controller.dart';
import 'package:PiliPalaX/plugin/pl_player/controller.dart';
import 'package:PiliPalaX/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompletionOverlay extends StatefulWidget {
  final PlPlayerController playerController;
  final VideoIntroController? videoIntroController;
  final BangumiIntroController? bangumiIntroController;

  const CompletionOverlay({
    super.key,
    required this.playerController,
    this.videoIntroController,
    this.bangumiIntroController,
  });

  @override
  State<CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<CompletionOverlay> {
  late RelatedController relatedController;
  String heroTag = '';

  @override
  void initState() {
    super.initState();
    if (widget.videoIntroController != null) {
      heroTag = widget.videoIntroController!.heroTag;
    } else if (widget.bangumiIntroController != null) {
      heroTag = widget.bangumiIntroController!.heroTag;
    }
    try {
      relatedController = Get.find<RelatedController>(tag: heroTag);
    } catch (_) {
      relatedController = Get.put(RelatedController(), tag: heroTag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景层 - 半透明黑色
        Container(
          color: Colors.black.withOpacity(0.85),
        ),

        // 顶部区域 - 用户信息和操作按钮
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Info and Actions
                if (widget.videoIntroController != null) _buildUserInfo(),
                const SizedBox(height: 20),
                // Recommended Videos
                const Text(
                  '推荐视频',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // 底部区域 - 相关视频列表
        Positioned(
          top: 200,
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildRelatedVideos(),
        ),

        // 右下角关闭按钮
        Positioned(
          right: 20,
          bottom: 20,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // 退出全屏
                widget.playerController.triggerFullScreen(status: false);
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedVideos() {
    return Obx(() {
      if (relatedController.relatedVideoList.isEmpty) {
        return const Center(
          child: Text('暂无推荐视频', style: TextStyle(color: Colors.white)),
        );
      }

      // 使用 ListView.builder 正常显示列表
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: relatedController.relatedVideoList.length,
          itemBuilder: (context, index) {
            final video = relatedController.relatedVideoList[index];
            return _buildVideoCard(video);
          },
        ),
      );
    });
  }

  Widget _buildVideoCard(dynamic video) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          String newHeroTag = Utils.makeHeroTag(video.bvid);
          if (video.cid != null) {
            Get.toNamed('/video?bvid=${video.bvid}&cid=${video.cid}',
                arguments: {'videoItem': video, 'heroTag': newHeroTag});
          } else {
            SearchHttp.ab2c(aid: video.aid, bvid: video.bvid).then((cid) =>
                Get.toNamed('/video?bvid=${video.bvid}&cid=${video.cid}',
                    arguments: {'videoItem': video, 'heroTag': newHeroTag}));
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  NetworkImgLayer(
                    src: video.pic ?? '',
                    width: 200,
                    height: 112,
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        Utils.timeFormat(video.duration ?? 0),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              video.title ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              video.owner?.name ?? '',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    final ctr = widget.videoIntroController!;
    return Obx(() {
      final owner = ctr.videoDetail.value.owner;
      if (owner == null) return const SizedBox();

      return Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              // 跳转到用户空间
              Get.toNamed(
                '/member?mid=${owner.mid}',
                arguments: {'face': owner.face},
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: NetworkImgLayer(
                  src: owner.face ?? '',
                  width: 48,
                  height: 48,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and Follow
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                owner.name ?? '',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              // Follow Button
              GestureDetector(
                onTap: () => ctr.actionRelationMod(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ctr.followStatus['attribute'] == 0 ? '+ 关注' : '已关注',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Actions
          _buildActionButtons(),
        ],
      );
    });
  }

  Widget _buildActionButtons() {
    final ctr = widget.videoIntroController!;
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.refresh,
          label: '重播',
          onTap: () {
            widget.playerController.seekTo(Duration.zero);
            widget.playerController.play();
          },
        ),
        Obx(() => _buildActionButton(
              icon:
                  ctr.hasLike.value ? Icons.thumb_up : Icons.thumb_up_outlined,
              label: '点赞',
              color: ctr.hasLike.value
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              onTap: () => ctr.actionLikeVideo(),
            )),
        Obx(() => _buildActionButton(
              icon: ctr.hasDislike.value
                  ? Icons.thumb_down
                  : Icons.thumb_down_outlined,
              label: '不喜欢',
              color: ctr.hasDislike.value
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              onTap: () => ctr.actionDislikeVideo(),
            )),
        Obx(() => _buildActionButton(
              icon: Icons.monetization_on_outlined,
              label: '投币',
              color: ctr.hasCoin.value
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              onTap: () => ctr.actionCoinVideo(),
            )),
        Obx(() => _buildActionButton(
              icon: ctr.hasFav.value ? Icons.star : Icons.star_outline,
              label: '收藏',
              color: ctr.hasFav.value
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
              onTap: () => ctr.actionFavVideo(),
            )),
        _buildActionButton(
          icon: Icons.share_outlined,
          label: '分享',
          onTap: () => ctr.actionShareVideo(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: color, size: 28),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
