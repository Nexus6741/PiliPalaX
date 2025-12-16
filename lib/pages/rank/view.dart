import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/widgets/spring_physics.dart';
import 'package:PiliPalaX/pages/rank/controller.dart';
import 'package:PiliPalaX/pages/rank/zone/view.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final RankController _rankController = Get.put(RankController());

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rankController.tabController = TabController(
      length: _rankController.tabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rankController.tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
        bottom: TabBar(
          controller: _rankController.tabController,
          tabs: _rankController.tabs.map((e) => Tab(text: e['label'])).toList(),
          isScrollable: true,
          dividerColor: Colors.transparent,
          tabAlignment: TabAlignment.start,
        ),
      ),
      body: TabBarView(
        physics: const CustomTabBarViewScrollPhysics(),
        controller: _rankController.tabController,
        children: _rankController.tabs.map((tab) {
          return ZonePage(
            rid: tab['rid'],
            tid: tab['tid'],
          );
        }).toList(),
      ),
    );
  }
}
