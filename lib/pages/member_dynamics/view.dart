import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/pages/member_dynamics/index.dart';
import 'package:PiliPalaX/utils/utils.dart';

import '../../common/constants.dart';
import '../../common/widgets/http_error.dart';
import '../../utils/grid.dart';
import '../../utils/storage.dart';
import '../dynamics/widgets/dynamic_panel.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

class MemberDynamicsPage extends StatefulWidget {
  const MemberDynamicsPage({super.key, required this.mid});
  final int mid;
  @override
  State<MemberDynamicsPage> createState() => _MemberDynamicsPageState();
}

class _MemberDynamicsPageState extends State<MemberDynamicsPage>
    with AutomaticKeepAliveClientMixin {
  late MemberDynamicsController _memberDynamicController;
  late bool dynamicsWaterfallFlow;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final int mid = widget.mid;
    final String heroTag = Utils.makeHeroTag(mid);
    _memberDynamicController =
        Get.put(MemberDynamicsController(mid: mid), tag: heroTag);
    dynamicsWaterfallFlow = GStorage.setting
        .get(SettingBoxKey.dynamicsWaterfallFlow, defaultValue: true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if ((scrollNotification is ScrollEndNotification &&
                scrollNotification.metrics.extentAfter == 0) ||
            (scrollNotification is ScrollUpdateNotification &&
                scrollNotification.metrics.maxScrollExtent -
                        scrollNotification.metrics.pixels <=
                    200)) {
          // 触发分页加载
          EasyThrottle.throttle(
              'member_dynamics', const Duration(milliseconds: 1000), () {
            _memberDynamicController.onLoad();
          });
        }
        return true;
      },
      child: RefreshIndicator(
        displacement: 10.0,
        edgeOffset: 10.0,
        onRefresh: _memberDynamicController.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            Obx(() {
              final loadingState = _memberDynamicController.loadingState.value;
              final list = _memberDynamicController.dynamicsList;

              if (loadingState.isLoading && list.isEmpty) {
                return const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (loadingState.isError && list.isEmpty) {
                return SliverToBoxAdapter(
                  child: HttpError(
                    errMsg: loadingState.errMsg ?? '请求失败',
                    fn: _memberDynamicController.onReload,
                  ),
                );
              }

              if (list.isEmpty) {
                return const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: Center(child: Text('暂无动态')),
                  ),
                );
              }

              if (!dynamicsWaterfallFlow) {
                return SliverCrossAxisGroup(
                  slivers: [
                    const SliverFillRemaining(),
                    SliverConstrainedCrossAxis(
                        maxExtent: Grid.maxRowWidth * 2,
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return DynamicPanel(item: list[index]);
                            },
                            childCount: list.length,
                          ),
                        )),
                    const SliverFillRemaining(),
                  ],
                );
              }

              return SliverWaterfallFlow.extent(
                maxCrossAxisExtent: Grid.maxRowWidth * 2,
                crossAxisSpacing: StyleString.safeSpace,
                mainAxisSpacing: StyleString.safeSpace,
                lastChildLayoutTypeBuilder: (index) => index == list.length
                    ? LastChildLayoutType.foot
                    : LastChildLayoutType.none,
                children: [
                  for (var i in list) DynamicPanel(item: i),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
