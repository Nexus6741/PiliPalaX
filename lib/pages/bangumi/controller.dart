import 'package:PiliPalaX/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:PiliPalaX/http/bangumi.dart';
import 'package:PiliPalaX/models/bangumi/list.dart';
import 'package:PiliPalaX/models/bangumi/timeline.dart';
import 'package:PiliPalaX/utils/storage.dart';

class BangumiController extends GetxController {
  final ScrollController scrollController = ScrollController();
  RxList<BangumiListItemModel> bangumiList = <BangumiListItemModel>[].obs;
  RxList<BangumiListItemModel> bangumiFollowList = <BangumiListItemModel>[].obs;
  RxList<TimelineModel> timelineList = <TimelineModel>[].obs;
  RxBool timelineLoading = true.obs;
  int _currentPage = 1;
  bool isLoadingMore = true;
  Box userInfoCache = GStorage.userInfo;
  RxBool userLogin = false.obs;
  late int mid;
  var userInfo;

  @override
  void onInit() {
    super.onInit();
    userInfo = userInfoCache.get('userInfoCache');
    if (userInfo != null) {
      mid = userInfo.mid;
    }
    userLogin.value = userInfo != null;
    // 加载追番时间表
    queryBangumiTimeline();
  }

  Future queryBangumiListFeed({type = 'init'}) async {
    if (type == 'init') {
      _currentPage = 1;
    }
    var result = await BangumiHttp.bangumiList(page: _currentPage);
    if (result['status']) {
      if (type == 'init') {
        bangumiList.value = result['data'].list;
      } else {
        bangumiList.addAll(result['data'].list);
      }
      _currentPage += 1;
    } else {}
    isLoadingMore = false;
    return result;
  }

  // 上拉加载
  Future onLoad() async {
    queryBangumiListFeed(type: 'onLoad');
  }

  // 我的订阅
  Future queryBangumiFollow() async {
    userInfo = userInfo ?? userInfoCache.get('userInfoCache');
    if (userInfo == null) {
      return;
    }
    var result = await BangumiHttp.bangumiFollow(mid: userInfo.mid);
    if (result['status']) {
      bangumiFollowList.value = result['data'].list;
    } else {}
    return result;
  }

  // 返回顶部并刷新
  void animateToTop() {
    scrollController.animToTop();
  }

  // 查询追番时间表
  Future<void> queryBangumiTimeline() async {
    timelineLoading.value = true;
    try {
      // 同时获取番剧和国创的时间表
      final results = await Future.wait([
        BangumiHttp.bangumiTimeline(types: 1, before: 6, after: 6), // 番剧
        BangumiHttp.bangumiTimeline(types: 4, before: 6, after: 6), // 国创
      ]);

      List<TimelineModel>? list1 = results[0]['data'];
      List<TimelineModel>? list2 = results[1]['data'];

      // 合并番剧和国创的数据
      if (list1 != null &&
          list2 != null &&
          list1.isNotEmpty &&
          list2.isNotEmpty) {
        for (var i = 0; i < list1.length && i < list2.length; i++) {
          list1[i].addAll(list2[i]);
        }
      } else {
        list1 ??= list2;
      }

      timelineList.value = list1 ?? [];
    } catch (e) {
      timelineList.value = [];
    } finally {
      timelineLoading.value = false;
    }
  }
}
