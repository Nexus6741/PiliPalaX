import 'package:get/get.dart';
import 'package:PiliPalaX/http/bangumi.dart';
import 'package:PiliPalaX/models/bangumi/list.dart';

class MemberBangumiController extends GetxController {
  final int mid;

  MemberBangumiController({required this.mid});

  int pn = 1;
  RxBool isLoading = true.obs;
  RxBool isLoadingMore = false.obs;
  RxBool hasMore = true.obs;
  RxString errorMsg = ''.obs;
  Rx<BangumiListDataModel?> bangumiData = Rx<BangumiListDataModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      if (pn == 1) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }
      errorMsg.value = '';

      var res = await BangumiHttp.bangumiFollow(mid: mid, pn: pn);

      if (res['status']) {
        final data = res['data'] as BangumiListDataModel;
        if (pn == 1) {
          bangumiData.value = data;
        } else {
          // 追加数据
          bangumiData.value?.list?.addAll(data.list ?? []);
          bangumiData.refresh();
        }
        // 检查是否还有更多
        hasMore.value = (data.list?.length ?? 0) >= 15;
        pn++;
      } else {
        errorMsg.value = res['msg'] ?? '加载失败';
      }
    } catch (e) {
      errorMsg.value = '加载失败: $e';
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> onRefresh() async {
    pn = 1;
    hasMore.value = true;
    await loadData();
  }

  Future<void> onLoadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    await loadData();
  }
}
