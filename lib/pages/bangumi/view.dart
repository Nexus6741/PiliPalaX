import 'dart:async';
import 'dart:math';

import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:nil/nil.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';

import '../../utils/grid.dart';
import 'controller.dart';
import 'widgets/bangumi_card_v.dart';
import 'widgets/bangumi_card_timeline.dart';
import '../pgc_rank/controller.dart' show RankType;

class BangumiPage extends StatefulWidget {
  const BangumiPage({super.key});

  @override
  State<BangumiPage> createState() => _BangumiPageState();
}

class _BangumiPageState extends State<BangumiPage>
    with AutomaticKeepAliveClientMixin {
  final BangumiController _bangumiController = Get.put(BangumiController());
  late Future? _futureBuilderFuture;
  late Future? _futureBuilderFutureFollow;
  late ScrollController scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scrollController = _bangumiController.scrollController;
    // 暂时禁用滚动隐藏搜索栏功能
    // StreamController<bool> mainStream =
    //     Get.find<MainController>().bottomBarStream;
    // HomeController homeController = Get.find<HomeController>();
    _futureBuilderFuture = _bangumiController.queryBangumiListFeed();
    _futureBuilderFutureFollow = _bangumiController.queryBangumiFollow();
    scrollController.addListener(
      () async {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          EasyThrottle.throttle('my-throttler', const Duration(seconds: 1), () {
            _bangumiController.isLoadingMore = true;
            _bangumiController.onLoad();
          });
        }

        // 暂时禁用滚动隐藏搜索栏功能
        // final ScrollDirection direction =
        //     scrollController.position.userScrollDirection;
        // if (direction == ScrollDirection.forward) {
        //   mainStream.add(true);
        //   homeController.showSearchBar.value = true;
        // } else if (direction == ScrollDirection.reverse) {
        //   mainStream.add(false);
        //   homeController.showSearchBar.value = false;
        // }
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
    return RefreshIndicator(
      displacement: 10.0,
      edgeOffset: 10.0,
      onRefresh: () async {
        await _bangumiController.queryBangumiListFeed();
        await _bangumiController.queryBangumiFollow();
        return _bangumiController.queryBangumiTimeline();
      },
      child: CustomScrollView(
        controller: _bangumiController.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 最近追番
          SliverToBoxAdapter(
            child: Obx(
              () => Visibility(
                visible: _bangumiController.userLogin.value,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: StyleString.safeSpace, bottom: 10, left: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '最近追番',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            tooltip: '刷新',
                            onPressed: () {
                              setState(() {
                                _futureBuilderFutureFollow =
                                    _bangumiController.queryBangumiFollow();
                              });
                            },
                            icon: const Icon(
                              Icons.refresh,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: Grid.maxRowWidth * 1,
                      child: FutureBuilder(
                        future: _futureBuilderFutureFollow,
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            if (snapshot.data == null) {
                              return const SizedBox();
                            }
                            Map data = snapshot.data as Map;
                            List list = _bangumiController.bangumiFollowList;
                            if (data['status']) {
                              return Obx(
                                () => list.isNotEmpty
                                    ? ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: list.length,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            width: Grid.maxRowWidth / 2,
                                            height: Grid.maxRowWidth * 1,
                                            margin: EdgeInsets.only(
                                                left: StyleString.safeSpace,
                                                right: index ==
                                                        _bangumiController
                                                                .bangumiFollowList
                                                                .length -
                                                            1
                                                    ? StyleString.safeSpace
                                                    : 0),
                                            child: BangumiCardV(
                                              bangumiItem: _bangumiController
                                                  .bangumiFollowList[index],
                                            ),
                                          );
                                        },
                                      )
                                    : const SizedBox(
                                        child: Center(
                                          child: Text('还没有追番'),
                                        ),
                                      ),
                              );
                            } else {
                              return nil;
                            }
                          } else {
                            return nil;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 追番时间表
          SliverToBoxAdapter(
            child: Obx(() {
              if (_bangumiController.timelineLoading.value) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (_bangumiController.timelineList.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildTimeline();
            }),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 10, bottom: 10, left: 16, right: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '推荐',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Get.toNamed('/pgcRank', arguments: {
                            'rankType': RankType.bangumi,
                          });
                        },
                        icon: const Icon(Icons.leaderboard, size: 18),
                        label: const Text('排行榜'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Get.toNamed('/pgcIndex');
                        },
                        icon: const Icon(Icons.grid_view, size: 18),
                        label: const Text('索引'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                StyleString.safeSpace, 0, StyleString.safeSpace, 0),
            sliver: FutureBuilder(
              future: _futureBuilderFuture,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  Map data = snapshot.data as Map;
                  if (data['status']) {
                    return Obx(() => contentGrid(
                        _bangumiController, _bangumiController.bangumiList));
                  } else {
                    return HttpError(
                      errMsg: data['msg'],
                      fn: () {
                        setState(() {
                          _futureBuilderFuture =
                              _bangumiController.queryBangumiListFeed();
                        });
                      },
                    );
                  }
                } else {
                  return contentGrid(_bangumiController, []);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget contentGrid(ctr, bangumiList) {
    return AnimationLimiter(
      key: ValueKey(bangumiList!.isNotEmpty ? bangumiList.first.hashCode : 0),
      child: SliverGrid(
        gridDelegate: SliverGridDelegateWithExtentAndRatio(
          // 行间距
          mainAxisSpacing: StyleString.cardSpace - 2,
          // 列间距
          crossAxisSpacing: StyleString.cardSpace,
          // 最大宽度
          maxCrossAxisExtent: Grid.maxRowWidth / 3 * 2,
          childAspectRatio: 0.65,
          mainAxisExtent: MediaQuery.textScalerOf(context).scale(60),
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: 2,
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: bangumiList!.isNotEmpty
                      ? BangumiCardV(bangumiItem: bangumiList[index])
                      : nil,
                ),
              ),
            );
          },
          childCount: bangumiList!.isNotEmpty ? bangumiList!.length : 10,
        ),
      ),
    );
  }

  // 追番时间表
  Widget _buildTimeline() {
    final timelineList = _bangumiController.timelineList;
    if (timelineList.isEmpty) {
      return const SizedBox.shrink();
    }

    // 找到今天的索引
    final initialIndex = max(
      0,
      timelineList.indexWhere((item) => item.isToday == 1),
    );

    return Container(
      margin: const EdgeInsets.only(top: StyleString.safeSpace),
      height: Grid.maxRowWidth / 2 / 0.75 +
          MediaQuery.textScalerOf(context).scale(96),
      child: DefaultTabController(
        initialIndex: initialIndex,
        length: timelineList.length,
        child: Column(
          children: [
            // 标题和Tab栏
            Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  '追番时间表',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerHeight: 0,
                    overlayColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                    splashFactory: NoSplash.splashFactory,
                    padding: const EdgeInsets.only(right: 10),
                    indicatorPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                    labelStyle: const TextStyle(fontSize: 14),
                    dividerColor: Colors.transparent,
                    tabs: timelineList.map((item) {
                      return Tab(
                        text:
                            '${item.date} ${item.isToday == 1 ? '今天' : '周${const [
                                '一',
                                '二',
                                '三',
                                '四',
                                '五',
                                '六',
                                '日',
                              ][item.dayOfWeek! - 1]}'}',
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            // 内容区域
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: timelineList.map((item) {
                  if (item.episodes == null || item.episodes!.isEmpty) {
                    return const Center(child: Text('暂无更新'));
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: item.episodes!.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return Container(
                        width: Grid.maxRowWidth / 2,
                        margin: EdgeInsets.only(
                          left: StyleString.safeSpace,
                          right: index == item.episodes!.length - 1
                              ? StyleString.safeSpace
                              : 0,
                        ),
                        child: BangumiCardTimeline(
                          item: item.episodes![index],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
