import 'package:PiliPalaX/http/live.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/models/live/live_area_list/area_list.dart';
import 'package:PiliPalaX/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiveAreaController extends GetxController {
  final ScrollController scrollController = ScrollController();

  bool isLoading = false;
  Rx<LoadingState<List<AreaList>?>> loadingState =
      Rx<LoadingState<List<AreaList>?>>(LoadingState.loading());

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  Future<LoadingState<List<AreaList>?>> customGetData() =>
      LiveHttp.liveAreaList();

  Future<void> queryData() async {
    if (isLoading) return;
    isLoading = true;
    LoadingState<List<AreaList>?> response = await customGetData();
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
