import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../http/user.dart';
import '../../models/video_detail_res.dart';
import '../../utils/storage.dart';
import '../../utils/utils.dart';
import 'network_img_layer.dart';

class ListSheet {
  ListSheet({
    this.episodes,
    this.sections, // 新增：支持多个sections
    this.bvid,
    this.aid,
    required this.currentCid,
    required this.changeFucCall,
    required this.context,
    this.pages,
    this.ugcSeason, // 新增：合集信息（用于订阅功能）
    this.onSubscriptionChanged, // 新增：订阅状态改变回调
  });

  final dynamic episodes; // 单个section的episodes列表（兼容旧代码）
  final List<SectionItem>? sections; // 多个sections（新功能）
  final String? bvid;
  final int? aid;
  final int currentCid;
  final Function changeFucCall;
  final BuildContext context;
  final List<Part>? pages;
  final UgcSeason? ugcSeason; // 合集信息
  final Function(bool isSubscribed)? onSubscriptionChanged; // 订阅状态改变回调

  late PersistentBottomSheetController bottomSheetController;

  void buildShowBottomSheet() {
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      // 横屏模式：右侧侧边栏
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 350,
                color: Colors.black.withOpacity(0.8),
                child: ListSheetContent(
                  episodes: episodes,
                  sections: sections, // 传递sections
                  bvid: bvid,
                  aid: aid,
                  currentCid: currentCid,
                  changeFucCall: changeFucCall,
                  onClose: () => Navigator.of(context).pop(),
                  pages: pages,
                  ugcSeason: ugcSeason, // 传递合集信息
                  onSubscriptionChanged: onSubscriptionChanged, // 传递回调
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.fastOutSlowIn)),
            child: child,
          );
        },
      );
    } else {
      // 竖屏模式：底部弹窗
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: ListSheetContent(
                episodes: episodes,
                sections: sections, // 传递sections
                bvid: bvid,
                aid: aid,
                currentCid: currentCid,
                changeFucCall: changeFucCall,
                onClose: () => Navigator.of(context).pop(),
                pages: pages,
                ugcSeason: ugcSeason, // 传递合集信息
                onSubscriptionChanged: onSubscriptionChanged, // 传递回调
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.fastOutSlowIn)),
            child: child,
          );
        },
      );
    }
  }
}

class ListSheetContent extends StatefulWidget {
  const ListSheetContent({
    super.key,
    this.episodes,
    this.sections, // 新增：支持多个sections
    this.bvid,
    this.aid,
    required this.currentCid,
    required this.changeFucCall,
    required this.onClose,
    this.pages,
    this.ugcSeason, // 新增：合集信息
    this.onSubscriptionChanged, // 新增：订阅状态改变回调
  });

  final dynamic episodes; // 单个section的episodes列表（兼容旧代码）
  final List<SectionItem>? sections; // 多个sections（新功能）
  final String? bvid;
  final int? aid;
  final int currentCid;
  final Function changeFucCall;
  final Function() onClose;
  final List<Part>? pages;
  final UgcSeason? ugcSeason; // 合集信息
  final Function(bool isSubscribed)? onSubscriptionChanged; // 订阅状态改变回调

  @override
  State<ListSheetContent> createState() => _ListSheetContentState();
}

class _ListSheetContentState extends State<ListSheetContent>
    with SingleTickerProviderStateMixin {
  final ItemScrollController itemScrollController = ItemScrollController();
  late int currentIndex;
  bool reverse = false;
  bool isCurrentExpanded = true; // 控制当前选集列表的展开/收起

  // Section相关
  late List<dynamic> displayEpisodes; // 当前显示的episodes
  int currentSectionIndex = 0; // 当前选中的section索引
  List<SectionItem>? allSections; // 所有sections

  // 订阅状态
  bool isSubscribed = false;
  bool isSubscribing = false;

  // TabController for section tabs
  TabController? _tabController;

  // 为每个section保存独立的scrollController
  Map<int, ItemScrollController> sectionScrollControllers = {};

  @override
  void initState() {
    super.initState();

    // 初始化订阅状态
    if (widget.ugcSeason != null) {
      isSubscribed = widget.ugcSeason!.signState == 1;
      // 异步检查实际订阅状态（确保状态同步）
      _checkSubscriptionStatus();
    }

    // 初始化sections和episodes
    if (widget.sections != null && widget.sections!.isNotEmpty) {
      allSections = widget.sections;
      // 找到包含当前视频的section
      for (int i = 0; i < allSections!.length; i++) {
        final section = allSections![i];
        final found = section.episodes!.any((e) =>
            e.cid == widget.currentCid ||
            e.bvid == widget.bvid ||
            e.aid == widget.aid);
        if (found) {
          currentSectionIndex = i;
          break;
        }
      }
      displayEpisodes = allSections![currentSectionIndex].episodes!;

      // 初始化TabController
      _tabController = TabController(
        length: allSections!.length,
        vsync: this,
        initialIndex: currentSectionIndex,
      );
      _tabController!.addListener(_handleTabChange);
    } else {
      displayEpisodes = widget.episodes!;
    }

    currentIndex =
        displayEpisodes.indexWhere((dynamic e) => e.cid == widget.currentCid);
    if (currentIndex == -1 && widget.bvid != null) {
      currentIndex =
          displayEpisodes.indexWhere((dynamic e) => e.bvid == widget.bvid);
    }
    if (currentIndex == -1 && widget.aid != null) {
      currentIndex =
          displayEpisodes.indexWhere((dynamic e) => e.aid == widget.aid);
    }
    if (currentIndex == -1) {
      currentIndex = 0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentIndex >= 0 && currentIndex < displayEpisodes.length) {
        itemScrollController.jumpTo(index: currentIndex);
      }
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    super.dispose();
  }

  // 处理Tab切换
  void _handleTabChange() {
    if (_tabController == null || !_tabController!.indexIsChanging) return;
    _changeSection(_tabController!.index);
  }

  // 检查订阅状态（确保与服务器同步）
  Future<void> _checkSubscriptionStatus() async {
    if (widget.ugcSeason?.id == null) return;

    try {
      // 查询视频关系，获取真实的订阅状态
      final res = await UserHttp.queryVideoRelation(
        bvid: widget.bvid,
        aid: widget.aid,
      );

      if (res['status'] && res['data'] != null) {
        final data = res['data'];
        // season_fav字段表示是否订阅了合集
        final seasonFav = data['season_fav'] ?? false;

        if (mounted) {
          setState(() {
            isSubscribed = seasonFav;
          });

          // 如果状态与ugcSeason不一致，更新它
          if (widget.ugcSeason!.signState != (seasonFav ? 1 : 0)) {
            widget.ugcSeason!.signState = seasonFav ? 1 : 0;
            // 通知外部状态已更新
            widget.onSubscriptionChanged?.call(seasonFav);
          }
        }
      }
    } catch (e) {
      // 查询失败时，使用ugcSeason中的状态
      if (mounted) {
        setState(() {
          isSubscribed = widget.ugcSeason!.signState == 1;
        });
      }
    }
  }

  // 切换section
  void _changeSection(int index) {
    if (allSections == null || index == currentSectionIndex) return;
    setState(() {
      currentSectionIndex = index;
      displayEpisodes = allSections![index].episodes!;
      // 更新当前索引为该section中的第一个
      currentIndex = 0;
    });
  }

  // 订阅/取消订阅合集
  Future<void> _toggleSubscribe() async {
    if (widget.ugcSeason == null || isSubscribing) return;

    setState(() {
      isSubscribing = true;
    });

    try {
      final seasonId = widget.ugcSeason!.id;
      if (seasonId == null) {
        SmartDialog.showToast('合集ID无效');
        return;
      }

      dynamic res;
      if (isSubscribed) {
        // 取消订阅
        res = await UserHttp.unsubscribeSeason(seasonId: seasonId);
      } else {
        // 订阅
        res = await UserHttp.subscribeSeason(seasonId: seasonId);
      }

      if (res['status']) {
        setState(() {
          isSubscribed = !isSubscribed;
          // 更新UgcSeason的signState
          widget.ugcSeason!.signState = isSubscribed ? 1 : 0;
        });
        // 通知外部订阅状态已改变
        widget.onSubscriptionChanged?.call(isSubscribed);
        SmartDialog.showToast(isSubscribed ? '订阅成功' : '已取消订阅');
      } else {
        SmartDialog.showToast(res['msg'] ?? '操作失败');
      }
    } catch (e) {
      SmartDialog.showToast('操作失败：$e');
    } finally {
      setState(() {
        isSubscribing = false;
      });
    }
  }

  // 定位到当前播放的视频
  void _locateCurrentPlaying() {
    // print('🎯 [定位] 开始定位当前播放');
    // print(
    // '🎯 [定位] currentCid: ${widget.currentCid}, bvid: ${widget.bvid}, aid: ${widget.aid}');
    // print(
    // '🎯 [定位] allSections: ${allSections != null ? allSections!.length : 'null'}');
    // print('🎯 [定位] currentSectionIndex: $currentSectionIndex');
    // print(
    // '🎯 [定位] sectionScrollControllers keys: ${sectionScrollControllers.keys.toList()}');

    // 在所有sections中查找当前播放的视频
    if (allSections != null) {
      for (int i = 0; i < allSections!.length; i++) {
        final section = allSections![i];
        // print(
        // '🎯 [定位] 检查 section $i: ${section.title}, episodes: ${section.episodes?.length}');

        final index = section.episodes!.indexWhere((e) =>
            e.cid == widget.currentCid ||
            e.bvid == widget.bvid ||
            e.aid == widget.aid);

        // print('🎯 [定位] section $i 中找到的 index: $index');

        if (index != -1) {
          // print('🎯 [定位] ✅ 在 section $i 的 index $index 找到当前播放');

          // 找到了，切换到对应的section
          if (i != currentSectionIndex) {
            // print('🎯 [定位] 需要切换 Tab: $currentSectionIndex -> $i');
            // 需要切换Tab
            _tabController?.animateTo(i);
            setState(() {
              currentSectionIndex = i;
              displayEpisodes = allSections![i].episodes!;
              currentIndex = index;
            });
          } else {
            // print('🎯 [定位] 已在当前 Tab，更新 currentIndex: $index');
            currentIndex = index;
          }

          // 滚动到对应位置 - 使用对应section的scrollController
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final controller = sectionScrollControllers[i];
            // print(
            // '🎯 [定位] 获取 controller[$i]: ${controller != null ? 'exists' : 'null'}');
            // print('🎯 [定位] controller.isAttached: ${controller?.isAttached}');

            if (controller != null && controller.isAttached) {
              // print('🎯 [定位] 开始滚动到 index: $index');
              controller.scrollTo(
                index: index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              // print('⚠️ [定位] controller 不可用，无法滚动');
            }
          });
          SmartDialog.showToast('已定位到当前播放');
          return;
        }
      }
      // print('⚠️ [定位] 未在任何 section 中找到当前播放');
    } else {
      // print('🎯 [定位] 单个列表模式');
      // 单个列表，直接滚动
      if (currentIndex >= 0 && currentIndex < displayEpisodes.length) {
        // print('🎯 [定位] 滚动到 index: $currentIndex');
        itemScrollController.scrollTo(
          index: currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        SmartDialog.showToast('已定位到当前播放');
      } else {
        // print(
        // '⚠️ [定位] currentIndex 无效: $currentIndex / ${displayEpisodes.length}');
      }
    }
  }

  Widget buildEpisodeListItem(
    dynamic episode,
    int index,
    bool isCurrentIndex,
  ) {
    Color primary = Theme.of(context).colorScheme.primary;
    late String title;
    if (episode.runtimeType.toString() == "EpisodeItem") {
      if (episode.longTitle != null && episode.longTitle != "") {
        title = "第${(episode.title ?? '${index + 1}')}话  ${episode.longTitle!}";
      } else {
        title = episode.title!;
      }
    } else if (episode.runtimeType.toString() == "PageItem") {
      title = episode.pagePart!;
    } else if (episode.runtimeType.toString() == "Part") {
      title = episode.pagePart!;
    }

    // 新样式：针对 EpisodeItem (合集)
    if (episode is EpisodeItem) {
      Widget item = InkWell(
        onTap: () => _onTap(episode, title),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: NetworkImgLayer(
                      src: episode.cover ?? '',
                      width: 110,
                      height: 62,
                    ),
                  ),
                  if (episode.page?.duration != null)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          Utils.timeFormat(episode.page!.duration!),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            episode.title ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isCurrentIndex
                                  ? primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isCurrentIndex &&
                            widget.pages != null &&
                            widget.pages!.length > 1)
                          InkWell(
                            onTap: () {
                              setState(() {
                                isCurrentExpanded = !isCurrentExpanded;
                              });
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 8, bottom: 8),
                              child: AnimatedRotation(
                                turns: isCurrentExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 统计信息
                    Row(
                      children: [
                        if (episode.stat?.view != null) ...[
                          const Icon(Icons.play_circle_outline,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(
                            Utils.numFormat(episode.stat!.view!),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (episode.stat?.danmu != null) ...[
                          const Icon(Icons.subtitles_outlined,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(
                            Utils.numFormat(episode.stat!.danmu!),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          item,
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.fastOutSlowIn,
            child: SizedBox(
              width: double.infinity,
              child: (isCurrentIndex &&
                      widget.pages != null &&
                      widget.pages!.length > 1 &&
                      isCurrentExpanded)
                  ? Container(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 3.5,
                        ),
                        itemCount: widget.pages!.length,
                        itemBuilder: (context, index) {
                          final page = widget.pages![index];
                          final isCurrent = page.cid == widget.currentCid;
                          return Material(
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                widget.onClose();
                                // 这里是分P，不是番剧集数，所以不需要传递epid
                                widget.changeFucCall(
                                    widget.bvid, page.cid, widget.aid);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isCurrent) ...[
                                      Image.asset(
                                        'assets/images/live.png',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        height: 12,
                                        semanticLabel: "正在播放：",
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        page.pagePart ?? 'P${index + 1}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isCurrent
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          )
        ],
      );
    }

    // 旧样式：针对 Part (分P) 或其他
    return ListTile(
      onTap: () => _onTap(episode, title),
      dense: false,
      leading: isCurrentIndex
          ? Image.asset(
              'assets/images/live.png',
              color: primary,
              height: 12,
              semanticLabel: "正在播放：",
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: isCurrentIndex
              ? primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (episode.badge != null) ...[
            if (episode.badge == '会员')
              Image.asset(
                'assets/images/big-vip.png',
                height: 20,
                semanticLabel: "大会员",
              ),
            if (episode.badge != '会员') Text(episode.badge),
            const SizedBox(width: 10),
          ],
          if (!(episode.runtimeType.toString() == 'EpisodeItem' &&
              (episode.longTitle != null && episode.longTitle != '')))
            Text('${index + 1}/${widget.episodes!.length}'),
        ],
      ),
    );
  }

  void _onTap(dynamic episode, String title) {
    if (episode.badge != null && episode.badge == "会员") {
      dynamic userInfo = GStorage.userInfo.get('userInfoCache');
      int vipStatus = 0;
      if (userInfo != null) {
        vipStatus = userInfo.vipStatus;
      }
      if (vipStatus != 1) {
        SmartDialog.showToast('需要大会员');
        return;
      }
    }
    SmartDialog.showToast('切换到：$title');
    widget.onClose();
    if (episode.runtimeType.toString() == "EpisodeItem") {
      widget.changeFucCall(episode.bvid, episode.cid, episode.aid,
          epid: episode.id);
    } else {
      widget.changeFucCall(widget.bvid!, episode.cid, widget.aid!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 如果有多个sections，使用TabBarView
    final bool hasMultipleSections = allSections != null &&
        allSections!.length > 1 &&
        _tabController != null;

    return Container(
      height: Utils.getSheetHeight(context),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // 标题栏
          Container(
            height: 45,
            padding: const EdgeInsets.only(left: 14, right: 14),
            child: Row(
              children: [
                Text(
                  hasMultipleSections
                      ? '合集（${allSections!.fold<int>(0, (sum, section) => sum + (section.episodes?.length ?? 0))}）'
                      : '合集（${displayEpisodes.length}）',
                  style: theme.textTheme.titleMedium,
                ),
                // 订阅按钮（仅合集显示）
                if (widget.ugcSeason != null)
                  TextButton.icon(
                    onPressed: isSubscribing ? null : _toggleSubscribe,
                    icon: Icon(
                      isSubscribed ? Icons.star : Icons.star_border,
                      size: 18,
                      color: isSubscribed ? Colors.amber : null,
                    ),
                    label: Text(
                      isSubscribed ? '已订阅' : '订阅',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                const Spacer(),
                // 定位当前播放按钮
                IconButton(
                  tooltip: '定位当前播放',
                  icon: const Icon(Icons.my_location, size: 20),
                  onPressed: _locateCurrentPlaying,
                ),
                if (!hasMultipleSections) ...[
                  IconButton(
                    tooltip: '跳至顶部',
                    icon: const Icon(Icons.vertical_align_top, size: 20),
                    onPressed: () {
                      itemScrollController.scrollTo(
                        index: !reverse ? 0 : displayEpisodes.length - 1,
                        duration: const Duration(milliseconds: 200),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: '跳至底部',
                    icon: const Icon(Icons.vertical_align_bottom, size: 20),
                    onPressed: () {
                      itemScrollController.scrollTo(
                        index: !reverse ? displayEpisodes.length - 1 : 0,
                        duration: const Duration(milliseconds: 200),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: '反序',
                    icon: Icon(
                      !reverse
                          ? MdiIcons.sortAscending
                          : MdiIcons.sortDescending,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        reverse = !reverse;
                      });
                    },
                  ),
                ],
                IconButton(
                  tooltip: '关闭',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
          // Section Tab（如果有多个sections）- 使用TabBar实现可滑动切换
          if (hasMultipleSections)
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.outline,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                tabs: allSections!.map((section) {
                  return Tab(
                    text: section.title ??
                        '分组${allSections!.indexOf(section) + 1}',
                  );
                }).toList(),
              ),
            ),
          // 内容区域
          Expanded(
            child: hasMultipleSections
                ? _buildTabBarView(theme)
                : _buildSingleList(theme),
          ),
        ],
      ),
    );
  }

  // 构建TabBarView（多个sections时使用）
  Widget _buildTabBarView(ThemeData theme) {
    // print('🏗️ [构建] _buildTabBarView, sections: ${allSections!.length}');

    return TabBarView(
      controller: _tabController,
      children: allSections!.map((section) {
        final episodes = section.episodes ?? [];
        final sectionIndex = allSections!.indexOf(section);

        // print(
        // '🏗️ [构建] section $sectionIndex: ${section.title}, episodes: ${episodes.length}');

        // 为每个section创建或获取独立的ScrollController
        if (!sectionScrollControllers.containsKey(sectionIndex)) {
          // print('🏗️ [构建] 创建新的 controller[$sectionIndex]');
          sectionScrollControllers[sectionIndex] = ItemScrollController();
        } else {
          // print('🏗️ [构建] 使用已存在的 controller[$sectionIndex]');
        }
        final scrollController = sectionScrollControllers[sectionIndex]!;

        // 如果是当前section，需要定位到当前播放的视频
        if (sectionIndex == currentSectionIndex) {
          final currentIdx = episodes.indexWhere((e) =>
              e.cid == widget.currentCid ||
              e.bvid == widget.bvid ||
              e.aid == widget.aid);

          // print('🏗️ [构建] 当前 section $sectionIndex, currentIdx: $currentIdx');

          if (currentIdx != -1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // print(
              // '🏗️ [构建] 初始定位到 index: $currentIdx, isAttached: ${scrollController.isAttached}');
              if (scrollController.isAttached) {
                scrollController.jumpTo(index: currentIdx);
              }
            });
          }
        }

        return Material(
          child: ScrollablePositionedList.separated(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20),
            itemCount: episodes.length,
            itemBuilder: (BuildContext context, int index) {
              final isCurrentIndex = sectionIndex == currentSectionIndex &&
                  (episodes[index].cid == widget.currentCid ||
                      episodes[index].bvid == widget.bvid ||
                      episodes[index].aid == widget.aid);
              return buildEpisodeListItem(
                episodes[index],
                index,
                isCurrentIndex,
              );
            },
            itemScrollController: scrollController,
            separatorBuilder: (_, index) => Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 构建单个列表（单个section或无section时使用）
  Widget _buildSingleList(ThemeData theme) {
    return Material(
      child: ScrollablePositionedList.separated(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
        reverse: reverse,
        itemCount: displayEpisodes.length,
        itemBuilder: (BuildContext context, int index) {
          return buildEpisodeListItem(
            displayEpisodes[index],
            index,
            currentIndex == index,
          );
        },
        itemScrollController: itemScrollController,
        separatorBuilder: (_, index) => Divider(
          height: 1,
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}
