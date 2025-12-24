import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/pages/member_coin/controller.dart';
import 'package:PiliPalaX/pages/member_home/widgets/video_card_v_member_home.dart';
import 'package:PiliPalaX/utils/grid.dart';

class MemberCoinPage extends StatefulWidget {
  const MemberCoinPage({super.key});

  @override
  State<MemberCoinPage> createState() => _MemberCoinPageState();
}

class _MemberCoinPageState extends State<MemberCoinPage> {
  late final int mid;
  late final String? name;
  late final MemberCoinController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    mid = int.parse(Get.parameters['mid'] ?? Get.arguments['mid'].toString());
    name = Get.parameters['name'] ?? Get.arguments['name'];
    _controller = Get.put(
      MemberCoinController(mid: mid),
      tag: 'memberCoin_$mid',
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
        title: Text('${name ?? ''}的最近投币'),
      ),
      body: RefreshIndicator(
        onRefresh: _controller.onRefresh,
        child: Obx(() => _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading.value && _controller.coinList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.coinList.isEmpty) {
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
                  videoItem: _controller.coinList[index],
                  useTransparentBg: true,
                );
              },
              childCount: _controller.coinList.length,
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
