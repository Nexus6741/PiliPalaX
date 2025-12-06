import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/skeleton/video_card_v.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/common/widgets/search_text.dart';
import 'package:PiliPalaX/common/widgets/self_sized_horizontal_list.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/live/live_feed_index/card_live_item.dart';
import 'package:PiliPalaX/pages/live/widgets/live_item_app.dart';
import 'package:PiliPalaX/utils/grid.dart';

import 'child_controller.dart';

class LiveAreaChildPage extends StatefulWidget {
  const LiveAreaChildPage({
    super.key,
    required this.areaId,
    required this.parentAreaId,
  });

  final dynamic areaId;
  final dynamic parentAreaId;

  @override
  State<LiveAreaChildPage> createState() => _LiveAreaChildPageState();
}

class _LiveAreaChildPageState extends State<LiveAreaChildPage>
    with AutomaticKeepAliveClientMixin {
  late final _controller = Get.put(
    LiveAreaChildController(widget.areaId, widget.parentAreaId),
    tag: '${widget.areaId}${widget.parentAreaId}',
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller.scrollController.addListener(() {
      if (_controller.scrollController.position.pixels >=
          _controller.scrollController.position.maxScrollExtent - 200) {
        EasyThrottle.throttle(
            'liveAreaChild', const Duration(milliseconds: 200), () {
          _controller.onLoadMore();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ThemeData theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _controller.onRefresh,
      child: CustomScrollView(
        controller: _controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              left: StyleString.safeSpace,
              right: StyleString.safeSpace,
              top: StyleString.safeSpace,
              bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
            ),
            sliver: Obx(
              () => _buildBody(theme, _controller.loadingState.value),
            ),
          ),
        ],
      ),
    );
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: StyleString.cardSpace,
    crossAxisSpacing: StyleString.cardSpace,
    maxCrossAxisExtent: Grid.maxRowWidth,
    childAspectRatio: StyleString.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(90),
  );

  Widget _buildBody(
    ThemeData theme,
    LoadingState<List<CardLiveItem>?> loadingState,
  ) {
    if (loadingState is Loading) {
      return SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemBuilder: (context, index) => const VideoCardVSkeleton(),
        itemCount: 10,
      );
    } else if (loadingState is Success) {
      final response = (loadingState as Success<List<CardLiveItem>?>).response;
      return SliverMainAxisGroup(
        slivers: [
          if (_controller.newTags?.isNotEmpty == true)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelfSizedHorizontalList(
                  gapSize: 12,
                  childBuilder: (index) {
                    final item = _controller.newTags![index];
                    return Obx(
                      () {
                        final isCurr = index == _controller.tagIndex.value;
                        return SearchText(
                          fontSize: 14,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          text: '${item.name}',
                          bgColor: isCurr
                              ? theme.colorScheme.secondaryContainer
                              : Colors.transparent,
                          textColor: isCurr
                              ? theme.colorScheme.onSecondaryContainer
                              : null,
                          onTap: (value) {
                            _controller.onSelectTag(index, item.sortType);
                          },
                        );
                      },
                    );
                  },
                  itemCount: _controller.newTags!.length,
                ),
              ),
            ),
          if (response != null && response.isNotEmpty)
            SliverGrid.builder(
              gridDelegate: gridDelegate,
              itemBuilder: (context, index) {
                if (index == response.length - 1) {
                  _controller.onLoadMore();
                }
                return LiveCardVApp(item: response[index]);
              },
              itemCount: response.length,
            )
          else
            SliverToBoxAdapter(
              child: HttpError(
                errMsg: '暂无数据',
                fn: _controller.onReload,
              ),
            ),
        ],
      );
    } else if (loadingState is Error) {
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: (loadingState as Error).errMsg,
          fn: _controller.onReload,
        ),
      );
    }
    return const SliverToBoxAdapter(child: SizedBox());
  }
}
