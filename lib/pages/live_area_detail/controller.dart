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
    // 先计算 initialIndex，再查询数据
    queryData();
  }

  List<AreaItem>? getDataList(List<AreaItem>? response) {
    if (response != null && response.isNotEmpty) {
      // 查找当前 areaId 在列表中的索引
      // 注意：需要处理类型不匹配的情况（int vs String）
      final index = response.indexWhere((e) {
        // 将两者都转换为字符串进行比较
        final eId = e.id?.toString() ?? '';
        final targetId = areaId?.toString() ?? '';
        return eId == targetId;
      });

      initialIndex = index >= 0 ? index : 0;
      // print('=== LiveAreaDetail initialIndex ===');
      // print('areaId: $areaId (type: ${areaId.runtimeType})');
      // print('parentAreaId: $parentAreaId (type: ${parentAreaId.runtimeType})');
      // print('found index: $index');
      // print('initialIndex: $initialIndex');
      // print('response length: ${response.length}');
      // print('All area IDs in response:');
      // for (var i = 0; i < response.length; i++) {
      //   print(
      //       '  [$i] ${response[i].name} (id: ${response[i].id}, type: ${response[i].id.runtimeType})');
      // }
      // if (index >= 0) {
      //   print(
      //       'matched item: ${response[index].name} (id: ${response[index].id})');
      // } else {
      //   print('WARNING: No matching item found for areaId: $areaId');
      // }
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
      // print('=== After getDataList, initialIndex = $initialIndex ===');
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
