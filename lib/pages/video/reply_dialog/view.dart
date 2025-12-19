import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/common/skeleton/video_reply.dart';
import 'package:PiliPalaX/common/widgets/http_error.dart';
import 'package:PiliPalaX/models/common/reply_type.dart';
import 'package:PiliPalaX/pages/video/reply/widgets/reply_item.dart';

import '../../../../utils/utils.dart';
import 'controller.dart';

class VideoReplyDialogPanel extends StatefulWidget {
  const VideoReplyDialogPanel({
    required this.oid,
    required this.root,
    required this.dialog,
    required this.replyType,
    this.targetRpid,
    super.key,
  });

  final int oid;
  final int root;
  final int dialog;
  final ReplyType replyType;
  final int? targetRpid;

  @override
  State<VideoReplyDialogPanel> createState() => _VideoReplyDialogPanelState();
}

class _VideoReplyDialogPanelState extends State<VideoReplyDialogPanel> {
  late VideoReplyDialogController _ctrl;
  Future? _futureBuilderFuture;
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    final String tag = '${widget.root}_${widget.dialog}';
    final bool isExisting =
        Get.isRegistered<VideoReplyDialogController>(tag: tag);

    _ctrl = Get.put(
      VideoReplyDialogController(
        widget.oid,
        widget.root,
        widget.dialog,
        widget.replyType,
        targetRpid: widget.targetRpid,
      ),
      tag: tag,
    );

    // 如果 controller 已存在，需要更新 targetRpid 并触发定位
    if (isExisting && widget.targetRpid != null) {
      _ctrl.targetRpid = widget.targetRpid;
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
        EasyThrottle.throttle('dialoglist', const Duration(milliseconds: 200),
            () => _ctrl.queryDialogList(type: 'onLoad'));
      }
    });

    _futureBuilderFuture = _ctrl.queryDialogList();
  }

  @override
  void dispose() {
    super.dispose();
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
            padding: const EdgeInsets.only(left: 12, right: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('查看对话'),
                IconButton(
                  tooltip: '关闭',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
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
                return await _ctrl.queryDialogList(type: 'init');
              },
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return FutureBuilder(
      future: _futureBuilderFuture,
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final Map data = snapshot.data as Map;
          if (data['status']) {
            return _buildSuccessContent(context);
          } else {
            return HttpError(
              errMsg: data['msg'],
              fn: () => setState(() {
                _futureBuilderFuture = _ctrl.queryDialogList(type: 'init');
              }),
            );
          }
        } else {
          return ListView.builder(
            itemCount: 8,
            itemBuilder: (context, index) => const VideoReplySkeleton(),
          );
        }
      },
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    return Obx(() => ListView.builder(
          controller: _ctrl.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _ctrl.replyList.length + 1,
          itemBuilder: (context, index) {
            if (index == _ctrl.replyList.length) {
              return _buildLoadMoreIndicator(context);
            }
            return _buildReplyItem(context, index);
          },
        ));
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
