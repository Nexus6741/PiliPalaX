import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/models/member/space_data.dart';
import 'package:PiliPalaX/pages/member/controller.dart';

class MemberContributeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  MemberContributeController({
    required this.heroTag,
    required this.initialIndex,
  });

  final String? heroTag;
  final int? initialIndex;

  TabController? tabController;
  List<Tab>? tabs;
  late final MemberController _ctr = Get.find<MemberController>(tag: heroTag);
  List<SpaceTab2Item>? items;
  bool? hasSeasonOrSeries;

  @override
  void onInit() {
    super.onInit();

    // 从 MemberController 获取 contribute 的 items
    final contributeTab = _ctr.tab2?.firstWhere(
      (item) => item.param == 'contribute',
      orElse: () => SpaceTab2(),
    );

    // print('========== MemberContribute Debug ==========');
    // print('Found contribute tab: ${contributeTab != null}');
    // print('Contribute items count: ${contributeTab?.items?.length ?? 0}');

    if (contributeTab?.items != null && contributeTab!.items!.isNotEmpty) {
      items = List.from(contributeTab.items!);

      // 打印所有items
      // print('All contribute items:');
      for (var item in items!) {
        // print(
        // '  - title: ${item.title}, param: ${item.param}, seasonId: ${item.seasonId}, seriesId: ${item.seriesId}');
      }

      // 检查是否有合集或列表
      hasSeasonOrSeries = items!.any((item) =>
          item.param == 'season_video' ||
          item.param == 'series' ||
          item.seasonId != null ||
          item.seriesId != null);

      // print('Has season or series: $hasSeasonOrSeries');

      // 如果有合集/列表，添加"全部合集/列表"项
      if (hasSeasonOrSeries == true) {
        items!.add(
          SpaceTab2Item(
            param: 'ugcSeason',
            title: '全部合集/列表',
          ),
        );
      }

      // 如果有多个Tab，创建TabController
      if (items!.length > 1) {
        tabs = items!.map((item) => Tab(text: item.title)).toList();
        tabController = TabController(
          vsync: this,
          length: items!.length,
          initialIndex: max(0, initialIndex ?? 0),
        );
        // print('Created TabController with ${items!.length} tabs');
      } else {
        // print('Single tab mode, no TabController created');
      }
    } else {
      // print('No contribute items found');
    }
    // print('===========================================');
  }

  @override
  void onClose() {
    tabController?.dispose();
    super.onClose();
  }
}
