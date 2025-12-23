import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/http/user.dart';
import 'package:PiliPalaX/http/video.dart';
import 'package:PiliPalaX/models/user/fav_detail.dart';
import 'package:PiliPalaX/models/user/fav_folder.dart';
import 'package:PiliPalaX/utils/utils.dart';

class FavDetailController extends GetxController {
  FavFolderItemData? item;
  Rx<FavDetailData> favDetailData = FavDetailData().obs;

  int? mediaId;
  late String heroTag;
  int currentPage = 1;
  bool isLoadingMore = false;
  RxMap favInfo = {}.obs;
  RxList favList = [].obs;
  RxString loadingText = '加载中...'.obs;
  int mediaCount = 0;

  @override
  void onInit() {
    item = Get.arguments;
    if (Get.parameters.keys.isNotEmpty) {
      mediaId = int.tryParse(Get.parameters['mediaId'] ?? '');
      // 安全获取 heroTag，如果没有则生成一个
      heroTag = Get.parameters['heroTag'] ?? Utils.makeHeroTag(mediaId);
    }
    super.onInit();
  }

  Future<dynamic> queryUserFavFolderDetail({type = 'init'}) async {
    // print('=== queryUserFavFolderDetail ===');
    // print('type: $type');
    // print('mediaId: $mediaId');
    // print('currentPage: $currentPage');
    // print('mediaCount: $mediaCount');
    // print('favList.length: ${favList.length}');

    if (type == 'onLoad' && favList.length >= mediaCount) {
      loadingText.value = '没有更多了';
      // print('Already loaded all, returning early');
      return {'status': true, 'msg': 'no more data'};
    }
    if (mediaId == null) {
      // print('mediaId is null, returning error');
      return {'status': false, 'msg': 'mediaId is null'};
    }
    isLoadingMore = true;
    var res = await UserHttp.userFavFolderDetail(
      pn: currentPage,
      ps: 20,
      mediaId: mediaId!,
    );
    // print('API response: ${res['status']}');
    // print('API data type: ${res['data']?.runtimeType}');

    if (res['status']) {
      // print('res[data].info: ${res['data'].info}');
      // print('res[data].medias: ${res['data'].medias}');
      // print('res[data].medias length: ${res['data'].medias?.length}');

      favInfo.value = res['data'].info;
      if (currentPage == 1 && type == 'init') {
        favList.value = res['data'].medias ?? [];
        mediaCount = res['data'].info['media_count'] ?? 0;
        // print(
        // 'Init: favList.length = ${favList.length}, mediaCount = $mediaCount');
      } else if (type == 'onLoad') {
        favList.addAll(res['data'].medias ?? []);
        // print('OnLoad: favList.length = ${favList.length}');
      }
      if (favList.length >= mediaCount) {
        loadingText.value = '没有更多了';
        // print('All loaded, setting loadingText to 没有更多了');
      }
    } else {
      // print('API failed: ${res['msg']}');
    }
    currentPage += 1;
    isLoadingMore = false;
    // print('Returning res: $res');
    return res;
  }

  onCancelFav(int id) async {
    var result = await VideoHttp.favVideo(
        aid: id, addIds: '', delIds: mediaId.toString());
    if (result['status']) {
      List dataList = favList;
      for (var i in dataList) {
        if (i.id == id) {
          dataList.remove(i);
          break;
        }
      }
      SmartDialog.showToast('取消收藏');
    }
  }

  onLoad() {
    queryUserFavFolderDetail(type: 'onLoad');
  }
}
