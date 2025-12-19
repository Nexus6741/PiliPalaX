import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/http/reply.dart';
import 'package:PiliPalaX/models/common/reply_type.dart';
import 'package:PiliPalaX/models/video/reply/item.dart';

class VideoReplyDialogController extends GetxController
    with GetSingleTickerProviderStateMixin {
  VideoReplyDialogController(
    this.oid,
    this.root,
    this.dialog,
    this.replyType, {
    this.targetRpid,
  });

  final ScrollController scrollController = ScrollController();
  // 视频oid
  int oid;
  // 根评论 rpid
  int root;
  // 对话树根 rpid
  int dialog;
  // 目标评论 rpid (用于定位跳转)
  int? targetRpid;
  ReplyType replyType;
  RxList<ReplyItemModel> replyList = <ReplyItemModel>[].obs;
  // 分页用的 minFloor
  int? minFloor;
  bool isLoadingMore = false;
  RxString noMore = ''.obs;
  // 根评论
  ReplyItemModel? rootReply;

  // 高亮的评论索引
  RxnInt highlightIndex = RxnInt();
  // 动画控制器
  late AnimationController animationController;

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  Future queryDialogList({String type = 'init'}) async {
    if (type == 'init') {
      minFloor = null;
      replyList.clear();
    }
    if (isLoadingMore) return;
    isLoadingMore = true;

    final res = await ReplyHttp.replyDialogList(
      oid: oid,
      root: root,
      dialog: dialog,
      type: replyType.index,
      size: 20,
      minFloor: minFloor,
    );

    if (res['status']) {
      final data = res['data'];
      final List<dynamic> replies = data['replies'] ?? [];
      final cursor = data['cursor'];
      final upperMid = data['upper']?['mid'] ?? 0;

      if (replies.isNotEmpty) {
        final List<ReplyItemModel> newReplies =
            replies.map((e) => ReplyItemModel.fromJson(e, upperMid)).toList();

        if (type == 'init') {
          replyList.value = newReplies;
          // 如果有目标评论,查找并定位
          if (targetRpid != null) {
            locateTargetReply();
          }
        } else {
          replyList.addAll(newReplies);
        }

        // 更新分页参数
        if (cursor != null && cursor['max_floor'] != null) {
          minFloor = cursor['max_floor'] + 1;
        }

        // 检查是否还有更多
        final dialogInfo = data['dialog'];
        if (dialogInfo != null &&
            cursor != null &&
            cursor['max_floor'] >= dialogInfo['max_floor']) {
          noMore.value = '没有更多了';
        } else {
          noMore.value = '加载中...';
        }
      } else {
        noMore.value = replyList.isEmpty ? '暂无对话' : '没有更多了';
      }
    }

    isLoadingMore = false;
    return res;
  }

  // 定位目标评论
  void locateTargetReply() {
    if (targetRpid == null) return;
    final index = replyList.indexWhere((item) => item.rpid == targetRpid);
    if (index != -1) {
      highlightIndex.value = index;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          scrollToIndex(index);
          animationController.forward(from: 0);
        });
      });
      targetRpid = null;
    }
  }

  // 滚动到指定索引
  void scrollToIndex(int index) {
    if (!scrollController.hasClients) return;
    const double itemHeight = 150.0;
    final double targetOffset = index * itemHeight;
    final double maxOffset = scrollController.position.maxScrollExtent;
    final double offset = targetOffset.clamp(0.0, maxOffset);

    scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
