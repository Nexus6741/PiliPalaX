import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/http/music.dart';
import 'package:PiliPalaX/models/music/bgm_detail.dart';
import 'package:PiliPalaX/models/music/bgm_recommend_list.dart';
import 'package:PiliPalaX/pages/common/common_controller.dart';
import 'package:PiliPalaX/plugin/pl_player/index.dart';
import 'package:get/get.dart';

/// 音乐推荐视频控制器
class MusicRecommendController
    extends CommonListController<List<BgmRecommend>?, BgmRecommend> {
  late final String musicId;
  late final MusicDetail musicDetail;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    musicId = args['musicId'];
    musicDetail = args['musicDetail'];
    
    // 暂停正在播放的视频，避免冲突
    PlPlayerController.pauseIfExists();
    
    queryData();
  }

  @override
  void checkIsEnd(int length) {
    isEnd = true; // 音乐推荐列表一次性返回所有数据
  }

  @override
  List<BgmRecommend>? getDataList(List<BgmRecommend>? response) {
    return response;
  }

  @override
  Future<LoadingState<List<BgmRecommend>?>> customGetData() async {
    final result = await MusicHttp.bgmRecommend(musicId);
    return result;
  }
}
