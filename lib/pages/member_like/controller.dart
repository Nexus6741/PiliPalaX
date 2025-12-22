import 'package:get/get.dart';
import 'package:PiliPalaX/http/member.dart';
import 'package:PiliPalaX/models/member/space_data.dart';

class MemberLikeController extends GetxController {
  final int mid;
  MemberLikeController({required this.mid});

  RxList<SpaceArchiveItem> likeList = <SpaceArchiveItem>[].obs;
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
      likeList.clear();
    }

    isLoading.value = true;
    loadingText.value = '加载中...';

    try {
      var res = await MemberHttp.spaceLikeArc(
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
            likeList.value = newItems;
          } else {
            likeList.addAll(newItems);
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
