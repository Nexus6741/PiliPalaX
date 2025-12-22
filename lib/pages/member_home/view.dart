import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/pages/member_home/controller.dart';
import 'package:PiliPalaX/pages/member_home/widgets/video_card_v_member_home.dart';
import 'package:PiliPalaX/pages/member_home/widgets/fav_item.dart';
import 'package:PiliPalaX/utils/grid.dart';

class MemberHomePage extends StatefulWidget {
  const MemberHomePage({super.key, required this.heroTag});

  final String heroTag;

  @override
  State<MemberHomePage> createState() => _MemberHomePageState();
}

class _MemberHomePageState extends State<MemberHomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final MemberHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      MemberHomeController(heroTag: widget.heroTag),
      tag: widget.heroTag,
    );
  }

  // 视频网格代理
  late final gridDelegateV = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: StyleString.cardSpace,
    crossAxisSpacing: StyleString.cardSpace,
    maxCrossAxisExtent: Grid.maxRowWidth,
    childAspectRatio: StyleString.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(55),
  );

  // 番剧网格代理
  late final gridDelegatePgc = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: StyleString.cardSpace,
    crossAxisSpacing: StyleString.cardSpace,
    maxCrossAxisExtent: Grid.maxRowWidth * 0.6,
    childAspectRatio: 0.75,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(52),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() => _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final spaceData = _controller.spaceData;
    if (spaceData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isVertical = MediaQuery.of(context).size.width < 600;
    final color = Theme.of(context).colorScheme.outline;

    return CustomScrollView(
      slivers: [
        // 视频投稿
        if (spaceData.archive?.item?.isNotEmpty == true) ...[
          _buildHeader(
            color,
            title: '视频',
            param: 'contribute',
            param1: 'video',
            count: spaceData.archive!.count ?? 0,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: StyleString.safeSpace,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: gridDelegateV,
              itemBuilder: (context, index) {
                return VideoCardVMemberHome(
                  videoItem: spaceData.archive!.item![index],
                );
              },
              itemCount: min(
                isVertical ? 4 : 8,
                spaceData.archive!.item!.length,
              ),
            ),
          ),
        ],

        // 收藏夹
        if (spaceData.favourite2?.item?.isNotEmpty == true) ...[
          _buildHeader(
            color,
            title: '收藏',
            param: 'favorite',
            count: spaceData.favourite2!.count ?? 0,
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 98,
              child: MemberHomeFavItem(
                item: spaceData.favourite2!.item!.first,
              ),
            ),
          ),
        ],

        // 最近投币的视频
        if (spaceData.coinArchive?.item?.isNotEmpty == true) ...[
          _buildHeader(
            color,
            title: '最近投币的视频',
            param: 'coinArchive',
            count: spaceData.coinArchive!.count ?? 0,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: StyleString.safeSpace,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: gridDelegateV,
              itemBuilder: (context, index) {
                return VideoCardVMemberHome(
                  videoItem: spaceData.coinArchive!.item![index],
                );
              },
              itemCount: min(
                isVertical ? 2 : 4,
                spaceData.coinArchive!.item!.length,
              ),
            ),
          ),
        ],

        // 最近点赞的视频
        if (spaceData.likeArchive?.item?.isNotEmpty == true) ...[
          _buildHeader(
            color,
            title: '最近点赞的视频',
            param: 'likeArchive',
            count: spaceData.likeArchive!.count ?? 0,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: StyleString.safeSpace,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: gridDelegateV,
              itemBuilder: (context, index) {
                return VideoCardVMemberHome(
                  videoItem: spaceData.likeArchive!.item![index],
                );
              },
              itemCount: min(
                isVertical ? 2 : 4,
                spaceData.likeArchive!.item!.length,
              ),
            ),
          ),
        ],

        // 底部间距
        SliverToBoxAdapter(
          child: SizedBox(
            height: 100 + MediaQuery.viewPaddingOf(context).bottom,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    Color color, {
    required String title,
    required String param,
    String? param1,
    required int count,
    bool? visible,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$title '),
                  TextSpan(
                    text: count.toString(),
                    style: TextStyle(fontSize: 13, color: color),
                  ),
                  if (visible != null)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Icon(
                          visible ? Icons.visibility : Icons.visibility_off,
                          size: 17,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _onMoreTap(param, param1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '查看更多',
                    style: TextStyle(fontSize: 13, color: color),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMoreTap(String param, String? param1) {
    switch (param) {
      case 'contribute':
        _controller.toContributeTab(subTab: param1);
        break;
      case 'favorite':
        _controller.toFavoriteTab();
        break;
      case 'bangumi':
        _controller.toBangumiTab();
        break;
      case 'coinArchive':
        // 跳转到投币视频详情页
        Get.toNamed(
          '/memberCoin',
          parameters: {
            'mid': _controller.memberController.mid.toString(),
            'name': _controller.spaceData?.card?.name ?? '',
          },
        );
        break;
      case 'likeArchive':
        // 跳转到点赞视频详情页
        Get.toNamed(
          '/memberLike',
          parameters: {
            'mid': _controller.memberController.mid.toString(),
            'name': _controller.spaceData?.card?.name ?? '',
          },
        );
        break;
    }
  }
}
