import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/http/dynamics.dart';
import 'package:PiliPalaX/http/user.dart';
import 'package:PiliPalaX/models/dynamics/topic_card_list.dart';
import 'package:PiliPalaX/models/dynamics/topic_top_details.dart';
import 'package:PiliPalaX/utils/storage.dart';

class DynamicsTopicController extends GetxController {
  final String topicId = Get.parameters['id']!;
  String topicName = Get.parameters['name'] ?? '';

  RxInt sortBy = 0.obs;
  String offset = '';
  Rx<TopicSortByConf?> topicSortByConf = Rx<TopicSortByConf?>(null);
  bool _isInitialized = false;

  double? appbarOffset;

  // top
  Rx<bool?> isFav = Rx<bool?>(null);
  Rx<bool?> isLike = Rx<bool?>(null);
  Rx<TopicTopDetails?> topDetails = Rx<TopicTopDetails?>(null);
  RxBool isTopLoading = true.obs;
  RxString topErrorMsg = ''.obs;

  // list
  RxList<TopicCardItem> dynamicsList = <TopicCardItem>[].obs;
  RxBool isLoading = true.obs;
  RxBool isLoadingMore = false.obs;
  RxBool isEnd = false.obs;
  RxString errorMsg = ''.obs;

  late final ScrollController scrollController = ScrollController();
  late final bool isLogin = GStorage.userInfo.get('userInfoCache') != null;

  @override
  void onInit() {
    super.onInit();

    // 添加滚动监听
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (!isEnd.value && !isLoadingMore.value) {
          onLoadMore();
        }
      }
    });

    queryTop();
    queryData();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> queryTop() async {
    isTopLoading.value = true;
    topErrorMsg.value = '';

    var res = await DynamicsHttp.topicTop(topicId: topicId);
    if (res['status']) {
      topDetails.value = res['data'];
      if (topDetails.value?.topicItem != null) {
        var topicItem = topDetails.value!.topicItem!;
        topicName = topicItem.name;
        isFav.value = topicItem.isFav;
        isLike.value = topicItem.isLike;
      }
    } else {
      topErrorMsg.value = res['msg'] ?? '加载失败';
    }
    isTopLoading.value = false;
  }

  Future<void> queryData() async {
    if (isLoadingMore.value || isEnd.value) return;

    if (offset.isEmpty) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }
    errorMsg.value = '';

    // print(
    // '📡 [queryData] 请求参数: topicId=$topicId, offset=$offset, sortBy=${sortBy.value}');

    var res = await DynamicsHttp.topicFeed(
      topicId: topicId,
      offset: offset,
      sortBy: sortBy.value,
    );

    if (res['status']) {
      TopicCardList? data = res['data'];
      if (data != null) {
        offset = data.offset ?? '';
        // print(
        // '📊 [queryData] 响应数据: items=${data.items?.length ?? 0}, hasMore=${data.hasMore}, offset=$offset');

        // 更新排序配置
        topicSortByConf.value = data.topicSortByConf;

        // 只在第一次初始化时设置默认排序
        if (!_isInitialized && data.topicSortByConf != null) {
          sortBy.value = data.topicSortByConf?.showSortBy ?? 0;
          _isInitialized = true;
          // print('🎯 [queryData] 初始化默认排序: ${sortBy.value}');
        }

        if (data.hasMore == false) {
          isEnd.value = true;
        }

        if (data.items != null && data.items!.isNotEmpty) {
          if (offset.isEmpty) {
            dynamicsList.value = data.items!;
            // print('✅ [queryData] 设置新数据: ${data.items!.length} 条');
          } else {
            dynamicsList.addAll(data.items!);
            // print('➕ [queryData] 追加数据: ${data.items!.length} 条');
          }
        } else {
          // 如果没有数据且是第一页，清空列表
          if (offset.isEmpty) {
            dynamicsList.clear();
            // print('🗑️ [queryData] 清空列表，无数据');
          }
        }
      }
    } else {
      errorMsg.value = res['msg'] ?? '加载失败';
      // print('❌ [queryData] 请求失败: ${res['msg']}');
    }

    isLoading.value = false;
    isLoadingMore.value = false;
  }

  Future<void> onRefresh() async {
    offset = '';
    isEnd.value = false;
    await Future.wait([
      queryTop(),
      queryData(),
    ]);
  }

  Future<void> onLoadMore() async {
    if (!isEnd.value && !isLoadingMore.value) {
      await queryData();
    }
  }

  Future<void> onReload() async {
    if (appbarOffset != null) {
      if (scrollController.hasClients &&
          scrollController.offset > appbarOffset!) {
        scrollController.jumpTo(appbarOffset!);
      }
    } else {
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
    }
    offset = '';
    isEnd.value = false;
    dynamicsList.clear(); // 清空列表
    await queryData();
  }

  void onSort(int newSortBy) {
    // print('🔄 [onSort] 切换排序: $newSortBy');
    sortBy.value = newSortBy;
    onReload();
  }

  Future<void> onFav() async {
    // print('🔵 [onFav] 开始收藏/取消收藏');
    // print('🔵 [onFav] isLogin: $isLogin');

    if (!isLogin) {
      SmartDialog.showToast('账号未登录');
      return;
    }

    bool currentIsFav = isFav.value ?? false;
    // print('🔵 [onFav] currentIsFav: $currentIsFav');
    // print('🔵 [onFav] topicId: $topicId');

    var res = currentIsFav
        ? await UserHttp.delFavTopic(topicId)
        : await UserHttp.addFavTopic(topicId);

    // print('🔵 [onFav] 返回结果: $res');

    if (res['status']) {
      if (topDetails.value?.topicItem != null) {
        if (currentIsFav) {
          topDetails.value!.topicItem!.fav -= 1;
        } else {
          topDetails.value!.topicItem!.fav += 1;
        }
      }
      isFav.value = !currentIsFav;
      SmartDialog.showToast(currentIsFav ? '已取消收藏' : '收藏成功');
    } else {
      SmartDialog.showToast(res['msg'] ?? '操作失败');
    }
  }

  Future<void> onLike() async {
    // print('🔵 [onLike] 开始点赞/取消点赞');
    // print('🔵 [onLike] isLogin: $isLogin');

    if (!isLogin) {
      SmartDialog.showToast('账号未登录');
      return;
    }

    bool currentIsLike = isLike.value ?? false;
    // print('🔵 [onLike] currentIsLike: $currentIsLike');
    // print('🔵 [onLike] topicId: $topicId');

    var res = await UserHttp.likeTopic(topicId, currentIsLike);

    // print('🔵 [onLike] 返回结果: $res');

    if (res['status']) {
      if (topDetails.value?.topicItem != null) {
        if (currentIsLike) {
          topDetails.value!.topicItem!.like -= 1;
        } else {
          topDetails.value!.topicItem!.like += 1;
        }
      }
      isLike.value = !currentIsLike;
      SmartDialog.showToast(currentIsLike ? '已取消点赞' : '点赞成功');
    } else {
      SmartDialog.showToast(res['msg'] ?? '操作失败');
    }
  }
}
