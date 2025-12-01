import 'package:get/get.dart';
import 'package:PiliPalaX/http/constants.dart';
import 'package:PiliPalaX/http/live.dart';
import 'package:PiliPalaX/models/live/room_info.dart';
import 'package:PiliPalaX/plugin/pl_player/index.dart';
import 'package:PiliPalaX/utils/storage.dart';
import '../../models/live/room_info_h5.dart';
import '../../utils/video_utils.dart';

class LiveRoomController extends GetxController {
  String cover = '';
  late int roomId;
  dynamic liveItem;
  late String heroTag;
  double volume = 0.0;
  // 静音状态
  RxBool volumeOff = false.obs;
  PlPlayerController plPlayerController =
      PlPlayerController.getInstance(videoType: 'live');
  Rx<RoomInfoH5Model> roomInfoH5 = RoomInfoH5Model().obs;
  // late bool enableCDN;

  RxInt currentQn = 10000.obs;
  RxString currentQnDesc = '原画'.obs;
  RxList<Map> acceptQnList = <Map>[].obs;

  bool get isLogin => GStorage.userInfo.get('userInfoCache') != null;

  @override
  void onInit() {
    super.onInit();
    roomId = int.parse(Get.parameters['roomid']!);
    if (Get.arguments != null) {
      liveItem = Get.arguments['liveItem'];
      heroTag = Get.arguments['heroTag'] ?? '';
      if (liveItem != null && liveItem.pic != null && liveItem.pic != '') {
        cover = liveItem.pic;
      }
      if (liveItem != null && liveItem.cover != null && liveItem.cover != '') {
        cover = liveItem.cover;
      }
    }
    // CDN优化
    // enableCDN = setting.get(SettingBoxKey.enableCDN, defaultValue: true);
  }

  playerInit(source) async {
    await plPlayerController.setDataSource(
      DataSource(
        videoSource: source,
        audioSource: null,
        type: DataSourceType.network,
        httpHeaders: {
          'user-agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 13_3_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15',
          'referer': HttpString.baseUrl
        },
      ),
      // 硬解
      enableHA: true,
      autoplay: true,
    );
  }

  Future queryLiveInfo() async {
    var res = await LiveHttp.liveRoomInfo(roomId: roomId, qn: currentQn.value);
    if (res['status']) {
      List<GQnDesc> qnDesc = res['data'].playurlInfo.playurl.gQnDesc;
      acceptQnList.value =
          qnDesc.map((e) => {'code': e.qn, 'desc': e.desc}).toList();
      var current = qnDesc.firstWhere((e) => e.qn == currentQn.value,
          orElse: () => qnDesc.first);
      currentQnDesc.value = current.desc!;

      List<CodecItem> codec =
          res['data'].playurlInfo.playurl.stream.first.format.first.codec;
      CodecItem item = codec.first;
      String videoUrl = VideoUtils.getCdnUrl(item);
      await playerInit(videoUrl);
      return res;
    }
  }

  void changeQn(int quality) {
    currentQn.value = quality;
    queryLiveInfo();
  }

  void setVolume(value) {
    if (value == 0) {
      // 设置音量
      volumeOff.value = false;
    } else {
      // 取消音量
      volume = value;
      volumeOff.value = true;
    }
  }

  Future queryLiveInfoH5() async {
    var res = await LiveHttp.liveRoomInfoH5(roomId: roomId);
    if (res['status']) {
      roomInfoH5.value = res['data'];
    }
    return res;
  }
}
