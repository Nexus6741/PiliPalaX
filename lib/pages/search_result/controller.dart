import 'package:get/get.dart';

class SearchResultController extends GetxController {
  String? keyword;
  String? searchType; // 保存原始的搜索类型
  int tabIndex = 0;

  @override
  void onInit() {
    super.onInit();
    if (Get.parameters.keys.isNotEmpty) {
      keyword = Get.parameters['keyword'];
      searchType = Get.parameters['searchType']; // 保存搜索类型
    }
  }
}
