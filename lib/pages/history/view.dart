import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/skeleton/video_card_h.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/common/widgets/no_data.dart';
import 'package:PiliPalaX/pages/history/index.dart';

import '../../common/constants.dart';
import '../../utils/grid.dart';
import 'widgets/item.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.type});

  final String? type;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with AutomaticKeepAliveClientMixin {
  late final HistoryController _historyController = Get.put(
    HistoryController(type: widget.type),
    tag: widget.type ?? 'all',
  );
  Future? _futureBuilderFuture;
  late ScrollController scrollController;

  // 获取当前Tab的controller
  HistoryController currCtr([int? index]) {
    try {
      index ??= _historyController.tabController?.index ?? 0;
      if (index != 0 && _historyController.tabs.isNotEmpty) {
        return Get.find<HistoryController>(
          tag: _historyController.tabs[index - 1].type,
        );
      }
    } catch (_) {}
    return _historyController;
  }

  @override
  void initState() {
    super.initState();
    _futureBuilderFuture = _historyController.queryHistoryList();
    scrollController = _historyController.scrollController;
    scrollController.addListener(
      () {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 300) {
          if (!_historyController.isLoadingMore.value) {
            EasyThrottle.throttle('history', const Duration(seconds: 1), () {
              _historyController.onLoad();
            });
          }
        }
      },
    );
    _historyController.enableMultiple.listen((p0) {
      setState(() {});
    });
  }

  // 选中
  onChoose(index) {
    _historyController.historyList[index].checked =
        !_historyController.historyList[index].checked!;
    _historyController.checkedCount.value =
        _historyController.historyList.where((item) => item.checked!).length;
    _historyController.historyList.refresh();
  }

  // 更新多选状态
  onUpdateMultiple() {
    setState(() {});
  }

  @override
  void dispose() {
    scrollController.removeListener(() {});
    if (widget.type == null) {
      Get.delete<HistoryController>(tag: 'all');
      // 清理所有Tab的controller
      for (var tab in _historyController.tabs) {
        try {
          Get.delete<HistoryController>(tag: tab.type);
        } catch (_) {}
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 如果是子Tab，直接返回内容
    if (widget.type != null) {
      return _buildContent();
    }

    // 主页面，包含Tab
    return Obx(() {
      final enableMultiple = _historyController.enableMultiple.value;
      return PopScope(
        canPop: !enableMultiple,
        onPopInvokedWithResult: (didPop, result) {
          if (enableMultiple) {
            currCtr().enableMultiple.value = false;
            for (var item in currCtr().historyList) {
              item.checked = false;
            }
            currCtr().checkedCount.value = 0;
          }
        },
        child: Scaffold(
          appBar: AppBarWidget(
            visible: enableMultiple,
            child1: _buildNormalAppBar(),
            child2: _buildMultiSelectAppBar(),
          ),
          body: _historyController.tabs.isEmpty
              ? _buildContent()
              : Column(
                  children: [
                    TabBar(
                      controller: _historyController.tabController,
                      isScrollable: false,
                      onTap: (index) {
                        if (!_historyController
                            .tabController!.indexIsChanging) {
                          currCtr().scrollController.jumpTo(0);
                        } else {
                          if (enableMultiple) {
                            currCtr(_historyController
                                    .tabController!.previousIndex)
                                .enableMultiple
                                .value = false;
                            for (var item in currCtr(_historyController
                                    .tabController!.previousIndex)
                                .historyList) {
                              item.checked = false;
                            }
                            currCtr(_historyController
                                    .tabController!.previousIndex)
                                .checkedCount
                                .value = 0;
                          }
                        }
                      },
                      tabs: [
                        const Tab(text: '全部'),
                        ..._historyController.tabs.map(
                          (item) => Tab(text: item.name),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        physics: enableMultiple
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        controller: _historyController.tabController,
                        children: [
                          _buildContent(),
                          ..._historyController.tabs.map(
                            (item) => HistoryPage(type: item.type),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      titleSpacing: 0,
      centerTitle: false,
      title: Hero(
        tag: 'media_title_观看记录',
        createRectTween: (Rect? begin, Rect? end) {
          return RectTween(begin: begin, end: end);
        },
        child: Material(
          color: Colors.transparent,
          child: Text(
            '观看记录',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: '搜索',
          onPressed: () => Get.toNamed('/historySearch'),
          icon: const Icon(Icons.search_outlined),
        ),
        PopupMenuButton<String>(
          onSelected: (String type) {
            switch (type) {
              case 'pause':
                currCtr().onPauseHistory(context);
                break;
              case 'clear':
                currCtr().onClearHistory(context);
                break;
              case 'del':
                currCtr().onDelHistory();
                break;
              case 'multiple':
                currCtr().enableMultiple.value = true;
                setState(() {});
                break;
              default:
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'pause',
              child: Obx(
                () => Text(!currCtr().pauseStatus.value ? '暂停观看记录' : '恢复观看记录'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'clear',
              child: Text('清空观看记录'),
            ),
            const PopupMenuItem<String>(
              value: 'del',
              child: Text('删除已看记录'),
            ),
            const PopupMenuItem<String>(
              value: 'multiple',
              child: Text('多选删除'),
            ),
          ],
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  AppBar _buildMultiSelectAppBar() {
    return AppBar(
      titleSpacing: 0,
      centerTitle: false,
      leading: IconButton(
        tooltip: '取消',
        onPressed: () {
          currCtr().enableMultiple.value = false;
          for (var item in currCtr().historyList) {
            item.checked = false;
          }
          currCtr().checkedCount.value = 0;
          setState(() {});
        },
        icon: const Icon(Icons.close_outlined),
      ),
      title: Obx(
        () => Text(
          '已选择${currCtr().checkedCount.value}项',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            for (var item in currCtr().historyList) {
              item.checked = true;
            }
            currCtr().checkedCount.value = currCtr().historyList.length;
            currCtr().historyList.refresh();
          },
          child: const Text('全选'),
        ),
        TextButton(
          onPressed: () => currCtr().onDelCheckedHistory(context),
          child: Text(
            '删除',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      displacement: 10.0,
      edgeOffset: 10.0,
      onRefresh: () async {
        await _historyController.onRefresh();
        return;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _historyController.scrollController,
        slivers: [
          FutureBuilder(
            future: _futureBuilderFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.data == null) {
                  return const SliverToBoxAdapter(child: SizedBox());
                }
                Map data = snapshot.data;
                if (data['status']) {
                  return Obx(
                    () => _historyController.historyList.isNotEmpty
                        ? SliverGrid(
                            gridDelegate: SliverGridDelegateWithExtentAndRatio(
                                mainAxisSpacing: StyleString.cardSpace,
                                crossAxisSpacing: StyleString.safeSpace,
                                maxCrossAxisExtent: Grid.maxRowWidth * 2,
                                childAspectRatio: StyleString.aspectRatio * 2.4,
                                mainAxisExtent: 0),
                            delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              return AnimationConfiguration.staggeredGrid(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                columnCount: 2,
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: HistoryItem(
                                      videoItem:
                                          _historyController.historyList[index],
                                      ctr: _historyController,
                                      onChoose: () => onChoose(index),
                                      onUpdateMultiple: () =>
                                          onUpdateMultiple(),
                                    ),
                                  ),
                                ),
                              );
                            },
                                childCount:
                                    _historyController.historyList.length),
                          )
                        : _historyController.isLoadingMore.value
                            ? const SliverToBoxAdapter(
                                child: Center(child: Text('加载中')),
                              )
                            : const NoData(),
                  );
                } else {
                  return HttpError(
                    errMsg: data['msg'],
                    fn: () => setState(() {}),
                  );
                }
              } else {
                // 骨架屏
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithExtentAndRatio(
                      mainAxisSpacing: StyleString.cardSpace,
                      crossAxisSpacing: StyleString.safeSpace,
                      maxCrossAxisExtent: Grid.maxRowWidth * 2,
                      childAspectRatio: StyleString.aspectRatio * 2.4,
                      mainAxisExtent: 0),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return const VideoCardHSkeleton();
                  }, childCount: 10),
                );
              }
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 10,
            ),
          )
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.type != null;
}

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({
    required this.child1,
    required this.child2,
    required this.visible,
    super.key,
  });

  final PreferredSizeWidget child1;
  final PreferredSizeWidget child2;
  final bool visible;
  @override
  Size get preferredSize => child1.preferredSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: !visible ? child1 : child2,
    );
  }
}
