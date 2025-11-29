import 'dart:math';

import 'package:PiliPalaX/common/constants.dart';
import 'package:PiliPalaX/utils/extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:PiliPalaX/http/video.dart';
import 'package:PiliPalaX/models/home/rcmd/result.dart';
import 'package:PiliPalaX/models/model_rec_video_item.dart';
import 'package:PiliPalaX/utils/storage.dart';

class RcmdController extends GetxController {
  final ScrollController scrollController = ScrollController();
  int _currentPage = 0;
  // RxList<RecVideoItemAppModel> appVideoList = <RecVideoItemAppModel>[].obs;
  // RxList<RecVideoItemModel> webVideoList = <RecVideoItemModel>[].obs;
  List<OverlayEntry?> popupDialog = <OverlayEntry?>[];
  Box setting = GStorage.setting;
  RxInt crossAxisCount = 2.obs;
  late bool enableSaveLastData;
  late String defaultRcmdType = 'web';
  late RxList<dynamic> videoList;

  @override
  void onInit() {
    super.onInit();
    enableSaveLastData =
        setting.get(SettingBoxKey.enableSaveLastData, defaultValue: false);
    defaultRcmdType =
        setting.get(SettingBoxKey.defaultRcmdType, defaultValue: 'web');
    if (defaultRcmdType == 'web') {
      videoList = <RecVideoItemModel>[].obs;
    } else {
      videoList = <RecVideoItemAppModel>[].obs;
    }
  }

  // 获取推荐
  Future queryRcmdFeed(type) async {
    if (type == 'onRefresh') {
      _currentPage = 0;
      // 重新读取配置
      enableSaveLastData =
          setting.get(SettingBoxKey.enableSaveLastData, defaultValue: false);
    }
    late final Map<String, dynamic> res;
    switch (defaultRcmdType) {
      case 'app':
      case 'notLogin':
        res = await VideoHttp.rcmdVideoListApp(
          loginStatus: defaultRcmdType != 'notLogin',
          freshIdx: _currentPage,
        );
        break;
      default: //'web'
        res = await VideoHttp.rcmdVideoList(
          freshIdx: _currentPage,
          ps: 20,
        );
    }
    if (res['status']) {
      if (type == 'init') {
        if (videoList.isNotEmpty) {
          videoList.addAll(res['data']);
        } else {
          videoList.value = res['data'];
        }
      } else if (type == 'onRefresh') {
        if (enableSaveLastData) {
          // 计算列数
          double maxRowWidth =
              setting.get(SettingBoxKey.maxRowWidth, defaultValue: 240.0);
          // 减去左右 margin
          double screenWidth = Get.width - StyleString.safeSpace * 2;
          int crossAxisCount = ((screenWidth - StyleString.cardSpace) /
                  (maxRowWidth + StyleString.cardSpace))
              .ceil();
          crossAxisCount = max(1, crossAxisCount);

          // 保留前N行
          int keepLines =
              setting.get(SettingBoxKey.rcmdKeepLines, defaultValue: 2);
          int count = crossAxisCount * keepLines;

          List<dynamic> keptItems = [];
          if (videoList.length >= count) {
            keptItems = videoList.sublist(0, count);
          } else {
            keptItems = List.from(videoList);
          }

          // 标记为保留项
          for (var item in keptItems) {
            item.isKeep = true;
          }

          var newItems = res['data'];
          // 插入到新数据的前两行之后
          if (newItems.length >= count) {
            newItems.insertAll(count, keptItems);
          } else {
            newItems.addAll(keptItems);
          }
          videoList.value = newItems;
        } else {
          videoList.value = res['data'];
        }
      } else if (type == 'onLoad') {
        videoList.addAll(res['data']);
      }
      _currentPage += 1;
      // 若videoList数量太小，可能会影响翻页，此时再次请求
      // 为避免请求到的数据太少时还在反复请求，要求本次返回数据大于1条才触发
      if (res['data'].length > 1 && videoList.length < 24) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (videoList.length < 24) queryRcmdFeed('onLoad');
        });
      }
      if (res['data'].length < 5) {
        SmartDialog.showToast("仅请求到${res['data'].length}条");
      }
    } else {
      SmartDialog.showToast("${res['msg']}，请尝试(重新)登录");
    }
    return res;
  }

  // 下拉刷新
  Future onRefresh() async {
    queryRcmdFeed('onRefresh');
  }

  // 上拉加载
  Future onLoad() async {
    queryRcmdFeed('onLoad');
  }

  // 返回顶部
  void animateToTop() {
    scrollController.animToTop();
  }
}
