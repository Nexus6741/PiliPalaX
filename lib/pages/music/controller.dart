import 'package:flutter/material.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/http/music.dart';
import 'package:PiliPalaX/models/music/bgm_detail.dart';
import 'package:PiliPalaX/plugin/pl_player/index.dart';
import 'package:get/get.dart';

/// 音乐详情页控制器
class MusicDetailController extends GetxController {
  final ScrollController scrollController = ScrollController();
  final infoState = LoadingState<MusicDetail>.loading().obs;
  final showTitle = false.obs;

  late final String musicId;

  String get shareUrl =>
      'https://music.bilibili.com/h5/music-detail?music_id=$musicId';

  @override
  void onInit() {
    super.onInit();
    musicId = Get.parameters['musicId']!;
    
    // 暂停正在播放的视频，避免冲突
    PlPlayerController.pauseIfExists();
    
    getMusicDetail();

    // 监听滚动，控制标题显示
    scrollController.addListener(() {
      if (scrollController.hasClients) {
        final offset = scrollController.offset;
        showTitle.value = offset > 100;
      }
    });
  }

  /// 获取音乐详情
  Future<void> getMusicDetail() async {
    infoState.value = LoadingState.loading();
    final res = await MusicHttp.bgmDetail(musicId);
    infoState.value = res;
  }

  /// 刷新
  Future<void> onRefresh() async {
    await getMusicDetail();
  }

  /// 重新加载
  Future<void> onReload() async {
    await getMusicDetail();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
