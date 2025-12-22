import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/pages/member_opus/controller.dart';
import 'package:PiliPalaX/pages/member_opus/widgets/space_opus_card.dart';
import 'package:PiliPalaX/utils/utils.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

class MemberOpusPage extends StatefulWidget {
  const MemberOpusPage({super.key, required this.mid});

  final int mid;

  @override
  State<MemberOpusPage> createState() => _MemberOpusPageState();
}

class _MemberOpusPageState extends State<MemberOpusPage>
    with AutomaticKeepAliveClientMixin {
  late MemberOpusController _controller;
  double _maxWidth = 200;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final String heroTag = Utils.makeHeroTag(widget.mid);
    _controller = Get.put(
      MemberOpusController(mid: widget.mid),
      tag: '${heroTag}_opus',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bottom = MediaQuery.of(context).padding.bottom;

    return RefreshIndicator(
      onRefresh: _controller.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              left: StyleString.safeSpace,
              right: StyleString.safeSpace,
              bottom: bottom + 100,
            ),
            sliver: Obx(() => _buildBody()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // 加载中
    if (_controller.isLoading.value && _controller.opusList.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // 加载失败
    if (_controller.errorMsg.value.isNotEmpty && _controller.opusList.isEmpty) {
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: _controller.errorMsg.value,
          fn: _controller.onRefresh,
        ),
      );
    }

    // 无数据 - 显示空白
    if (_controller.opusList.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // 瀑布流布局
    return SliverWaterfallFlow(
      gridDelegate: SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: StyleString.safeSpace,
        crossAxisSpacing: StyleString.safeSpace,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // 触发加载更多
          if (index == _controller.opusList.length - 1) {
            _controller.onLoadMore();
          }

          // 计算卡片宽度
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = (screenWidth / 200).floor().clamp(2, 4);
          _maxWidth =
              (screenWidth - StyleString.safeSpace * (crossAxisCount + 1)) /
                  crossAxisCount;

          return SpaceOpusCard(
            item: _controller.opusList[index],
            maxWidth: _maxWidth,
          );
        },
        childCount: _controller.opusList.length,
      ),
    );
  }
}
