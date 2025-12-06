import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../models/video_detail_res.dart';
import '../../utils/storage.dart';
import '../../utils/utils.dart';
import 'network_img_layer.dart';

class ListSheet {
  ListSheet({
    required this.episodes,
    this.bvid,
    this.aid,
    required this.currentCid,
    required this.changeFucCall,
    required this.context,
    this.pages,
  });

  final dynamic episodes;
  final String? bvid;
  final int? aid;
  final int currentCid;
  final Function changeFucCall;
  final BuildContext context;
  final List<Part>? pages;

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
                  bvid: bvid,
                  aid: aid,
                  currentCid: currentCid,
                  changeFucCall: changeFucCall,
                  onClose: () => Navigator.of(context).pop(),
                  pages: pages,
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
                bvid: bvid,
                aid: aid,
                currentCid: currentCid,
                changeFucCall: changeFucCall,
                onClose: () => Navigator.of(context).pop(),
                pages: pages,
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
    required this.episodes,
    this.bvid,
    this.aid,
    required this.currentCid,
    required this.changeFucCall,
    required this.onClose,
    this.pages,
  });

  final dynamic episodes;
  final String? bvid;
  final int? aid;
  final int currentCid;
  final Function changeFucCall;
  final Function() onClose;
  final List<Part>? pages;

  @override
  State<ListSheetContent> createState() => _ListSheetContentState();
}

class _ListSheetContentState extends State<ListSheetContent> {
  final ItemScrollController itemScrollController = ItemScrollController();
  late int currentIndex;
  bool reverse = false;
  bool isCurrentExpanded = true; // 控制当前选集列表的展开/收起

  @override
  void initState() {
    super.initState();
    currentIndex =
        widget.episodes!.indexWhere((dynamic e) => e.cid == widget.currentCid);
    if (currentIndex == -1 && widget.bvid != null) {
      currentIndex =
          widget.episodes!.indexWhere((dynamic e) => e.bvid == widget.bvid);
    }
    if (currentIndex == -1 && widget.aid != null) {
      currentIndex =
          widget.episodes!.indexWhere((dynamic e) => e.aid == widget.aid);
    }
    if (currentIndex == -1) {
      currentIndex = 0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentIndex >= 0 && currentIndex < widget.episodes!.length) {
        itemScrollController.jumpTo(index: currentIndex);
      }
    });
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
      widget.changeFucCall(episode.bvid, episode.cid, episode.aid, epid: episode.id);
    } else {
      widget.changeFucCall(widget.bvid!, episode.cid, widget.aid!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Utils.getSheetHeight(context),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Container(
            height: 45,
            padding: const EdgeInsets.only(left: 14, right: 14),
            child: Row(
              children: [
                Text(
                  '合集（${widget.episodes!.length}）',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  tooltip: '跳至顶部',
                  icon: const Icon(Icons.vertical_align_top),
                  onPressed: () {
                    itemScrollController.scrollTo(
                      index: !reverse ? 0 : widget.episodes!.length - 1,
                      duration: const Duration(milliseconds: 200),
                    );
                  },
                ),
                IconButton(
                  tooltip: '跳至底部',
                  icon: const Icon(Icons.vertical_align_bottom),
                  onPressed: () {
                    itemScrollController.scrollTo(
                      index: !reverse ? widget.episodes!.length - 1 : 0,
                      duration: const Duration(milliseconds: 200),
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: '反序',
                  icon: Icon(!reverse
                      ? MdiIcons.sortAscending
                      : MdiIcons.sortDescending),
                  onPressed: () {
                    setState(() {
                      reverse = !reverse;
                    });
                  },
                ),
                IconButton(
                  tooltip: '关闭',
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
          Expanded(
            child: Material(
              child: ScrollablePositionedList.separated(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 20),
                reverse: reverse,
                itemCount: widget.episodes!.length,
                itemBuilder: (BuildContext context, int index) {
                  return buildEpisodeListItem(
                    widget.episodes![index],
                    index,
                    currentIndex == index,
                  );
                },
                itemScrollController: itemScrollController,
                separatorBuilder: (_, index) => Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
