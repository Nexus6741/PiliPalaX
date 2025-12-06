import 'dart:math';

import 'package:PiliPalaX/http/live.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/live/live_feed_index/card_live_item.dart';
import 'package:PiliPalaX/models/live/live_second_list/data.dart';
import 'package:PiliPalaX/models/live/live_second_list/tag.dart';
import 'package:PiliPalaX/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiveAreaChildController extends GetxController {
  LiveAreaChildController(this.areaId, this.parentAreaId);
  final dynamic areaId;
  final dynamic parentAreaId;

  final ScrollController scrollController = ScrollController();

  int page = 1;
  int? count;
  bool isEnd = false;
  bool isLoading = false;
  Rx<LoadingState<List<CardLiveItem>?>> loadingState =
      Rx<LoadingState<List<CardLiveItem>?>>(LoadingState.loading());

  String? sortType;

  // tag
  final RxInt tagIndex = 0.obs;
  List<LiveSecondTag>? newTags;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  void checkIsEnd(int length) {
    if (count != null && length >= count!) {
      isEnd = true;
    }
  }

  List<CardLiveItem>? getDataList(LiveSecondData response) {
    count = response.count;
    newTags = response.newTags;
    if (newTags != null && sortType != null) {
      final idx = newTags!.indexWhere((e) => e.sortType == sortType);
      tagIndex.value = max(0, idx);
    } else {
      tagIndex.value = 0;
    }
    return response.cardList;
  }

  Future<LoadingState<LiveSecondData>> customGetData() =>
      LiveHttp.liveSecondList(
        pn: page,
        areaId: areaId,
        parentAreaId: parentAreaId,
        sortType: sortType,
      );

  Future<void> queryData([bool isRefresh = true]) async {
    if (isLoading || (!isRefresh && isEnd)) return;
    isLoading = true;
    LoadingState<LiveSecondData> response = await customGetData();
    if (response is Success<LiveSecondData>) {
      List<CardLiveItem>? dataList = getDataList(response.response);
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
    return queryData();
  }

  Future<void> onLoadMore() {
    return queryData(false);
  }

  Future<void> onReload() {
    loadingState.value = LoadingState.loading();
    page = 1;
    isEnd = false;
    return queryData();
  }

  void onSelectTag(int index, String? sortType) {
    if (isLoading) {
      return;
    }
    tagIndex.value = index;
    this.sortType = sortType;
    onRefresh();
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
