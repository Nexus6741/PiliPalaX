import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/skeleton/video_card_v.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/live/live_follow/item.dart';
import 'package:PiliPalaX/utils/grid.dart';
import 'package:easy_debounce/easy_throttle.dart';

import 'controller.dart';
import 'widgets/live_item_follow.dart';

class LiveFollowPage extends StatefulWidget {
  const LiveFollowPage({super.key});

  @override
  State<LiveFollowPage> createState() => _LiveFollowPageState();
}

class _LiveFollowPageState extends State<LiveFollowPage> {
  final _controller = Get.put(LiveFollowController());

  @override
  void initState() {
    super.initState();
    _controller.scrollController.addListener(() {
      if (_controller.scrollController.position.pixels >=
          _controller.scrollController.position.maxScrollExtent - 200) {
        EasyThrottle.throttle(
            'liveFollowList', const Duration(milliseconds: 200), () {
          _controller.onLoadMore();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Obx(
          () {
            final count = _controller.count.value;
            return Text(count != null ? '$count人正在直播' : '关注直播');
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _controller.onRefresh,
        child: CustomScrollView(
          controller: _controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                left: StyleString.safeSpace + padding.left,
                right: StyleString.safeSpace + padding.right,
                bottom: padding.bottom + 100,
              ),
              sliver: Obx(() => _buildBody(_controller.loadingState.value)),
            ),
          ],
        ),
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

  Widget _buildBody(LoadingState<List<LiveFollowItem>?> loadingState) {
    if (loadingState is Loading) {
      return SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemBuilder: (context, index) => const VideoCardVSkeleton(),
        itemCount: 10,
      );
    } else if (loadingState is Success) {
      final response =
          (loadingState as Success<List<LiveFollowItem>?>).response;
      if (response != null && response.isNotEmpty) {
        return SliverGrid.builder(
          gridDelegate: gridDelegate,
          itemBuilder: (context, index) {
            if (index == response.length - 1) {
              _controller.onLoadMore();
            }
            return LiveCardVFollow(
              liveItem: response[index],
            );
          },
          itemCount: response.length,
        );
      } else {
        return SliverToBoxAdapter(
          child: HttpError(
            errMsg: '暂无关注的主播正在直播',
            fn: _controller.onReload,
          ),
        );
      }
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
