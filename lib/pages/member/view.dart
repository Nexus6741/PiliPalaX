import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/pages/member/index.dart';
import 'package:PiliPalaX/utils/utils.dart';

import '../member_dynamics/view.dart';
import '../member_seasons_and_series/view.dart';
import '../member_home/view.dart';
import '../member_bangumi/view.dart';
import '../member_favorite/view.dart';
import '../member_contribute/view.dart';
import 'widgets/user_info_card.dart';
import 'package:PiliPalaX/common/widgets/spring_physics.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({super.key});

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage>
    with SingleTickerProviderStateMixin {
  late String heroTag;
  late MemberController _memberController;
  late int mid;

  @override
  void initState() {
    super.initState();
    mid = int.parse(Get.parameters['mid']!);
    heroTag = Get.arguments?['heroTag'] ?? Utils.makeHeroTag(mid);
    _memberController = Get.put(MemberController(mid: mid), tag: heroTag);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: true,
      appBar: AppBar(
        actions: _buildActions(context),
      ),
      body: Obx(() {
        // 加载中
        if (_memberController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // 加载失败
        if (_memberController.errorMsg.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_memberController.errorMsg.value),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _memberController.refresh(),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        // 数据为空
        if (_memberController.spaceData.value == null) {
          return const Center(child: Text('暂无数据'));
        }

        return _buildContent(context);
      }),
    );
  }

  // 构建内容
  Widget _buildContent(BuildContext context) {
    final spaceData = _memberController.spaceData.value!;
    final card = spaceData.card;
    final images = spaceData.images;

    // 调试信息 - 如果card或images为空，显示详细错误
    if (card == null || images == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '数据解析异常',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (card == null) ...[
                const Text('❌ card 数据为空'),
                const SizedBox(height: 8),
              ],
              if (images == null) ...[
                const Text('❌ images 数据为空'),
                const SizedBox(height: 8),
              ],
              const Text('请查看控制台日志了解详细错误信息'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _memberController.refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // 获取支持的Tab列表
    final tabs = _getSupportedTabs();

    return NestedScrollView(
      floatHeaderSlivers: false,
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          // 用户信息卡片
          SliverToBoxAdapter(
            child: Obx(() => UserInfoCard(
                  isOwner: _memberController.ownerMid == mid,
                  card: card,
                  images: images,
                  relation: _memberController.relation.value,
                  onFollow: () => _memberController.actionRelationMod(context),
                  live: spaceData.live,
                  silence: spaceData.silence,
                )),
          ),
          // Tab栏
          if (tabs.isNotEmpty)
            SliverPersistentHeader(
              delegate: _MySliverPersistentHeaderDelegate(
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: TabBar(
                    labelPadding: const EdgeInsets.symmetric(horizontal: 15),
                    tabAlignment: TabAlignment.center,
                    isScrollable: true,
                    tabs: tabs.map((tab) => Tab(text: tab['title'])).toList(),
                    controller: _memberController.tabController,
                  ),
                ),
              ),
              pinned: true,
            ),
        ];
      },
      body: tabs.isEmpty
          ? const Center(child: Text('暂无内容'))
          : TabBarView(
              physics: const CustomTabBarViewScrollPhysics(),
              controller: _memberController.tabController,
              children: tabs.map((tab) => _buildTabContent(tab)).toList(),
            ),
    );
  }

  // 获取支持的Tab列表
  List<Map<String, String>> _getSupportedTabs() {
    final tab2 = _memberController.tab2;
    if (tab2 == null || tab2.isEmpty) {
      // 返回默认Tab（包含主页和追番）
      return [
        {'title': '主页', 'param': 'home'},
        {'title': '动态', 'param': 'dynamic'},
        {'title': '投稿', 'param': 'contribute'},
        {'title': '合集/列表', 'param': 'seasons_series'},
        {'title': '追番', 'param': 'bangumi'},
      ];
    }

    // 过滤支持的Tab，转换为 Map 格式
    return tab2
        .where((tab) {
          return ['home', 'dynamic', 'contribute', 'bangumi', 'favorite']
              .contains(tab.param);
        })
        .map((tab) => {
              'title': tab.title ?? '',
              'param': tab.param ?? '',
            })
        .toList();
  }

  // 构建Tab内容
  Widget _buildTabContent(Map<String, String> tab) {
    final param = tab['param'] ?? '';

    switch (param) {
      case 'home':
        return MemberHomePage(heroTag: heroTag);
      case 'dynamic':
        return MemberDynamicsPage(mid: mid);
      case 'contribute':
        return MemberContribute(
          mid: mid,
          heroTag: heroTag,
        );
      case 'bangumi':
        return MemberBangumiPage(mid: mid);
      case 'favorite':
        return MemberFavoritePage(mid: mid);
      case 'seasons_series':
        return MemberSeasonsAndSeriesPage(mid: mid);
      default:
        return Center(child: Text('未知Tab: $param'));
    }
  }

  // 构建菜单
  List<Widget> _buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: '搜索',
        onPressed: () {
          final name = _memberController.card?.name ?? '';
          Get.toNamed('/memberSearch?mid=$mid&uname=$name');
        },
        icon: const Icon(Icons.search_outlined),
      ),
      PopupMenuButton(
        icon: const Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) => <PopupMenuEntry>[
          // 他人空间的菜单
          if (_memberController.ownerMid != mid &&
              _memberController.userInfo != null) ...[
            PopupMenuItem(
              onTap: () => _memberController.blockUser(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block, size: 19),
                  const SizedBox(width: 10),
                  Obx(() => Text(_memberController.relation.value != 128
                      ? '加入黑名单'
                      : '移除黑名单')),
                ],
              ),
            ),
            // 移除粉丝（如果对方关注了我）
            if (_memberController.card?.relation?.isFollowed == 1)
              PopupMenuItem(
                onTap: _memberController.removeFan,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.remove_circle_outline_outlined, size: 19),
                    SizedBox(width: 10),
                    Text('移除粉丝'),
                  ],
                ),
              ),
          ],
          // 分享
          PopupMenuItem(
            onTap: () => _memberController.shareUser(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.share_outlined, size: 19),
                const SizedBox(width: 10),
                Text(_memberController.ownerMid != mid ? '分享UP主' : '分享我的主页'),
              ],
            ),
          ),
          // 充电排行榜
          PopupMenuItem(
            onTap: () {
              // TODO: 实现充电排行榜
              SmartDialog.showToast('充电排行榜功能开发中');
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.electric_bolt, size: 19),
                SizedBox(width: 10),
                Text('充电排行榜'),
              ],
            ),
          ),
          // 自己空间的额外菜单
          if (_memberController.ownerMid == mid &&
              _memberController.userInfo != null) ...[
            // 大会员经验
            if ((_memberController.card?.vip?.status ?? 0) > 0)
              PopupMenuItem(
                onTap: () async {
                  // TODO: 实现大会员经验领取
                  SmartDialog.showToast('大会员经验功能开发中');
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upcoming_outlined, size: 19),
                    SizedBox(width: 10),
                    Text('大会员经验'),
                  ],
                ),
              ),
            const PopupMenuDivider(),
            // 登录设备
            PopupMenuItem(
              onTap: () {
                // TODO: 实现登录设备页面
                SmartDialog.showToast('登录设备功能开发中');
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.devices, size: 18),
                  SizedBox(width: 10),
                  Text('登录设备'),
                ],
              ),
            ),
            // 登录记录
            PopupMenuItem(
              onTap: () {
                // TODO: 实现登录记录页面
                SmartDialog.showToast('登录记录功能开发中');
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login, size: 18),
                  SizedBox(width: 10),
                  Text('登录记录'),
                ],
              ),
            ),
            // 硬币记录
            PopupMenuItem(
              onTap: () {
                // TODO: 实现硬币记录页面
                SmartDialog.showToast('硬币记录功能开发中');
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on, size: 18),
                  SizedBox(width: 10),
                  Text('硬币记录'),
                ],
              ),
            ),
            // 经验记录
            PopupMenuItem(
              onTap: () {
                // TODO: 实现经验记录页面
                SmartDialog.showToast('经验记录功能开发中');
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.linear_scale, size: 18),
                  SizedBox(width: 10),
                  Text('经验记录'),
                ],
              ),
            ),
            // 空间设置
            PopupMenuItem(
              onTap: () {
                // TODO: 实现空间设置页面
                SmartDialog.showToast('空间设置功能开发中');
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings_outlined, size: 19),
                  SizedBox(width: 10),
                  Text('空间设置'),
                ],
              ),
            ),
          ] else if (_memberController.ownerMid != mid &&
              _memberController.userInfo != null) ...[
            // 举报
            const PopupMenuDivider(),
            PopupMenuItem(
              onTap: () {
                // TODO: 实现举报功能
                SmartDialog.showToast('举报功能开发中');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 19,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '举报',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 复制UID
          PopupMenuItem(
            onTap: () {
              Clipboard.setData(ClipboardData(text: mid.toString()));
              SmartDialog.showToast('已复制UID：$mid');
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.copy, size: 19),
                const SizedBox(width: 10),
                Text('复制UID：$mid')
              ],
            ),
          ),
        ],
      ),
    ];
  }
}

class _MySliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double _minExtent = 40;
  final double _maxExtent = 40;
  final Widget child;

  _MySliverPersistentHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => _maxExtent;

  @override
  double get minExtent => _minExtent;

  @override
  bool shouldRebuild(covariant _MySliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
