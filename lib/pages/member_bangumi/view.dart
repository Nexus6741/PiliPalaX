import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/models/bangumi/list.dart';
import 'package:PiliPalaX/pages/member_bangumi/controller.dart';
import 'package:PiliPalaX/pages/member_bangumi/widgets/pgc_card_v.dart';
import 'package:PiliPalaX/utils/grid.dart';

class MemberBangumiPage extends StatefulWidget {
  const MemberBangumiPage({
    super.key,
    required this.mid,
    this.heroTag,
  });

  final int mid;
  final String? heroTag;

  @override
  State<MemberBangumiPage> createState() => _MemberBangumiPageState();
}

class _MemberBangumiPageState extends State<MemberBangumiPage>
    with AutomaticKeepAliveClientMixin {
  late MemberBangumiController _controller;

  @override
  bool get wantKeepAlive => true;

  // 番剧网格代理
  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: StyleString.cardSpace,
    crossAxisSpacing: StyleString.cardSpace,
    maxCrossAxisExtent: Grid.smallCardWidth * 0.6,
    childAspectRatio: 0.75,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(52),
  );

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      MemberBangumiController(mid: widget.mid),
      tag: widget.heroTag ?? 'member_bangumi_${widget.mid}',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _controller.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              left: StyleString.safeSpace,
              right: StyleString.safeSpace,
              top: StyleString.safeSpace,
              bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
            ),
            sliver: Obx(() => _buildBody()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
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

    final data = _controller.bangumiData.value;
    if (data == null || data.list == null || data.list!.isEmpty) {
      return SliverToBoxAdapter(
        child: HttpError(
          errMsg: '暂无追番',
          fn: _controller.loadData,
        ),
      );
    }

    return SliverGrid.builder(
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        // 触发加载更多
        if (index == data.list!.length - 1) {
          _controller.onLoadMore();
        }
        return PgcCardVMemberBangumi(
          item: data.list![index] as BangumiListItemModel,
        );
      },
      itemCount: data.list!.length,
    );
  }
}
