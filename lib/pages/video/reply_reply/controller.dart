import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/http/reply.dart';
import 'package:PiliPalaX/models/common/reply_type.dart';
import 'package:PiliPalaX/models/video/reply/item.dart';

class VideoReplyReplyController extends GetxController
    with GetSingleTickerProviderStateMixin {
  VideoReplyReplyController(this.aid, this.rpid, this.replyType,
      {this.targetRpid});
  final ScrollController scrollController = ScrollController();
  // 视频aid 请求时使用的oid
  int? aid;
  // rpid 请求楼中楼回复
  String? rpid;
  // 目标评论 rpid (用于定位跳转)
  int? targetRpid;
  ReplyType replyType; // = ReplyType.video;
  RxList<ReplyItemModel> replyList = <ReplyItemModel>[].obs;
  // 当前页
  int currentPage = 0;
  bool isLoadingMore = false;
  RxString noMore = ''.obs;
  // 当前回复的回复
  ReplyItemModel? currentReplyItem;
  ReplyItemModel? root;

  // 高亮的评论索引
  RxnInt highlightIndex = RxnInt();
  // 动画控制器
  late AnimationController animationController;

  @override
  void onInit() {
    super.onInit();
    currentPage = 0;
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  Future queryReplyList({type = 'init'}) async {
    if (type == 'init') {
      currentPage = 0;
    }
    if (isLoadingMore) {
      return;
    }
    isLoadingMore = true;
    final res = await ReplyHttp.replyReplyList(
      oid: aid!,
      root: rpid!,
      pageNum: currentPage + 1,
      type: replyType.index,
      sort: 1, // HTTP API 不支持排序切换
    );
    if (res['status']) {
      if (res['data'].root != null) root = res['data'].root;
      final List<ReplyItemModel> replies = res['data'].replies;
      if (replies.isNotEmpty) {
        noMore.value = '加载中...';
        if (replies.length == res['data'].page.count) {
          noMore.value = '没有更多了';
        }
        currentPage++;
      } else {
        // 未登录状态replies可能返回null
        noMore.value = currentPage == 0 ? '还没有评论' : '没有更多了';
      }
      if (type == 'init') {
        replyList.value = replies;
        // 如果有目标评论,查找并定位
        if (targetRpid != null) {
          locateTargetReply();
        }
      } else {
        // 每次回复之后，翻页请求有且只有相同的一条回复数据
        if (replies.length == 1 && replies.last.rpid == replyList.last.rpid) {
          return;
        }
        replyList.addAll(replies);
        // res['data'].replies.addAll(replyList);
      }
    }
    isLoadingMore = false;
    return res;
  }

  // 定位目标评论 (公开方法，供外部调用)
  void locateTargetReply() {
    if (targetRpid == null) return;
    final index = replyList.indexWhere((item) => item.rpid == targetRpid);
    if (index != -1) {
      highlightIndex.value = index;
      // 使用 addPostFrameCallback 确保在列表渲染后再滚动
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          scrollToIndex(index);
          animationController.forward(from: 0);
        });
      });
      targetRpid = null; // 清除目标,避免重复定位
    }
  }

  // 滚动到指定索引
  void scrollToIndex(int index) {
    if (!scrollController.hasClients) return;
    // 估算每个评论项的高度(包括头像、内容、按钮等)
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
    currentPage = 0;
    animationController.dispose();
    super.onClose();
  }
}
