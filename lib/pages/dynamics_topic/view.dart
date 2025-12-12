import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/pages/dynamics/widgets/dynamic_panel.dart';
import 'package:PiliPalaX/pages/dynamics_create/simple_view_fixed.dart';
import 'package:PiliPalaX/pages/dynamics_topic/controller.dart';
import 'package:PiliPalaX/utils/feed_back.dart';
import 'package:PiliPalaX/utils/grid.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:PiliPalaX/utils/utils.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

class DynamicsTopicPage extends StatefulWidget {
  const DynamicsTopicPage({super.key});

  @override
  State<DynamicsTopicPage> createState() => _DynamicsTopicPageState();
}

class _DynamicsTopicPageState extends State<DynamicsTopicPage> {
  late final DynamicsTopicController _controller =
      Get.put(DynamicsTopicController(), tag: Utils.makeHeroTag('topic'));

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdgeInsets padding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_controller.isLogin) {
            Get.to(
              () => SimpleDynamicCreatePage(
                topicId: int.parse(_controller.topicId),
                topicName: _controller.topicName,
              ),
              preventDuplicates: false,
            );
          } else {
            SmartDialog.showToast('账号未登录');
          }
        },
        icon: const Icon(Icons.tag, size: 20),
        label: const Text('参与话题'),
      ),
      body: RefreshIndicator(
        onRefresh: _controller.onRefresh,
        child: CustomScrollView(
          controller: _controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            Obx(() => _buildAppBar(theme, padding)),
            Obx(() {
              final allSortBy =
                  _controller.topicSortByConf.value?.allSortBy ?? [];
              if (allSortBy.isNotEmpty) {
                return SliverPersistentHeader(
                  pinned: true,
                  delegate: _SortBarDelegate(
                    height: 50,
                    theme: theme,
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.only(
                        left: 12 + padding.left,
                        bottom: 6,
                        top: 6,
                      ),
                      alignment: Alignment.centerLeft,
                      child: ToggleButtons(
                        fillColor: theme.colorScheme.secondaryContainer,
                        selectedColor: theme.colorScheme.onSecondaryContainer,
                        constraints: const BoxConstraints(
                          minWidth: 54,
                          minHeight: 32,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(25),
                        ),
                        onPressed: (index) {
                          _controller.onSort(allSortBy[index].sortBy!);
                        },
                        isSelected: allSortBy.map((e) {
                          return e.sortBy == _controller.sortBy.value;
                        }).toList(),
                        children: allSortBy.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              e.sortName!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter();
            }),
            SliverPadding(
              padding: EdgeInsets.only(
                left: padding.left,
                right: padding.right,
                bottom: padding.bottom + 100,
              ),
              sliver: Obx(() => _buildBody()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, EdgeInsets padding) {
    if (_controller.isTopLoading.value) {
      return const SliverAppBar(
        pinned: true,
        expandedHeight: 200,
      );
    }

    if (_controller.topErrorMsg.value.isNotEmpty) {
      return SliverAppBar(
        pinned: true,
        title: Text(_controller.topicName),
      );
    }

    final topDetails = _controller.topDetails.value;
    if (topDetails == null || topDetails.topicItem == null) {
      return SliverAppBar(
        pinned: true,
        title: Text(_controller.topicName),
      );
    }

    final topicItem = topDetails.topicItem!;
    final topicCreator = topDetails.topicCreator;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 220,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/topic-header-bg.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                theme.colorScheme.surface.withValues(alpha: 0.3),
                BlendMode.darken,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: padding.top + kToolbarHeight,
            left: 12 + padding.left,
            right: 12 + padding.right,
            bottom: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (topicCreator != null)
                GestureDetector(
                  onTap: () {
                    Get.toNamed('/member?mid=${topicCreator.uid}');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NetworkImgLayer(
                        width: 28,
                        height: 28,
                        src: topicCreator.face ?? '',
                        type: 'avatar',
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          topicCreator.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        ' 发起',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                topicItem.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              if (topicItem.description?.isNotEmpty == true)
                Text(
                  topicItem.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${Utils.numFormat(topicItem.view ?? 0)}浏览 · ${Utils.numFormat(topicItem.discuss ?? 0)}讨论',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  Obx(() {
                    final isLike = _controller.isLike.value ?? false;
                    return OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          width: 1,
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        foregroundColor: isLike
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        feedBack();
                        _controller.onLike();
                      },
                      icon: Icon(
                        isLike ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 16,
                      ),
                      label: Text(
                        Utils.numFormat(topicItem.like),
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }),
                  const SizedBox(width: 10),
                  Obx(() {
                    final isFav = _controller.isFav.value ?? false;
                    return OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          width: 1,
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        foregroundColor: isFav
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        feedBack();
                        _controller.onFav();
                      },
                      icon: Icon(
                        isFav ? Icons.star : Icons.star_outline,
                        size: 16,
                      ),
                      label: Text(
                        Utils.numFormat(topicItem.fav),
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(
              text:
                  '${_controller.topicName} https://m.bilibili.com/topic-detail?topic_id=${_controller.topicId}',
            ));
            SmartDialog.showToast('已复制分享链接');
          },
          icon: const Icon(Icons.share),
        ),
        PopupMenuButton(
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                onTap: () {
                  feedBack();
                  _controller.onFav();
                },
                child: Obx(() {
                  final isFav = _controller.isFav.value ?? false;
                  return Text(isFav ? '取消收藏' : '收藏');
                }),
              ),
            ];
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading.value) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_controller.errorMsg.value.isNotEmpty) {
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: _controller.errorMsg.value,
          fn: _controller.onReload,
        ),
      );
    }

    if (_controller.dynamicsList.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('暂无动态'),
          ),
        ),
      );
    }

    // 检查是否启用瀑布流布局（横屏双列）
    final bool enableWaterfallFlow = GStorage.setting
        .get(SettingBoxKey.dynamicsWaterfallFlow, defaultValue: true);

    // 获取屏幕方向
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    // 在横屏且启用瀑布流时使用双列布局
    if (isLandscape && enableWaterfallFlow) {
      return _buildWaterfallLayout();
    } else {
      return _buildListLayout();
    }
  }

  Widget _buildListLayout() {
    return SliverList.builder(
      itemCount:
          _controller.dynamicsList.length + (_controller.isEnd.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _controller.dynamicsList.length) {
          // 只在结束时显示"没有更多了"
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('没有更多了'),
            ),
          );
        }

        final item = _controller.dynamicsList[index];
        if (item.dynamicCardItem != null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DynamicPanel(item: item.dynamicCardItem!),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWaterfallLayout() {
    final List<Widget> children = [];

    // 添加动态卡片
    for (var item in _controller.dynamicsList) {
      if (item.dynamicCardItem != null) {
        children.add(DynamicPanel(item: item.dynamicCardItem!));
      }
    }

    // 只在结束时添加"没有更多了"提示
    if (_controller.isEnd.value) {
      children.add(const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('没有更多了'),
        ),
      ));
    }

    return SliverWaterfallFlow.extent(
      maxCrossAxisExtent: Grid.maxRowWidth * 2,
      crossAxisSpacing: StyleString.cardSpace / 2,
      mainAxisSpacing: StyleString.cardSpace / 2,
      lastChildLayoutTypeBuilder: (index) =>
          index == children.length - 1 && _controller.isEnd.value
              ? LastChildLayoutType.foot
              : LastChildLayoutType.none,
      children: children,
    );
  }
}

class _SortBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  final ThemeData theme;

  _SortBarDelegate({
    required this.height,
    required this.child,
    required this.theme,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: theme.colorScheme.surface,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SortBarDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}
