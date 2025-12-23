import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/skeleton/video_reply.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/models/common/reply_type.dart';
import 'package:PiliPalaX/models/video/reply/item.dart';
import 'package:PiliPalaX/pages/video/reply/widgets/reply_item.dart';

import '../../../../utils/utils.dart';
import 'controller.dart';

class VideoReplyReplyPanel extends StatefulWidget {
  const VideoReplyReplyPanel({
    this.oid,
    this.rpid,
    this.closePanel,
    this.firstFloor,
    this.source,
    this.replyType,
    this.id,
    super.key,
  });
  final int? oid;
  final int? rpid;
  final Function? closePanel;
  final ReplyItemModel? firstFloor;
  final String? source;
  final ReplyType? replyType;
  final int? id;

  @override
  State<VideoReplyReplyPanel> createState() => _VideoReplyReplyPanelState();
}

class _VideoReplyReplyPanelState extends State<VideoReplyReplyPanel> {
  late VideoReplyReplyController _ctrl;
  Future? _futureBuilderFuture;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    final bool isExisting = Get.isRegistered<VideoReplyReplyController>(
        tag: widget.rpid.toString());

    _ctrl = Get.put(
        VideoReplyReplyController(
            widget.oid, widget.rpid.toString(), widget.replyType!,
            targetRpid: widget.id),
        tag: widget.rpid.toString());

    // 如果 controller 已存在，需要更新 targetRpid 并触发定位
    if (isExisting && widget.id != null) {
      _ctrl.targetRpid = widget.id;
      // 如果列表已加载，直接定位
      if (_ctrl.replyList.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _ctrl.locateTargetReply();
        });
      }
    }

    scrollController = _ctrl.scrollController;
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 300) {
        EasyThrottle.throttle('replylist', const Duration(milliseconds: 200),
            () => _ctrl.queryReplyList(type: 'onLoad'));
      }
    });

    _futureBuilderFuture = _ctrl.queryReplyList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      height: widget.source == 'videoDetail' && !isLandscape
          ? Utils.getSheetHeight(context)
          : null,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          if (widget.source == 'videoDetail')
            Container(
              height: 45,
              padding: const EdgeInsets.only(left: 12, right: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('评论详情'),
                  IconButton(
                    tooltip: '关闭',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      _ctrl.currentPage = 0;
                      widget.closePanel!();
                      if (isLandscape) {
                        // 横屏时需要手动关闭dialog
                        // Navigator.pop已在closePanel中调用
                      } else {
                        // 竖屏时关闭bottomSheet
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
          Expanded(
            child: RefreshIndicator(
              displacement: 10.0,
              edgeOffset: 10.0,
              onRefresh: () async {
                setState(() {});
                _ctrl.currentPage = 0;
                return await _ctrl.queryReplyList();
              },
              child: CustomScrollView(
                controller: _ctrl.scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  if (widget.firstFloor != null) ...[
                    SliverToBoxAdapter(
                      child: ReplyItem(
                        replyItem: widget.firstFloor,
                        replyLevel: '2',
                        showReplyRow: false,
                        addReply: (replyItem) => _ctrl.replyList.add(replyItem),
                        replyType: widget.replyType,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Divider(
                        height: 20,
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.1),
                        thickness: 6,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Obx(() => Text(
                              '共 ${_ctrl.replyList.length} 条回复',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            )),
                      ),
                    ),
                  ],
                  _buildReplyList(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyList(BuildContext context) {
    return FutureBuilder(
      future: _futureBuilderFuture,
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final Map data = snapshot.data as Map;
          if (data['status']) {
            return _buildSuccessContent(context);
          } else {
            return HttpError(errMsg: data['msg'], fn: () => setState(() {}));
          }
        } else {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const VideoReplySkeleton(),
              childCount: 8,
            ),
          );
        }
      },
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: <Widget>[
        if (widget.firstFloor == null && _ctrl.root != null) ...[
          SliverToBoxAdapter(
            child: ReplyItem(
              replyItem: _ctrl.root,
              replyLevel: '2',
              showReplyRow: false,
              addReply: (replyItem) => _ctrl.replyList.add(replyItem),
              replyType: widget.replyType,
            ),
          ),
          SliverToBoxAdapter(
            child: Divider(
              height: 20,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              thickness: 6,
            ),
          ),
        ],
        Obx(() => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _ctrl.replyList.length) {
                    return _buildLoadMoreIndicator(context);
                  }
                  return _buildReplyItem(context, index);
                },
                childCount: _ctrl.replyList.length + 1,
              ),
            )),
      ],
    );
  }

  Widget _buildLoadMoreIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      height: MediaQuery.of(context).padding.bottom + 100,
      child: Center(
        child: Obx(() => Text(
              _ctrl.noMore.value,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            )),
      ),
    );
  }

  Widget _buildReplyItem(BuildContext context, int index) {
    return Obx(() {
      final isHighlight = _ctrl.highlightIndex.value == index;
      final replyWidget = ReplyItem(
        replyItem: _ctrl.replyList[index],
        replyLevel: '2',
        showReplyRow: false,
        addReply: (replyItem) => _ctrl.replyList.add(replyItem),
        replyType: widget.replyType,
      );

      if (isHighlight) {
        return AnimatedBuilder(
          animation: _ctrl.animationController,
          builder: (ctx, child) {
            final animColor = ColorTween(
              begin: Theme.of(ctx)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              end: Colors.transparent,
            )
                .animate(CurvedAnimation(
                  parent: _ctrl.animationController,
                  curve: const Interval(0.5, 1.0),
                ))
                .value;
            return Container(color: animColor, child: child);
          },
          child: replyWidget,
        );
      }
      return replyWidget;
    });
  }
}
