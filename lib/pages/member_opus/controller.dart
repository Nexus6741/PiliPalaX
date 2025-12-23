import 'package:get/get.dart';
import 'package:PiliPalaX/http/member.dart';
import 'package:PiliPalaX/models/space_opus/space_opus_item.dart';

class MemberOpusController extends GetxController {
  MemberOpusController({required this.mid});

  final int mid;
  int page = 1;
  String offset = '';
  RxBool isLoading = true.obs;
  RxBool isLoadingMore = false.obs;
  RxBool hasMore = true.obs;
  RxList<SpaceOpusItem> opusList = <SpaceOpusItem>[].obs;
  RxString errorMsg = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    // print('========== MemberOpus loadData ==========');
    // print('Page: $page');
    // print('Offset: $offset');
    // print('Current list length: ${opusList.length}');
    // print('=========================================');

    if (page == 1) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }
    errorMsg.value = '';

    try {
      var res = await MemberHttp.memberOpus(
        hostMid: mid,
        page: page,
        offset: offset,
      );

      if (res['status']) {
        final data = res['data'];
        offset = data['offset'] ?? '';
        hasMore.value = data['has_more'] == true;

        // 解析为SpaceOpusItem列表
        final List<dynamic> rawItems = data['items'] ?? [];
        final List<SpaceOpusItem> items = rawItems
            .map((e) => SpaceOpusItem.fromJson(e as Map<String, dynamic>))
            .toList();

        // print('========== MemberOpus loadData Response ==========');
        // print('Items count: ${items.length}');
        // print('Has more: ${hasMore.value}');
        // print('New offset: $offset');
        // print('Will replace list: ${page == 1}');
        // print('==================================================');

        if (page == 1) {
          opusList.value = items;
        } else {
          opusList.addAll(items);
        }

        // print('Final list length: ${opusList.length}');
      } else {
        errorMsg.value = res['msg'] ?? '加载失败';
      }
    } catch (e) {
      errorMsg.value = '加载失败: $e';
      // print('MemberOpus loadData error: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> onRefresh() async {
    // print('========== MemberOpus onRefresh called ==========');
    page = 1;
    offset = '';
    hasMore.value = true;
    await loadData();
  }

  Future<void> onLoadMore() async {
    // print('========== MemberOpus onLoadMore called ==========');
    // print('isLoadingMore: ${isLoadingMore.value}');
    // print('isLoading: ${isLoading.value}');
    // print('hasMore: ${hasMore.value}');
    // print('==================================================');

    if (isLoadingMore.value || isLoading.value || !hasMore.value) {
      // print('Skipping onLoadMore: already loading or no more data');
      return;
    }
    page++;
    await loadData();
  }
}
