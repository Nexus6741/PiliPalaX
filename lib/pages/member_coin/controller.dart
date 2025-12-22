import 'package:get/get.dart';
import 'package:PiliPalaX/http/member.dart';
import 'package:PiliPalaX/models/member/space_data.dart';

class MemberCoinController extends GetxController {
  final int mid;
  MemberCoinController({required this.mid});

  RxList<SpaceArchiveItem> coinList = <SpaceArchiveItem>[].obs;
  RxBool isLoading = true.obs;
  RxBool isLoadingMore = false.obs;
  RxString loadingText = '加载中...'.obs;
  int currentPage = 1;
  bool hasMore = true;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  Future<void> queryData({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 1;
      hasMore = true;
      coinList.clear();
    }

    isLoading.value = true;
    loadingText.value = '加载中...';

    try {
      var res = await MemberHttp.spaceCoinArc(
        mid: mid,
        page: currentPage,
      );

      if (res['status']) {
        final data = res['data'];
        final List<dynamic>? items = data['item'];

        if (items != null && items.isNotEmpty) {
          final newItems = items
              .map((e) => SpaceArchiveItem.fromJson(e as Map<String, dynamic>))
              .toList();

          if (isRefresh) {
            coinList.value = newItems;
          } else {
            coinList.addAll(newItems);
          }

          currentPage++;
          hasMore = items.length >= 20;
        } else {
          hasMore = false;
        }

        if (!hasMore) {
          loadingText.value = '没有更多了';
        }
      } else {
        loadingText.value = res['msg'] ?? '加载失败';
      }
    } catch (e) {
      loadingText.value = '加载失败: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onRefresh() async {
    await queryData(isRefresh: true);
  }

  Future<void> onLoadMore() async {
    if (isLoadingMore.value || !hasMore) return;

    isLoadingMore.value = true;
    await queryData();
    isLoadingMore.value = false;
  }
}
