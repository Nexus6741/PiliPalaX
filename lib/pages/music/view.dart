import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/http/music.dart';
import 'package:PiliPalaX/models/music/bgm_detail.dart';
import 'package:PiliPalaX/pages/music/controller.dart';
import 'package:PiliPalaX/pages/music/video/view.dart';
import 'package:PiliPalaX/utils/feed_back.dart';
import 'package:PiliPalaX/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

/// 音乐详情页
class MusicDetailPage extends StatefulWidget {
  const MusicDetailPage({super.key});

  @override
  State<MusicDetailPage> createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  late final MusicDetailController controller = Get.put(
    MusicDetailController(),
    tag: Get.parameters['musicId']!,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: controller.onRefresh,
        child: Obx(() => _buildBody()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Obx(() {
        final state = controller.infoState.value;
        final showTitle = controller.showTitle.value;
        if (state is Success<MusicDetail> && state.data != null) {
          final data = state.data!;
          final cover = data.mvCover ?? '';
          final title = data.musicTitle ?? '';
          return AnimatedOpacity(
            opacity: showTitle ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !showTitle,
              child: Row(
                children: [
                  NetworkImgLayer(
                    src: cover,
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => Share.share(controller.shareUrl),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final state = controller.infoState.value;
    if (state is Success<MusicDetail> && state.data != null) {
      return _buildContent(state.data!);
    } else if (state is Error<MusicDetail>) {
      return _buildError(state.errMsg ?? '加载失败');
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent(MusicDetail item) {
    return CustomScrollView(
      controller: controller.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildMusicCard(item)),
        if (item.hotSongHeat?.songHeat != null &&
            item.hotSongHeat!.songHeat!.isNotEmpty)
          SliverToBoxAdapter(child: _buildHeatTrend(item)),
        SliverToBoxAdapter(child: _buildActions(item)),
      ],
    );
  }

  Widget _buildMusicCard(MusicDetail item) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面和基本信息
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    // TODO: 图片预览
                  },
                  child: Hero(
                    tag: 'music_${controller.musicId}',
                    child: NetworkImgLayer(
                      src: item.mvCover ?? '',
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _copyText(item.musicTitle ?? ''),
                        child: Text(
                          item.musicTitle ?? '',
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 艺术家信息
                      if (item.artistsList != null &&
                          item.artistsList!.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: item.artistsList!
                              .map((artist) => _buildArtist(artist))
                              .toList(),
                        ),
                      // 发行日期
                      if (item.musicPublish != null &&
                          item.musicPublish!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '发行日期：${item.musicPublish}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // 标签和MV按钮
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (item.musicRank != null &&
                              item.musicRank!.isNotEmpty)
                            Chip(
                              label: Text(
                                item.musicRank!,
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          if (item.mvCid != null && item.mvCid != 0)
                            GestureDetector(
                              onTap: () => _goToMV(item),
                              child: const Chip(
                                avatar: Icon(
                                  Icons.play_circle_outline,
                                  size: 16,
                                ),
                                label: Text(
                                  '看MV',
                                  style: TextStyle(fontSize: 11),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 详细信息
            if (_buildMusicInfo(item).isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                _buildMusicInfo(item),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            // 统计信息
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('热度', item.hotSongHeat?.lastHeat),
                _buildStatItem('播放', item.listenPv),
                GestureDetector(
                  onTap: () => _goToRecommendVideos(item),
                  child: _buildStatItem('稿件', item.musicRelation, true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtist(Artist artist) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        if (artist.mid != null && artist.mid != 0) {
          Get.toNamed(
            '/member',
            parameters: {'mid': artist.mid.toString()},
          );
        } else {
          _copyText(artist.name ?? '');
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (artist.face != null && artist.face!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: NetworkImgLayer(
                src: artist.face ?? '',
                width: 16,
                height: 16,
              ),
            ),
          Text(
            '${artist.identity ?? ''}: ${artist.name ?? ''}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _buildMusicInfo(MusicDetail item) {
    final List<String> info = [];
    if (item.originArtist != null && item.originArtist!.isNotEmpty) {
      info.add('原唱：${item.originArtist}');
    } else if (item.originArtistList != null &&
        item.originArtistList!.isNotEmpty) {
      info.add('原唱：${item.originArtistList}');
    }
    if (item.album != null && item.album!.isNotEmpty) {
      info.add('专辑：${item.album}');
    }
    if (item.musicSource != null && item.musicSource!.isNotEmpty) {
      info.add('出处：${item.musicSource}');
    }
    return info.join('\n');
  }

  Widget _buildStatItem(String label, int? value, [bool showArrow = false]) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value != null ? _formatNumber(value) : '-',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showArrow)
              Icon(
                Icons.keyboard_arrow_right,
                size: 18,
                color: theme.colorScheme.outline,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatTrend(MusicDetail item) {
    final theme = Theme.of(context);
    final heat = item.hotSongHeat!.songHeat!;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '近${heat.length}日热度趋势',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Container(
                height: 150,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 48,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '热度趋势图表',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '最新热度: ${_formatNumber(item.hotSongHeat!.lastHeat ?? 0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(MusicDetail item) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Share.share(controller.shareUrl),
              icon: const Icon(Icons.share, size: 20),
              label: const Text('分享'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              final state = controller.infoState.value;
              if (state is Success<MusicDetail> && state.data != null) {
                final hasLike = state.data!.wishListen ?? false;
                final count = state.data!.wishCount ?? 0;
                return FilledButton.icon(
                  onPressed: () => _handleLike(state.data!),
                  icon: Icon(
                    hasLike ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 20,
                  ),
                  label: Text(_formatNumber(count)),
                  style: FilledButton.styleFrom(
                    backgroundColor: hasLike
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: hasLike
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String errMsg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(errMsg),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.onReload,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _goToMV(MusicDetail item) {
    final String bvid = item.mvBvid ?? '';
    final int cid = item.mvCid ?? 0;
    if (bvid.isEmpty || cid == 0) {
      return;
    }
    final String heroTag = Utils.makeHeroTag(cid);
    // 不传videoItem，只传必要的字段（参考PiliPlus的toVideoPage方法）
    Get.toNamed(
      '/video?bvid=$bvid&cid=$cid',
      arguments: {
        'heroTag': heroTag,
        'cover': item.mvCover,
        'title': item.musicTitle,
      },
    );
  }

  void _goToRecommendVideos(MusicDetail item) {
    Get.to(
      () => const MusicRecommendPage(),
      arguments: {
        'musicId': controller.musicId,
        'musicDetail': item,
      },
    );
  }

  Future<void> _handleLike(MusicDetail item) async {
    feedBack();
    final hasLike = item.wishListen ?? false;
    final res = await MusicHttp.wishUpdate(controller.musicId, hasLike);
    if (res is Success) {
      item.wishListen = !hasLike;
      item.wishCount = (item.wishCount ?? 0) + (hasLike ? -1 : 1);
      controller.infoState.refresh();
      SmartDialog.showToast(hasLike ? '已取消点赞' : '点赞成功');
    } else if (res is Error) {
      SmartDialog.showToast(res.errMsg ?? '操作失败');
    }
  }

  void _copyText(String? text) {
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      SmartDialog.showToast('已复制: $text');
    }
  }

  String _formatNumber(int num) {
    if (num >= 10000) {
      return '${(num / 10000).toStringAsFixed(1)}万';
    }
    return num.toString();
  }
}
