import 'package:PiliPalaX/http/live.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/live/live_follow/data.dart';
import 'package:PiliPalaX/models/live/live_follow/item.dart';
import 'package:PiliPalaX/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiveFollowController extends GetxController {
  final ScrollController scrollController = ScrollController();

  int page = 1;
  bool isEnd = false;
  bool isLoading = false;
  Rx<LoadingState<List<LiveFollowItem>?>> loadingState =
      Rx<LoadingState<List<LiveFollowItem>?>>(LoadingState.loading());

  Rx<int?> count = Rx<int?>(null);

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  void checkIsEnd(int length) {
    final count = this.count.value;
    if (count != null && length >= count) {
      isEnd = true;
    }
  }

  List<LiveFollowItem>? getDataList(LiveFollowData response) {
    count.value = response.liveCount;
    return response.list;
  }

  Future<LoadingState<LiveFollowData>> customGetData() =>
      LiveHttp.liveFollow(page);

  Future<void> queryData([bool isRefresh = true]) async {
    if (isLoading || (!isRefresh && isEnd)) return;
    isLoading = true;
    LoadingState<LiveFollowData> response = await customGetData();
    if (response is Success<LiveFollowData>) {
      List<LiveFollowItem>? dataList = getDataList(response.response);
      if (dataList == null || dataList.isEmpty) {
        isEnd = true;
        if (isRefresh) {
          loadingState.value = Success(dataList);
        }
        isLoading = false;
        return;
      }
      if (isRefresh) {
        checkIsEnd(dataList.length);
        loadingState.value = Success(dataList);
      } else if (loadingState.value is Success) {
        final list = loadingState.value.data!..addAll(dataList);
        checkIsEnd(list.length);
        loadingState.refresh();
      }
      page++;
    } else {
      if (isRefresh) {
        loadingState.value =
            Error(response is Error ? (response as Error).errMsg : '加载失败');
      }
    }
    isLoading = false;
  }

  Future<void> onRefresh() {
    page = 1;
    isEnd = false;
    count.value = null;
    return queryData();
  }

  Future<void> onLoadMore() {
    return queryData(false);
  }

  Future<void> onReload() {
    loadingState.value = LoadingState.loading();
    page = 1;
    isEnd = false;
    count.value = null;
    return queryData();
  }

  void animateToTop() {
    scrollController.animToTop();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
