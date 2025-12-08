import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/pgc/pgc_index_condition/data.dart';
import 'package:PiliPalaX/models/pgc/pgc_index_condition/sort.dart';
import 'package:PiliPalaX/models/pgc/pgc_index_condition/value.dart';
import 'package:PiliPalaX/models/pgc/pgc_index_result/list.dart';
import 'package:PiliPalaX/utils/grid.dart';

import 'controller.dart';
import '../pgc/widgets/pgc_card_v.dart';

class PgcIndexPage extends StatefulWidget {
  const PgcIndexPage({super.key, this.indexType});

  final int? indexType;

  @override
  State<PgcIndexPage> createState() => _PgcIndexPageState();
}

class _PgcIndexPageState extends State<PgcIndexPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final int? indexType;
  late PgcIndexController? _mainController;
  late TabController? _tabController;
  final Map<int, PgcIndexController> _tabControllers = {};

  // 影视分类标签 (type对应seasonType: 2=电影, 5=电视剧, 3=纪录片, 7=综艺, 102=全部影视)
  final List<Map<String, dynamic>> _mediaTabs = [
    {'label': '全部', 'type': 102},
    {'label': '电影', 'type': 2},
    {'label': '电视剧', 'type': 5},
    {'label': '纪录片', 'type': 3},
    {'label': '综艺', 'type': 7},
  ];

  @override
  void initState() {
    super.initState();
    // 优先使用widget的indexType，否则从arguments获取
    indexType = widget.indexType ?? Get.arguments?['indexType'];

    // 如果是影视索引（indexType=102或其他），初始化TabController
    if (indexType != null) {
      _tabController = TabController(length: _mediaTabs.length, vsync: this);
    } else {
      // 番剧索引，使用单一controller
      _mainController = Get.put(
        PgcIndexController(indexType: indexType),
        tag: '$indexType',
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    // 清理所有tab的controller
    for (var controller in _tabControllers.values) {
      Get.delete<PgcIndexController>(tag: controller.tag);
    }
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ThemeData theme = Theme.of(context);

    // 根据indexType显示不同的标题
    String title = '索引';
    if (indexType == null) {
      title = '番剧索引';
    } else if (indexType == 102) {
      title = '影视索引';
    }

    // 如果是影视索引，使用TabBarView + TabBar（比PageView更丝滑）
    if (indexType != null && _tabController != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _mediaTabs.map((tab) => Tab(text: tab['label'])).toList(),
            indicatorSize: TabBarIndicatorSize.label,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: List.generate(
            _mediaTabs.length,
            (index) => _buildMediaPage(theme, index),
          ),
        ),
      );
    }

    // 番剧索引，不使用PageView
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _mainController!.onRefresh,
        child: CustomScrollView(
          controller: _mainController!.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 筛选条件
            _buildFilterWidget(theme, _mainController!),
            // 内容列表
            _buildContentList(theme, _mainController!),
          ],
        ),
      ),
    );
  }

  /// 获取或创建指定tab的controller
  PgcIndexController _getTabController(int tabIndex) {
    if (!_tabControllers.containsKey(tabIndex)) {
      final mediaType = _mediaTabs[tabIndex]['type'];
      final controller = PgcIndexController(indexType: mediaType);
      controller.tag = 'pgc_index_$tabIndex';
      Get.put(controller, tag: controller.tag);
      _tabControllers[tabIndex] = controller;
    }
    return _tabControllers[tabIndex]!;
  }

  /// 构建影视分类页面
  Widget _buildMediaPage(ThemeData theme, int index) {
    final controller = _getTabController(index);
    return RefreshIndicator(
      onRefresh: controller.onRefresh,
      child: CustomScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 筛选条件
          _buildFilterWidget(theme, controller),
          // 内容列表
          _buildContentList(theme, controller),
        ],
      ),
    );
  }

  /// 构建筛选条件
  Widget _buildFilterWidget(ThemeData theme, PgcIndexController controller) {
    return SliverToBoxAdapter(
      child: Obx(
        () {
          final conditionState = controller.conditionState.value;
          if (conditionState is Loading) {
            return const SizedBox.shrink();
          } else if (conditionState is Success<PgcIndexConditionData?>) {
            final data = conditionState.response;
            if (data == null) {
              return const SizedBox.shrink();
            }

            // 计算总行数
            int count = (data.order?.isNotEmpty == true ? 1 : 0) +
                (data.filter?.length ?? 0);
            if (count == 0) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: AnimatedSize(
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                duration: const Duration(milliseconds: 200),
                child: count > 5
                    ? Obx(
                        () => _buildSortsWidget(theme, count, data, controller))
                    : _buildSortsWidget(theme, count, data, controller),
              ),
            );
          } else if (conditionState is Error) {
            return const SizedBox.shrink();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// 构建筛选条件组合
  Widget _buildSortsWidget(
    ThemeData theme,
    int count,
    PgcIndexConditionData data,
    PgcIndexController controller,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(
          count > 5
              ? controller.isExpand.value
                  ? count
                  : (count + 1) ~/ 2
              : count,
          (index) {
            List<dynamic>? items;
            if (data.order?.isNotEmpty == true) {
              items = index == 0 ? data.order : data.filter?[index - 1].values;
            } else {
              items = data.filter?[index].values;
            }

            if (items?.isNotEmpty != true) return const SizedBox.shrink();

            return Padding(
              padding:
                  index == 0 ? EdgeInsets.zero : const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: items!.map((item) {
                  return _buildSortChip(theme, index, data, item, controller);
                }).toList(),
              ),
            );
          },
        ),
        if (count > 5) ...[
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.toggleExpand(),
            child: Container(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.isExpand.value ? '收起' : '展开',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  Icon(
                    controller.isExpand.value
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建单个筛选芯片
  Widget _buildSortChip(
    ThemeData theme,
    int index,
    PgcIndexConditionData data,
    dynamic item,
    PgcIndexController controller,
  ) {
    // 排序选项（order）- 只能选一个，点击切换排序方向
    if (item is PgcConditionOrder) {
      final label = item.name ?? '';
      final field = item.field;
      if (label.isEmpty || field == null) return const SizedBox.shrink();

      return Obx(() {
        final isCurr = controller.indexParams['order'] == field;
        // 获取当前排序方向：0=降序, 1=升序
        final currentSort = controller.indexParams['sort'] ?? 0;

        return GestureDetector(
          onTap: () {
            if (isCurr) {
              // 已选中，切换排序方向
              controller.updateOrderSort(field, currentSort == 0 ? 1 : 0);
            } else {
              // 未选中，选择此排序，默认降序
              controller.updateOrderSort(field, 0);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCurr
                  ? theme.colorScheme.secondaryContainer
                  : Colors.transparent,
              border: Border.all(
                color: isCurr
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isCurr
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                if (isCurr) ...[
                  const SizedBox(width: 2),
                  Icon(
                    currentSort == 0
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    size: 14,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ],
              ],
            ),
          ),
        );
      });
    }

    // 筛选选项（filter）- 每个分类只能选一个
    if (item is PgcConditionValue) {
      final label = item.name ?? '';
      final value = item.keyword;
      // 获取filter的key
      final hasOrder = data.order?.isNotEmpty == true;
      final filterIndex = hasOrder ? index - 1 : index;
      if (filterIndex < 0 || filterIndex >= (data.filter?.length ?? 0)) {
        return const SizedBox.shrink();
      }
      final key = data.filter![filterIndex].field;
      if (label.isEmpty || key == null) return const SizedBox.shrink();

      return Obx(() {
        final isCurr = controller.indexParams[key] == value;
        return GestureDetector(
          onTap: () {
            controller.updateIndexParams(key, value);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCurr
                  ? theme.colorScheme.secondaryContainer
                  : Colors.transparent,
              border: Border.all(
                color: isCurr
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isCurr
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        );
      });
    }

    return const SizedBox.shrink();
  }

  /// 构建内容列表
  Widget _buildContentList(ThemeData theme, PgcIndexController controller) {
    final padding = MediaQuery.viewPaddingOf(context);
    return SliverPadding(
      padding: EdgeInsets.only(
        left: StyleString.safeSpace,
        right: StyleString.safeSpace,
        top: 12,
        bottom: padding.bottom + 100,
      ),
      sliver: Obx(
        () => _buildListBody(controller.loadingState.value, controller),
      ),
    );
  }

  /// 构建列表内容
  Widget _buildListBody(LoadingState<List<PgcIndexItem>?> loadingState,
      PgcIndexController controller) {
    if (loadingState is Loading) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (loadingState is Success<List<PgcIndexItem>?>) {
      final response = loadingState.response;
      if (response?.isNotEmpty == true) {
        final gridDelegate = SliverGridDelegateWithExtentAndRatio(
          mainAxisSpacing: StyleString.cardSpace,
          crossAxisSpacing: StyleString.cardSpace,
          maxCrossAxisExtent: Grid.maxRowWidth * 0.6,
          childAspectRatio: 0.75,
          mainAxisExtent: MediaQuery.textScalerOf(context).scale(50),
        );

        return SliverGrid(
          gridDelegate: gridDelegate,
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == response.length - 1) {
                controller.onLoadMore();
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
            fn: controller.onReload,
          ),
        );
      }
    } else if (loadingState is Error) {
      final error = loadingState as Error;
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: error.errMsg,
          fn: controller.onReload,
        ),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}
