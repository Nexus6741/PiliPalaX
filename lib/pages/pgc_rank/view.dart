import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/badge.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/pgc/rank_item.dart';
import 'package:PiliPalaX/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:PiliPalaX/http/search.dart';
import 'package:PiliPalaX/models/bangumi/info.dart';
import 'package:PiliPalaX/models/common/search_type.dart';

import 'controller.dart';

class PgcRankPage extends StatefulWidget {
  const PgcRankPage({super.key});

  @override
  State<PgcRankPage> createState() => _PgcRankPageState();
}

class _PgcRankPageState extends State<PgcRankPage>
    with SingleTickerProviderStateMixin {
  late PgcRankController _controller;
  late TabController _tabController;
  late RankType rankType;
  late List<String> tabLabels;

  @override
  void initState() {
    super.initState();
    // 从路由参数获取排行榜类型
    rankType = Get.arguments?['rankType'] ?? RankType.bangumi;

    // 根据类型设置tab标签
    if (rankType == RankType.bangumi) {
      tabLabels = ['番剧', '国创'];
    } else {
      tabLabels = ['电影', '电视剧', '纪录片', '综艺'];
    }

    _controller = Get.put(
      PgcRankController(rankType: rankType),
      tag: rankType.name,
    );
    _tabController = TabController(length: tabLabels.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _controller.switchTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    Get.delete<PgcRankController>(tag: rankType.name);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${rankType == RankType.bangumi ? '番剧' : '影视'}排行榜'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: tabLabels.map((label) => Tab(text: label)).toList(),
          indicatorSize: TabBarIndicatorSize.label,
          isScrollable: tabLabels.length > 3,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          tabLabels.length,
          (index) => _buildRankList(index),
        ),
      ),
    );
  }

  /// 构建排行榜列表
  Widget _buildRankList(int tabIndex) {
    return Obx(() {
      final seasonType = _controller.seasonTypes[tabIndex];
      final state = _controller.rankStates[seasonType]?.value;

      if (state == null || state is Loading) {
        return const Center(child: CircularProgressIndicator());
      } else if (state is Success<List<PgcRankItem>>) {
        final list = state.response;
        if (list.isEmpty) {
          return HttpError(
            errMsg: '暂无数据',
            fn: _controller.onRefresh,
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: StyleString.safeSpace,
              vertical: 12,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return _buildRankCard(list[index]);
            },
          ),
        );
      } else if (state is Error) {
        return HttpError(
          errMsg: (state as Error).errMsg,
          fn: _controller.onRefresh,
        );
      }

      return const SizedBox.shrink();
    });
  }

  /// 构建排行榜卡片
  Widget _buildRankCard(PgcRankItem item) {
    final String heroTag = Utils.makeHeroTag(item.seasonId);

    return Card(
      elevation: 0,
      clipBehavior: Clip.hardEdge,
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _onTapCard(item, heroTag),
        child: SizedBox(
          height: 140,
          child: Row(
            children: [
              // 封面
              SizedBox(
                width: 100,
                child: Stack(
                  children: [
                    Hero(
                      tag: heroTag,
                      child: NetworkImgLayer(
                        src: item.cover ?? '',
                        width: 100,
                        height: 140,
                      ),
                    ),
                    // 排名标签
                    if (item.rank != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRankColor(item.rank!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item.rank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Badge标签
                    if (item.badge != null && item.badge!.isNotEmpty)
                      PBadge(
                        text: item.badge!,
                        top: null,
                        right: 6,
                        bottom: 6,
                        left: null,
                      ),
                  ],
                ),
              ),
              // 信息
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Text(
                        item.title ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // 更新信息
                      if (item.newEp?.indexShow != null)
                        Text(
                          item.newEp!.indexShow!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      // 统计信息
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCount(item.stat?.view),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.favorite_border,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCount(item.stat?.follow),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          if (item.rating != null) ...[
                            const Spacer(),
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.rating!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ],
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

  /// 点击卡片
  Future<void> _onTapCard(PgcRankItem item, String heroTag) async {
    final int seasonId = item.seasonId ?? 0;
    if (seasonId == 0) return;

    SmartDialog.showLoading(msg: '获取中...');
    final res = await SearchHttp.bangumiInfo(seasonId: seasonId);
    SmartDialog.dismiss().then((value) {
      if (res['status']) {
        if (res['data'].episodes.isEmpty) {
          SmartDialog.showToast('资源加载失败');
          return;
        }
        EpisodeItem episode = res['data'].episodes.first;
        int? epId = res['data'].userStatus?.progress?.lastEpId;
        if (epId == null) {
          epId = episode.epId;
        } else {
          for (var item in res['data'].episodes) {
            if (item.epId == epId) {
              episode = item;
              break;
            }
          }
        }
        String bvid = episode.bvid!;
        int cid = episode.cid!;
        String pic = episode.cover!;

        Get.toNamed(
          '/video?bvid=$bvid&cid=$cid&seasonId=$seasonId&epId=$epId',
          arguments: {
            'pic': pic,
            'heroTag': heroTag,
            'videoType': SearchType.media_bangumi,
            'bangumiItem': res['data'],
          },
        );
      } else {
        SmartDialog.showToast(res['msg']);
      }
    });
  }

  /// 获取排名颜色
  Color _getRankColor(int rank) {
    if (rank == 1) {
      return const Color(0xFFFFD700); // 金色
    } else if (rank == 2) {
      return const Color(0xFFC0C0C0); // 银色
    } else if (rank == 3) {
      return const Color(0xFFCD7F32); // 铜色
    } else {
      return Colors.grey;
    }
  }

  /// 格式化数字
  String _formatCount(int? count) {
    if (count == null) return '-';
    if (count >= 100000000) {
      return '${(count / 100000000).toStringAsFixed(1)}亿';
    } else if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    } else {
      return count.toString();
    }
  }
}
