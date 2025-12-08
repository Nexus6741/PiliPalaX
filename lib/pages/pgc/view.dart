import 'dart:async';

import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/pgc/fav_pgc/list.dart';
import 'package:PiliPalaX/models/pgc/pgc_index_result/list.dart';
import 'package:PiliPalaX/pages/home/index.dart';
import 'package:PiliPalaX/pages/main/index.dart';

import '../../utils/grid.dart';
import 'controller.dart';
import 'widgets/pgc_card_v.dart';

class PgcPage extends StatefulWidget {
  const PgcPage({super.key, required this.tabType});

  final PgcTabType tabType;

  @override
  State<PgcPage> createState() => _PgcPageState();
}

class _PgcPageState extends State<PgcPage> with AutomaticKeepAliveClientMixin {
  late final PgcController _pgcController = Get.put(
    PgcController(tabType: widget.tabType),
    tag: widget.tabType.name,
  );
  late ScrollController scrollController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scrollController = _pgcController.scrollController;
    StreamController<bool> mainStream =
        Get.find<MainController>().bottomBarStream;
    StreamController<bool> searchBarStream =
        Get.find<HomeController>().searchBarStream;

    scrollController.addListener(
      () async {
        // 加载更多
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          EasyThrottle.throttle('pgc-throttler', const Duration(seconds: 1),
              () {
            _pgcController.onLoadMore();
          });
        }

        // 控制底部栏和搜索栏显示
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

    return RefreshIndicator(
      onRefresh: _pgcController.onRefresh,
      child: CustomScrollView(
        controller: _pgcController.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 追剧区域
          _buildFollow(theme),
          // 推荐区域
          ..._buildRcmd(theme),
        ],
      ),
    );
  }

  /// 构建追剧区域
  Widget _buildFollow(ThemeData theme) {
    return SliverToBoxAdapter(
      child: _pgcController.isLogin
          ? Column(
              children: [
                _buildFollowTitle(theme),
                SizedBox(
                  height: Grid.maxRowWidth * 0.8 +
                      MediaQuery.textScalerOf(context).scale(50),
                  child: Obx(
                    () => _buildFollowBody(_pgcController.followState.value),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  /// 构建追剧标题
  Widget _buildFollowTitle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(
        top: StyleString.safeSpace,
        left: 16,
        right: 10,
      ),
      child: Row(
        children: [
          Obx(
            () => Text(
              '最近${widget.tabType == PgcTabType.bangumi ? '追番' : '追剧'}${_pgcController.followCount.value == -1 ? '' : ' ${_pgcController.followCount.value}'}',
              style: theme.textTheme.titleMedium,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: '刷新',
            onPressed: () {
              _pgcController.followPage = 1;
              _pgcController.followEnd = false;
              _pgcController.queryPgcFollow();
            },
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
    );
  }

  /// 构建追剧内容
  Widget _buildFollowBody(LoadingState<List<FavPgcItemModel>?> loadingState) {
    if (loadingState is Loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (loadingState is Success<List<FavPgcItemModel>?>) {
      final response = loadingState.response;
      if (response?.isNotEmpty == true) {
        return ListView.builder(
          controller: _pgcController.followController,
          scrollDirection: Axis.horizontal,
          itemCount: response!.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            if (index == response.length - 1) {
              _pgcController.queryPgcFollow(false);
            }
            return Container(
              width: Grid.maxRowWidth / 2,
              margin: EdgeInsets.only(
                left: StyleString.safeSpace,
                right: index == response.length - 1 ? StyleString.safeSpace : 0,
              ),
              child: PgcCardV(pgcItem: response[index]),
            );
          },
        );
      } else {
        return Center(
          child: Text(
            '还没有${widget.tabType == PgcTabType.bangumi ? '追番' : '追剧'}',
          ),
        );
      }
    } else if (loadingState is Error) {
      final error = loadingState as Error;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Text(error.errMsg ?? '', textAlign: TextAlign.center),
      );
    }
    return const SizedBox.shrink();
  }

  /// 构建推荐区域
  List<Widget> _buildRcmd(ThemeData theme) {
    return [
      _buildRcmdTitle(theme),
      SliverPadding(
        padding: const EdgeInsets.only(
          left: StyleString.safeSpace,
          right: StyleString.safeSpace,
          bottom: 100,
        ),
        sliver: Obx(
          () => _buildRcmdBody(_pgcController.loadingState.value),
        ),
      ),
    ];
  }

  /// 构建推荐标题
  Widget _buildRcmdTitle(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 10,
          left: 16,
          right: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('推荐', style: theme.textTheme.titleMedium),
            TextButton.icon(
              onPressed: () {
                // 影视索引：indexType=102表示全部影视内容
                Get.toNamed('/pgcIndex', arguments: {'indexType': 102});
              },
              icon: const Icon(Icons.grid_view, size: 18),
              label: const Text('索引'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建推荐内容
  Widget _buildRcmdBody(LoadingState<List<PgcIndexItem>?> loadingState) {
    if (loadingState is Loading) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (loadingState is Success<List<PgcIndexItem>?>) {
      final response = loadingState.response;
      if (response?.isNotEmpty == true) {
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithExtentAndRatio(
            mainAxisSpacing: StyleString.cardSpace,
            crossAxisSpacing: StyleString.cardSpace,
            maxCrossAxisExtent: Grid.maxRowWidth / 3 * 2,
            childAspectRatio: 0.65,
            mainAxisExtent: MediaQuery.textScalerOf(context).scale(60),
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == response.length - 1) {
                _pgcController.onLoadMore();
              }
              return PgcCardV(item: response[index]);
            },
            childCount: response!.length,
          ),
        );
      } else {
        return SliverToBoxAdapter(
          child: HttpError(
            errMsg: '暂无数据',
            fn: _pgcController.onReload,
          ),
        );
      }
    } else if (loadingState is Error) {
      final error = loadingState as Error;
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: error.errMsg,
          fn: _pgcController.onReload,
        ),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}
