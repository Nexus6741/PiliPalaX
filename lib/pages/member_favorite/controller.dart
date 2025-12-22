import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/http/user.dart';
import 'package:PiliPalaX/models/space_fav/space_fav_data.dart';
import 'package:PiliPalaX/utils/storage.dart';

class MemberFavoriteController extends GetxController {
  final int mid;

  MemberFavoriteController({required this.mid});

  RxBool isLoading = true.obs;
  RxString errorMsg = ''.obs;

  // 创建的收藏夹
  Rx<SpaceFavData> favState = SpaceFavData().obs;
  RxBool favExpanded = true.obs;
  RxBool favEnd = true.obs;
  int favPage = 2;

  // 订阅的收藏夹
  Rx<SpaceFavData> subState = SpaceFavData().obs;
  RxBool subExpanded = true.obs;
  RxBool subEnd = true.obs;
  int subPage = 2;

  // 是否是当前登录用户
  bool get isOwner {
    var userInfo = GStorage.userInfo.get('userInfoCache');
    return userInfo != null && userInfo.mid == mid;
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      errorMsg.value = '';

      var res = await UserHttp.spaceFav(mid: mid);

      if (res['status']) {
        final data = res['data'] as List?;
        if (data != null && data.isNotEmpty) {
          // 第一个是创建的收藏夹
          favState.value = SpaceFavData.fromJson(data[0]);
          favEnd.value = (favState.value.mediaListResponse?.count ?? -1) <=
              (favState.value.mediaListResponse?.list?.length ?? -1);

          // 第二个是订阅的收藏夹（如果有）
          if (data.length > 1) {
            subState.value = SpaceFavData.fromJson(data[1]);
            subEnd.value = (subState.value.mediaListResponse?.count ?? -1) <=
                (subState.value.mediaListResponse?.list?.length ?? -1);
          }
        }
      } else {
        errorMsg.value = res['msg'] ?? '加载失败';
      }
    } catch (e) {
      errorMsg.value = '加载失败: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onRefresh() async {
    favPage = 2;
    subPage = 2;
    await loadData();
  }

  void toggleFavExpanded() {
    favExpanded.value = !favExpanded.value;
  }

  void toggleSubExpanded() {
    subExpanded.value = !subExpanded.value;
  }

  // 加载更多创建的收藏夹
  Future<void> loadMoreFav() async {
    try {
      var res = await UserHttp.userfavFolder(pn: favPage, ps: 20, mid: mid);
      if (res['status']) {
        favPage++;
        final data = res['data'];
        if (data != null && data.list != null && data.list!.isNotEmpty) {
          // 转换为 SpaceFavItemModel
          final newItems = data.list!.map((item) {
            return SpaceFavItemModel(
              id: item.id,
              mediaId: item.id,
              title: item.title,
              cover: item.cover,
              mediaCount: item.mediaCount,
              mid: item.mid,
              attr: item.attr,
              intro: item.intro,
            );
          }).toList();
          favState.value.mediaListResponse?.list?.addAll(newItems);
          favState.refresh();
          // 检查是否还有更多
          favEnd.value =
              (favState.value.mediaListResponse?.list?.length ?? 0) >=
                  (favState.value.mediaListResponse?.count ?? 0);
        } else {
          favEnd.value = true;
        }
      } else {
        SmartDialog.showToast(res['msg'] ?? '加载失败');
      }
    } catch (e) {
      SmartDialog.showToast('加载失败: $e');
    }
  }

  // 加载更多订阅的收藏夹
  Future<void> loadMoreSub() async {
    try {
      var res = await UserHttp.userSubFolder(mid: mid, pn: subPage, ps: 20);
      if (res['status']) {
        subPage++;
        final data = res['data'];
        if (data != null && data.list != null && data.list!.isNotEmpty) {
          // 转换为 SpaceFavItemModel
          final newItems = data.list!.map((item) {
            return SpaceFavItemModel(
              id: item.id,
              mediaId: item.id,
              title: item.title,
              cover: item.cover,
              mediaCount: item.mediaCount,
              mid: item.mid,
              type: item.type,
              upper: item.upper != null
                  ? SpaceFavUpper(
                      mid: item.upper!.mid,
                      name: item.upper!.name,
                      face: item.upper!.face,
                    )
                  : null,
            );
          }).toList();
          subState.value.mediaListResponse?.list?.addAll(newItems);
          subState.refresh();
          // 检查是否还有更多
          subEnd.value =
              (subState.value.mediaListResponse?.list?.length ?? 0) >=
                  (subState.value.mediaListResponse?.count ?? 0);
        } else {
          subEnd.value = true;
        }
      } else {
        SmartDialog.showToast(res['msg'] ?? '加载失败');
      }
    } catch (e) {
      SmartDialog.showToast('加载失败: $e');
    }
  }
}
