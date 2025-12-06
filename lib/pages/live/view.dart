import 'dart:async';

import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/skeleton/video_card_v.dart';
import 'package:PiliPalaX/common/widgets/animated_dialog.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/common/widgets/overlay_pop.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/live/live_feed_index/index.dart';
import 'package:PiliPalaX/pages/home/index.dart';
import 'package:PiliPalaX/pages/main/index.dart';
import 'package:PiliPalaX/pages/live_area/view.dart';
import 'package:PiliPalaX/pages/live_follow/view.dart';
import 'package:PiliPalaX/utils/feed_back.dart';

import '../../utils/grid.dart';
import 'controller.dart';
import 'widgets/live_item_app.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage>
    with AutomaticKeepAliveClientMixin {
  final LiveController _liveController = Get.put(LiveController());
  late ScrollController scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scrollController = _liveController.scrollController;
    StreamController<bool> mainStream =
        Get.find<MainController>().bottomBarStream;
    StreamController<bool> searchBarStream =
        Get.find<HomeController>().searchBarStream;
    scrollController.addListener(
      () {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          EasyThrottle.throttle('liveList', const Duration(milliseconds: 200),
              () {
            _liveController.onLoadMore();
          });
        }

        final ScrollDirection direction =
            scrollController.position.userScrollDirection;
        if (direction == ScrollDirection.forward) {
          mainStream.add(true);
          searchBarStream.add(true);
        } else if (direction == ScrollDirection.reverse) {
          mainStream.add(false);
          searchBarStream.add(false);
        }
      },
    );
  }

  @override
  void dispose() {
    scrollController.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ThemeData theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.symmetric(horizontal: StyleString.safeSpace),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(StyleString.imgRadius),
      ),
      child: RefreshIndicator(
        displacement: 10.0,
        edgeOffset: 10.0,
        onRefresh: _liveController.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(
                top: StyleString.cardSpace,
                bottom: 100,
              ),
              sliver: SliverMainAxisGroup(
                slivers: [
                  // 顶部：关注 + 分区入口
                  Obx(() => _buildTop(theme, _liveController.topState.value)),
                  // 内容列表
                  Obx(() =>
                      _buildBody(theme, _liveController.loadingState.value)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部区域（关注列表 + 分区入口）
  Widget _buildTop(ThemeData theme, Pair<LiveCardList?, LiveCardList?> data) {
    return SliverMainAxisGroup(
      slivers: [
        // 关注列表
        if (data.first != null)
          SliverToBoxAdapter(child: _buildFollowList(theme, data.first!)),
        // 分区入口
        if (data.second?.cardData?.areaEntranceV3?.list?.isNotEmpty == true)
          SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _buildAreaTabs(theme, data.second!),
                ),
                // 游戏赛事按钮
                IconButton(
                  tooltip: '游戏赛事',
                  icon: const Icon(Icons.gamepad, size: 20),
                  onPressed: () {
                    final isDark = theme.brightness == Brightness.dark;
                    Get.toNamed(
                      '/webview',
                      parameters: {
                        'url':
                            'https://www.bilibili.com/h5/match/data/home?navhide=1&native.theme=${isDark ? 2 : 1}&night=${isDark ? 1 : 0}',
                      },
                    );
                  },
                ),
                // 全部标签按钮
                IconButton(
                  tooltip: '全部标签',
                  icon: const Icon(Icons.widgets, size: 20),
                  onPressed: () => Get.to(() => const LiveAreaPage()),
                ),
              ],
            ),
          )
        else
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
      ],
    );
  }

  /// 构建分区标签
  Widget _buildAreaTabs(ThemeData theme, LiveCardList areaItem) {
    final list = areaItem.cardData!.areaEntranceV3!.list!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // 推荐标签
          Obx(() {
            final isCurr = _liveController.areaIndex.value == 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildAreaChip(
                theme: theme,
                text: '推荐',
                isSelected: isCurr,
                onTap: () => _liveController.onSelectArea(0, null),
              ),
            );
          }),
          // 分区标签
          ...List.generate(list.length, (index) {
            final item = list[index];
            return Obx(() {
              final isCurr = (index + 1) == _liveController.areaIndex.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildAreaChip(
                  theme: theme,
                  text: item.title ?? item.areaV2Name ?? '',
                  isSelected: isCurr,
                  onTap: () => _liveController.onSelectArea(index + 1, item),
                ),
              );
            });
          }),
        ],
      ),
    );
  }

  /// 构建分区标签按钮
  Widget _buildAreaChip({
    required ThemeData theme,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isSelected
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: StyleString.cardSpace,
    crossAxisSpacing: StyleString.cardSpace,
    maxCrossAxisExtent: Grid.maxRowWidth,
    childAspectRatio: StyleString.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(80),
  );

  /// 构建内容区域
  Widget _buildBody(ThemeData theme, LoadingState<List?> loadingState) {
    if (loadingState is Loading) {
      return SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemBuilder: (context, index) => const VideoCardVSkeleton(),
        itemCount: 10,
      );
    } else if (loadingState is Success) {
      final response = (loadingState as Success<List?>).response;
      return SliverMainAxisGroup(
        slivers: [
          // 排序标签
          if (_liveController.newTags?.isNotEmpty == true)
            SliverToBoxAdapter(child: _buildSortTags(theme)),
          // 直播列表
          (response?.isNotEmpty == true)
              ? SliverGrid.builder(
                  gridDelegate: gridDelegate,
                  itemBuilder: (context, index) {
                    final item = response[index];
                    // 可能是 LiveCardList 或 CardLiveItem
                    if (item is LiveCardList) {
                      return LiveCardVApp(item: item.cardData!.smallCardV1!);
                    }
                    return LiveCardVApp(item: item);
                  },
                  itemCount: response!.length,
                )
              : HttpError(
                  errMsg: '暂无直播',
                  fn: _liveController.onReload,
                ),
        ],
      );
    } else if (loadingState is Error) {
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: (loadingState as Error).errMsg,
          fn: _liveController.onReload,
        ),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox());
  }

  /// 构建排序标签
  Widget _buildSortTags(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: List.generate(_liveController.newTags!.length, (index) {
          final tag = _liveController.newTags![index];
          return Obx(() {
            final isCurr = index == _liveController.tagIndex.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _liveController.onSelectTag(index, tag.sortType),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurr
                        ? theme.colorScheme.secondaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    tag.name ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: isCurr
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          });
        }),
      ),
    );
  }

  /// 构建关注列表
  Widget _buildFollowList(ThemeData theme, LiveCardList item) {
    final followData = item.cardData?.myIdolV1;
    if (followData == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '我的关注  '),
                  TextSpan(
                    text: '${followData.extraInfo?.totalCount ?? 0}',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: '人正在直播',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Get.to(() => const LiveFollowPage()),
              child: Text(
                '更多',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
          ],
        ),
        if (followData.list?.isNotEmpty == true)
          _buildFollowBody(theme, followData.list!),
      ],
    );
  }

  /// 构建关注主播横向列表
  Widget _buildFollowBody(ThemeData theme, List<CardLiveItem> followList) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: followList.map((item) {
          return SizedBox(
            width: 70,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Get.toNamed('/liveRoom?roomid=${item.roomid}'),
              onLongPress: () {
                feedBack();
                Get.toNamed('/member?mid=${item.uid}');
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1.5,
                        color: theme.colorScheme.primary,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: NetworkImgLayer(
                      type: 'avatar',
                      width: 45,
                      height: 45,
                      src: item.face,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.uname ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _removePopupDialog() {
    _liveController.popupDialog.last?.remove();
    _liveController.popupDialog.removeLast();
  }

  OverlayEntry _createPopupDialog(liveItem) {
    return OverlayEntry(
      builder: (context) => AnimatedDialog(
        closeFn: _removePopupDialog,
        child: OverlayPop(
          videoItem: liveItem,
          closeFn: _removePopupDialog,
        ),
      ),
    );
  }
}
