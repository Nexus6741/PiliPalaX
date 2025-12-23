import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/live/live_area_list/area_item.dart';

import 'controller.dart';
import 'child_view.dart';
import 'child_controller.dart';

class LiveAreaDetailPage extends StatefulWidget {
  const LiveAreaDetailPage({super.key});

  @override
  State<LiveAreaDetailPage> createState() => _LiveAreaDetailPageState();
}

class _LiveAreaDetailPageState extends State<LiveAreaDetailPage> {
  late final dynamic areaId;
  late final dynamic parentAreaId;
  late final String areaName;
  late final LiveAreaDetailController _controller;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments ?? {};
    areaId = args['areaId'];
    parentAreaId = args['parentAreaId'];
    areaName = args['areaName'] ?? '分区详情';

    // print('=== LiveAreaDetailPage initState ===');
    // print('Received areaId: $areaId (type: ${areaId.runtimeType})');
    // print(
    //     'Received parentAreaId: $parentAreaId (type: ${parentAreaId.runtimeType})');
    // print('Received areaName: $areaName');

    _controller = Get.put(
      LiveAreaDetailController(areaId, parentAreaId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(areaName),
      ),
      body: Padding(
        padding: EdgeInsets.only(left: padding.left, right: padding.right),
        child: Obx(
          () =>
              _buildBody(theme, padding.bottom, _controller.loadingState.value),
        ),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    double bottom,
    LoadingState<List<AreaItem>?> loadingState,
  ) {
    if (loadingState is Loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (loadingState is Success) {
      final response = (loadingState as Success<List<AreaItem>?>).response;
      if (response != null && response.isNotEmpty) {
        // 确保 initialIndex 在有效范围内
        final safeInitialIndex =
            _controller.initialIndex.clamp(0, response.length - 1);
        // print('=== Building DefaultTabController ===');
        // print('initialIndex: $safeInitialIndex');
        // print('tabs count: ${response.length}');

        return DefaultTabController(
          initialIndex: safeInitialIndex,
          length: response.length,
          child: Builder(
            builder: (context) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          dividerHeight: 0,
                          dividerColor: Colors.transparent,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          tabs: response
                              .map((e) => Tab(text: e.name ?? ''))
                              .toList(),
                          onTap: (index) {
                            try {
                              if (!DefaultTabController.of(context)
                                  .indexIsChanging) {
                                final item = response[index];
                                Get.find<LiveAreaChildController>(
                                  tag: '${item.id}${item.parentId}',
                                ).animateToTop();
                              }
                            } catch (_) {}
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () =>
                            _showTags(context, theme, bottom, response),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: TabBarView(
                      children: response
                          .map(
                            (e) => LiveAreaChildPage(
                              areaId: e.id,
                              parentAreaId: e.parentId,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      } else {
        // 没有子分区时直接显示列表
        return LiveAreaChildPage(
          areaId: areaId,
          parentAreaId: parentAreaId,
        );
      }
    } else if (loadingState is Error) {
      // 错误时直接显示列表
      return LiveAreaChildPage(
        areaId: areaId,
        parentAreaId: parentAreaId,
      );
    }
    return const SizedBox();
  }

  Widget _tagItem({
    required ThemeData theme,
    required AreaItem item,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: NetworkImgLayer(
              width: 45,
              height: 45,
              src: item.pic ?? '',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showTags(
    BuildContext context,
    ThemeData theme,
    double bottom,
    List<AreaItem> list,
  ) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          minChildSize: 0,
          maxChildSize: 1,
          initialChildSize: 1,
          snap: true,
          expand: false,
          snapSizes: const [1],
          builder: (_, scrollController) {
            return Column(
              children: [
                AppBar(
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  title: Text(areaName),
                  actions: [
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.clear),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      top: 12,
                      left: 12,
                      right: 12,
                      bottom: bottom + 100,
                    ),
                    itemCount: list.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 100,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 80,
                    ),
                    itemBuilder: (_, index) {
                      return _tagItem(
                        theme: theme,
                        item: list[index],
                        onTap: () {
                          Get.back();
                          DefaultTabController.of(context).index = index;
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
