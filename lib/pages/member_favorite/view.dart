import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/models/space_fav/space_fav_data.dart';
import 'package:PiliPalaX/pages/member_favorite/controller.dart';
import 'package:PiliPalaX/pages/member_favorite/widgets/fav_item.dart';
import 'package:PiliPalaX/utils/grid.dart';
import 'package:PiliPalaX/utils/storage.dart';

class MemberFavoritePage extends StatefulWidget {
  const MemberFavoritePage({
    super.key,
    required this.mid,
    this.heroTag,
  });

  final int mid;
  final String? heroTag;

  @override
  State<MemberFavoritePage> createState() => _MemberFavoritePageState();
}

class _MemberFavoritePageState extends State<MemberFavoritePage>
    with AutomaticKeepAliveClientMixin {
  late MemberFavoriteController _controller;
  late bool enableGradientBg;
  Box setting = GStorage.setting;

  @override
  bool get wantKeepAlive => true;

  // 网格代理
  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: 2,
    maxCrossAxisExtent: Grid.maxRowWidth * 2,
    childAspectRatio: StyleString.aspectRatio * 2.4,
    mainAxisExtent: 0,
  );

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      MemberFavoriteController(mid: widget.mid),
      tag: widget.heroTag ?? 'member_favorite_${widget.mid}',
    );
    enableGradientBg =
        setting.get(SettingBoxKey.enableGradientBg, defaultValue: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _controller.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
            ),
            sliver: Obx(() => _buildBody(theme)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_controller.isLoading.value) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_controller.errorMsg.value.isNotEmpty) {
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: _controller.errorMsg.value,
          fn: _controller.loadData,
        ),
      );
    }

    final favData = _controller.favState.value;
    final subData = _controller.subState.value;

    // 检查是否有数据
    final hasFavData = favData.mediaListResponse?.list?.isNotEmpty ?? false;
    final hasSubData = subData.mediaListResponse?.list?.isNotEmpty ?? false;

    if (!hasFavData && !hasSubData) {
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: '暂无收藏',
          fn: _controller.loadData,
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        // 创建的收藏夹
        if (hasFavData)
          _buildSection(
            theme,
            data: _controller.favState,
            isExpanded: _controller.favExpanded,
            isEnd: _controller.favEnd,
            onToggle: _controller.toggleFavExpanded,
            onLoadMore: _controller.loadMoreFav,
          ),
        // 订阅的收藏夹（仅当前用户可见）
        if (hasSubData && _controller.isOwner)
          _buildSection(
            theme,
            data: _controller.subState,
            isExpanded: _controller.subExpanded,
            isEnd: _controller.subEnd,
            onToggle: _controller.toggleSubExpanded,
            onLoadMore: _controller.loadMoreSub,
          ),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required Rx<SpaceFavData> data,
    required RxBool isExpanded,
    required RxBool isEnd,
    required VoidCallback onToggle,
    required Future<void> Function() onLoadMore,
  }) {
    return SliverMainAxisGroup(
      slivers: [
        // 标题栏
        SliverToBoxAdapter(
          child: Material(
            color: enableGradientBg
                ? Colors.transparent
                : theme.colorScheme.surface,
            child: InkWell(
              onTap: onToggle,
              child: Container(
                height: 45,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 12),
                child: Obx(() => Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              isExpanded.value
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          TextSpan(
                            text: ' ${data.value.name ?? "收藏夹"}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          TextSpan(
                            text:
                                ' ${data.value.mediaListResponse?.count ?? 0}',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )),
              ),
            ),
          ),
        ),
        // 列表内容
        Obx(() {
          final list = data.value.mediaListResponse?.list;
          if (!isExpanded.value) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          if (list != null && list.isNotEmpty) {
            return SliverGrid.builder(
              gridDelegate: gridDelegate,
              itemCount: list.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 98,
                  child: MemberFavItem(item: list[index]),
                );
              },
            );
          }
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }),
        // 加载更多按钮
        Obx(() {
          if (isEnd.value || !isExpanded.value) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: InkWell(
                onTap: onLoadMore,
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '查看更多内容',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
