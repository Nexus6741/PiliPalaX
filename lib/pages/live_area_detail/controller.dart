import 'dart:math';

import 'package:PiliPalaX/http/live.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/live/live_area_list/area_item.dart';
import 'package:PiliPalaX/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiveAreaDetailController extends GetxController {
  LiveAreaDetailController(this.areaId, this.parentAreaId);
  final dynamic areaId;
  final dynamic parentAreaId;

  final ScrollController scrollController = ScrollController();

  bool isLoading = false;
  Rx<LoadingState<List<AreaItem>?>> loadingState =
      Rx<LoadingState<List<AreaItem>?>>(LoadingState.loading());

  int initialIndex = 0;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  List<AreaItem>? getDataList(List<AreaItem>? response) {
    if (response != null && response.isNotEmpty) {
      initialIndex = max(0, response.indexWhere((e) => e.id == areaId));
    }
    return response;
  }

  Future<LoadingState<List<AreaItem>?>> customGetData() =>
      LiveHttp.liveRoomAreaList(parentid: parentAreaId);

  Future<void> queryData() async {
    if (isLoading) return;
    isLoading = true;
    LoadingState<List<AreaItem>?> response = await customGetData();
    if (response is Success<List<AreaItem>?>) {
      getDataList(response.response);
    }
    loadingState.value = response;
    isLoading = false;
  }

  Future<void> onRefresh() {
    return queryData();
  }

  Future<void> onReload() {
    loadingState.value = LoadingState.loading();
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
