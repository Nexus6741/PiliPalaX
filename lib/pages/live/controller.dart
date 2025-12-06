import 'package:PiliPalaX/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:PiliPalaX/http/live.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/live/live_feed_index/index.dart';
import 'package:PiliPalaX/models/live/live_second_list/index.dart';
import 'package:PiliPalaX/utils/storage.dart';

class LiveController extends GetxController {
  final ScrollController scrollController = ScrollController();
  int _currentPage = 1;
  int? _totalCount;
  bool isLoading = false;
  bool isEnd = false;

  RxInt crossAxisCount = 2.obs;
  List<OverlayEntry?> popupDialog = <OverlayEntry?>[];
  Box setting = GStorage.setting;

  // 加载状态
  final Rx<LoadingState<List?>> loadingState =
      LoadingState<List?>.loading().obs;

  // 顶部状态（关注+分区入口）
  final Rx<Pair<LiveCardList?, LiveCardList?>> topState =
      Pair<LiveCardList?, LiveCardList?>(first: null, second: null).obs;

  // 当前选中的分区
  final RxInt areaIndex = 0.obs;
  int? areaId;
  int? parentAreaId;

  // 排序标签
  final RxInt tagIndex = 0.obs;
  String? sortType;
  List<LiveSecondTag>? newTags;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  /// 查询数据
  Future<void> queryData() async {
    if (isLoading) return;
    isLoading = true;

    LoadingState result;
    if (areaIndex.value != 0) {
      // 分区列表
      result = await LiveHttp.liveSecondList(
        pn: _currentPage,
        areaId: areaId,
        parentAreaId: parentAreaId,
        sortType: sortType,
      );
    } else {
      // 推荐列表
      result = await LiveHttp.liveFeedIndex(pn: _currentPage);
    }

    isLoading = false;

    if (result is Success) {
      final data = result.data;

      if (_currentPage == 1) {
        // 处理顶部数据
        if (data is LiveIndexData) {
          if (data.hasMore == 0) isEnd = true;
          topState.value = Pair(
            first: data.followItem,
            second: data.areaItem,
          );
          loadingState.value = Success(data.cardList);
        } else if (data is LiveSecondData) {
          _totalCount = data.count;
          newTags = data.newTags;
          if (sortType != null) {
            tagIndex.value =
                newTags?.indexWhere((e) => e.sortType == sortType) ?? -1;
          }
          loadingState.value = Success(data.cardList);
        }
      } else {
        // 追加数据
        final currentState = loadingState.value;
        List? currentList;
        if (currentState is Success<List?>) {
          currentList = currentState.response;
        }
        final newList = <dynamic>[...?currentList];
        if (data is LiveIndexData) {
          if (data.hasMore == 0) isEnd = true;
          newList.addAll(data.cardList ?? []);
        } else if (data is LiveSecondData) {
          if (data.cardList != null &&
              _totalCount != null &&
              newList.length + data.cardList!.length >= _totalCount!) {
            isEnd = true;
          }
          newList.addAll(data.cardList ?? []);
        }
        loadingState.value = Success(newList);
      }
      _currentPage++;
    } else if (result is Error) {
      if (_currentPage == 1) {
        loadingState.value = Error(result.errMsg);
      }
    }
  }

  /// 刷新顶部区域数据（分区切换后）
  Future<void> queryTop() async {
    final res = await LiveHttp.liveFeedIndex(pn: 1, moduleSelect: true);
    if (res is Success<LiveIndexData>) {
      final data = res.response;
      topState.value = Pair(
        first: data.followItem,
        second: data.areaItem,
      );
      // 更新分区索引
      areaIndex
          .value = (data.areaItem?.cardData?.areaEntranceV3?.list?.indexWhere(
                (e) => e.areaV2Id == areaId && e.areaV2ParentId == parentAreaId,
              ) ??
              -2) +
          1;
    }
  }

  /// 选择分区
  void onSelectArea(int index, CardLiveItem? item) {
    if (isLoading) return;
    if (index == areaIndex.value) return;

    tagIndex.value = 0;
    newTags = null;
    sortType = null;
    areaIndex.value = index;
    areaId = item?.areaV2Id;
    parentAreaId = item?.areaV2ParentId;

    _totalCount = null;
    _currentPage = 1;
    isEnd = false;
    loadingState.value = LoadingState.loading();
    queryData();
  }

  /// 选择标签
  void onSelectTag(int index, String? tagSortType) {
    if (isLoading) return;
    tagIndex.value = index;
    sortType = tagSortType;

    _totalCount = null;
    _currentPage = 1;
    isEnd = false;
    loadingState.value = LoadingState.loading();
    queryData();
  }

  /// 加载更多
  Future<void> onLoadMore() async {
    if (isLoading || isEnd) return;
    await queryData();
  }

  /// 下拉刷新
  Future<void> onRefresh() async {
    _totalCount = null;
    _currentPage = 1;
    isEnd = false;
    if (areaIndex.value != 0) {
      queryTop();
    }
    await queryData();
  }

  /// 重新加载
  void onReload() {
    loadingState.value = LoadingState.loading();
    _currentPage = 1;
    isEnd = false;
    queryData();
  }

  /// 返回顶部并刷新
  void animateToTop() {
    scrollController.animToTop();
  }
}

/// 简单的 Pair 类
class Pair<T1, T2> {
  final T1? first;
  final T2? second;

  Pair({this.first, this.second});
}
