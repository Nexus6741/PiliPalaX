import 'package:get/get.dart';
import 'package:PiliPalaX/http/search.dart';
import 'package:PiliPalaX/models/search/trending.dart';
import 'package:flutter/material.dart';

class SearchTrendingController extends GetxController {
  final ScrollController scrollController = ScrollController();
  RxBool isLoading = true.obs;
  RxString errorMsg = ''.obs;
  RxList<SearchTrendingItem> trendingList = <SearchTrendingItem>[].obs;
  RxInt topCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  Future<void> queryData() async {
    isLoading.value = true;
    errorMsg.value = '';

    try {
      var result = await SearchHttp.searchTrending();
      if (result['status']) {
        SearchTrendingModel data = result['data'];
        List<SearchTrendingItem> topList = data.topList ?? [];
        List<SearchTrendingItem> list = data.list ?? [];

        topCount.value = topList.length;
        trendingList.value = [...topList, ...list];
      } else {
        errorMsg.value = result['msg'] ?? '加载失败';
      }
    } catch (e) {
      errorMsg.value = '加载失败: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onRefresh() async {
    await queryData();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
