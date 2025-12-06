import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/live/live_area_list/area_item.dart';
import 'package:PiliPalaX/models/live/live_area_list/area_list.dart';

import 'controller.dart';

class LiveAreaPage extends StatefulWidget {
  const LiveAreaPage({super.key});

  @override
  State<LiveAreaPage> createState() => _LiveAreaPageState();
}

class _LiveAreaPageState extends State<LiveAreaPage> {
  final _controller = Get.put(LiveAreaController());

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('全部标签'),
      ),
      body: Padding(
        padding: EdgeInsets.only(left: padding.left, right: padding.right),
        child: Obx(
          () => _buildBody(
            theme,
            padding.bottom,
            _controller.loadingState.value,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    double bottom,
    LoadingState<List<AreaList>?> loadingState,
  ) {
    if (loadingState is Loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (loadingState is Success) {
      final response = (loadingState as Success<List<AreaList>?>).response;
      if (response != null && response.isNotEmpty) {
        return DefaultTabController(
          length: response.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: response.map((e) => Tab(text: e.name)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: response
                      .map((e) => _buildAreaGrid(theme, e, bottom))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      } else {
        return HttpError(
          errMsg: '暂无数据',
          fn: _controller.onReload,
        );
      }
    } else if (loadingState is Error) {
      return HttpError(
        errMsg: (loadingState as Error).errMsg,
        fn: _controller.onReload,
      );
    }
    return const SizedBox();
  }

  Widget _buildAreaGrid(ThemeData theme, AreaList areaList, double bottom) {
    final list = areaList.areaList;
    if (list == null || list.isEmpty) {
      return const Center(child: Text('暂无子分区'));
    }
    return GridView.builder(
      padding: EdgeInsets.only(
        top: 12,
        left: 12,
        right: 12,
        bottom: bottom + 100,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 100,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 80,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _tagItem(theme: theme, item: item);
      },
    );
  }

  Widget _tagItem({
    required ThemeData theme,
    required AreaItem item,
  }) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          '/liveAreaDetail',
          arguments: {
            'areaId': item.id,
            'parentAreaId': item.parentId,
            'areaName': item.name,
          },
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: NetworkImgLayer(
              width: 48,
              height: 48,
              src: item.pic ?? '',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
