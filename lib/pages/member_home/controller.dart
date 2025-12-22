import 'package:get/get.dart';
import 'package:PiliPalaX/models/member/space_data.dart';
import 'package:PiliPalaX/pages/member/controller.dart';

class MemberHomeController extends GetxController {
  final String heroTag;
  late final MemberController memberController;

  MemberHomeController({required this.heroTag});

  @override
  void onInit() {
    super.onInit();
    memberController = Get.find<MemberController>(tag: heroTag);
  }

  // 获取空间数据
  SpaceData? get spaceData => memberController.spaceData.value;

  // 是否为自己的空间
  bool get isOwner => memberController.ownerMid == memberController.mid;

  // 跳转到投稿Tab
  void toContributeTab({String? subTab}) {
    final tab2 = memberController.tab2;
    if (tab2 == null) return;

    int index = tab2.indexWhere((tab) => tab.param == 'contribute');
    if (index != -1) {
      memberController.tabController.animateTo(index);
    }
  }

  // 跳转到收藏Tab
  void toFavoriteTab() {
    final tab2 = memberController.tab2;
    if (tab2 == null) return;

    int index = tab2.indexWhere((tab) => tab.param == 'favorite');
    if (index != -1) {
      memberController.tabController.animateTo(index);
    }
  }

  // 跳转到追番Tab
  void toBangumiTab() {
    final tab2 = memberController.tab2;
    if (tab2 == null) return;

    int index = tab2.indexWhere((tab) => tab.param == 'bangumi');
    if (index != -1) {
      memberController.tabController.animateTo(index);
    }
  }
}
