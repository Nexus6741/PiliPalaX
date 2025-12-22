import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/pages/member_like/controller.dart';
import 'package:PiliPalaX/pages/member_home/widgets/video_card_v_member_home.dart';
import 'package:PiliPalaX/utils/grid.dart';

class MemberLikePage extends StatefulWidget {
  const MemberLikePage({super.key});

  @override
  State<MemberLikePage> createState() => _MemberLikePageState();
}

class _MemberLikePageState extends State<MemberLikePage> {
  late final int mid;
  late final String? name;
  late final MemberLikeController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    mid = int.parse(Get.parameters['mid'] ?? Get.arguments['mid'].toString());
    name = Get.parameters['name'] ?? Get.arguments['name'];
    _controller = Get.put(
      MemberLikeController(mid: mid),
      tag: 'memberLike_$mid',
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${name ?? ''}的推荐'),
      ),
      body: RefreshIndicator(
        onRefresh: _controller.onRefresh,
        child: Obx(() => _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading.value && _controller.likeList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.likeList.isEmpty) {
      return HttpError(
        errMsg: _controller.loadingText.value,
        fn: () => _controller.queryData(isRefresh: true),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(StyleString.safeSpace),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithExtentAndRatio(
              mainAxisSpacing: StyleString.cardSpace,
              crossAxisSpacing: StyleString.cardSpace,
              maxCrossAxisExtent: Grid.maxRowWidth,
              childAspectRatio: StyleString.aspectRatio,
              mainAxisExtent: MediaQuery.textScalerOf(context).scale(55),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return VideoCardVMemberHome(
                  videoItem: _controller.likeList[index],
                );
              },
              childCount: _controller.likeList.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            height: 100,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                _controller.loadingText.value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
