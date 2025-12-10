import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/animated_dialog.dart';
import 'package:PiliPalaX/common/widgets/overlay_pop.dart';
import 'package:PiliPalaX/common/skeleton/video_card_h.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/common/widgets/video_card_h.dart';
// import 'package:PiliPalaX/pages/home/index.dart';
// import 'package:PiliPalaX/pages/main/index.dart';
import 'package:PiliPalaX/pages/rank/zone/index.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../utils/grid.dart';

class ZonePage extends StatefulWidget {
  const ZonePage({super.key, this.rid, this.tid})
      : assert(
            rid != null || tid != null, 'Either rid or tid must be provided');

  final int? rid;
  final int? tid;

  @override
  State<ZonePage> createState() => _ZonePageState();
}

class _ZonePageState extends State<ZonePage>
    with AutomaticKeepAliveClientMixin {
  late ZoneController _zoneController;
  Future? _futureBuilderFuture;
  late ScrollController scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _zoneController =
        Get.put(ZoneController(), tag: (widget.rid ?? widget.tid).toString());
    _futureBuilderFuture =
        _zoneController.queryRankFeed('init', widget.rid, widget.tid);
    scrollController = _zoneController.scrollController;
    // 暂时禁用滚动隐藏搜索栏功能
    // StreamController<bool> mainStream =
    //     Get.find<MainController>().bottomBarStream;
    // HomeController homeController = Get.find<HomeController>();
    scrollController.addListener(
      () {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          if (!_zoneController.isLoadingMore) {
            _zoneController.isLoadingMore = true;
            _zoneController.onLoad();
          }
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
      onRefresh: () async {
        return await _zoneController.onRefresh();
      },
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          FutureBuilder(
            future: _futureBuilderFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                Map data = snapshot.data as Map;
                if (data['status']) {
                  return Obx(
                    () => SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          StyleString.cardSpace, StyleString.safeSpace, 0, 0),
                      sliver: AnimationLimiter(
                        child: SliverGrid(
                          gridDelegate: SliverGridDelegateWithExtentAndRatio(
                              mainAxisSpacing: StyleString.safeSpace,
                              crossAxisSpacing: StyleString.safeSpace,
                              maxCrossAxisExtent: Grid.maxRowWidth * 2,
                              childAspectRatio: StyleString.aspectRatio * 2.4,
                              mainAxisExtent: 13),
                          delegate:
                              SliverChildBuilderDelegate((context, index) {
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: VideoCardH(
                                    videoItem: _zoneController.videoList[index],
                                    showPubdate: true,
                                    longPress: () {
                                      _zoneController.popupDialog.add(
                                          _createPopupDialog(_zoneController
                                              .videoList[index]));
                                      Overlay.of(context).insert(
                                          _zoneController.popupDialog.last!);
                                    },
                                    longPressEnd: _removePopupDialog,
                                  ),
                                ),
                              ),
                            );
                          }, childCount: _zoneController.videoList.length),
                        ),
                      ),
                    ),
                  );
                } else {
                  return SliverToBoxAdapter(
                    child: HttpError(
                      errMsg: data['msg'],
                      fn: () {
                        setState(() {
                          _futureBuilderFuture = _zoneController.queryRankFeed(
                              'init', widget.rid, widget.tid);
                        });
                      },
                    ),
                  );
                }
              } else {
                // 骨架屏
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      StyleString.cardSpace, StyleString.safeSpace, 0, 0),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithExtentAndRatio(
                        mainAxisSpacing: StyleString.safeSpace,
                        crossAxisSpacing: StyleString.safeSpace,
                        maxCrossAxisExtent: Grid.maxRowWidth * 2,
                        childAspectRatio: StyleString.aspectRatio * 2.4,
                        mainAxisExtent: 0),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return const VideoCardHSkeleton();
                    }, childCount: 10),
                  ),
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

  void _removePopupDialog() {
    _zoneController.popupDialog.last?.remove();
    _zoneController.popupDialog.removeLast();
  }

  OverlayEntry _createPopupDialog(videoItem) {
    return OverlayEntry(
      builder: (context) => AnimatedDialog(
        closeFn: _removePopupDialog,
        child: OverlayPop(
          videoItem: videoItem,
          closeFn: _removePopupDialog,
        ),
      ),
    );
  }
}
