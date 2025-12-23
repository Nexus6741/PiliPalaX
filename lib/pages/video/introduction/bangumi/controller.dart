import 'package:PiliPalaX/plugin/pl_player/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:PiliPalaX/http/constants.dart';
import 'package:PiliPalaX/http/search.dart';
import 'package:PiliPalaX/http/video.dart';
import 'package:PiliPalaX/models/bangumi/info.dart';
import 'package:PiliPalaX/models/download/download_entry_info.dart';
import 'package:PiliPalaX/models/user/fav_folder.dart';
import 'package:PiliPalaX/models/video/play/quality.dart';
import 'package:PiliPalaX/models/video/play/url.dart';
import 'package:PiliPalaX/pages/video/index.dart';
import 'package:PiliPalaX/pages/video/reply/index.dart';
import 'package:PiliPalaX/pages/video/widgets/batch_download_panel.dart';
import 'package:PiliPalaX/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPalaX/services/download_service.dart';
import 'package:PiliPalaX/utils/feed_back.dart';
import 'package:PiliPalaX/utils/id_utils.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:PiliPalaX/services/service_locator.dart';

class BangumiIntroController extends GetxController {
  // 视频bvid
  String bvid = Get.parameters['bvid']!;
  var seasonId = Get.parameters['seasonId'] != null
      ? int.parse(Get.parameters['seasonId']!)
      : null;
  var epId = Get.parameters['epId'] != null
      ? int.tryParse(Get.parameters['epId']!)
      : null;
  String heroTag = Get.arguments['heroTag'];

  // 是否预渲染 骨架屏
  bool preRender = false;

  // 视频详情 上个页面传入
  Map? videoItem = {};
  BangumiInfoModel? bangumiItem;

  // 请求状态
  RxBool isLoading = false.obs;

  // 视频详情 请求返回
  Rx<BangumiInfoModel> bangumiDetail = BangumiInfoModel().obs;

  // 请求返回的信息
  String responseMsg = '请求异常';

  // up主粉丝数
  Map userStat = {'follower': '-'};

  // 是否点赞
  RxBool hasLike = false.obs;
  // 是否投币
  RxBool hasCoin = false.obs;
  // 是否收藏
  RxBool hasFav = false.obs;
  Box userInfoCache = GStorage.userInfo;
  bool userLogin = false;
  Rx<FavFolderData> favFolderData = FavFolderData().obs;
  List addMediaIdsNew = [];
  List delMediaIdsNew = [];
  // 关注状态 默认未关注
  RxMap followStatus = {}.obs;
  int _tempThemeValue = -1;
  RxInt lastPlayCid = Get.parameters['cid'] != null
      ? int.tryParse(Get.parameters['cid']!)!.obs
      : 0.obs;
  var userInfo;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments.isNotEmpty as bool) {
      if (Get.arguments.containsKey('bangumiItem') as bool) {
        preRender = true;
        bangumiItem = Get.arguments['bangumiItem'];
        // bangumiItem!['pic'] = args.pic;
        // if (args.title is String) {
        //   videoItem!['title'] = args.title;
        // } else {
        //   String str = '';
        //   for (Map map in args.title) {
        //     str += map['text'];
        //   }
        //   videoItem!['title'] = str;
        // }
        // if (args.stat != null) {
        //   videoItem!['stat'] = args.stat;
        // }
        // videoItem!['pubdate'] = args.pubdate;
        // videoItem!['owner'] = args.owner;
      }
    }
    userInfo = userInfoCache.get('userInfoCache');
    userLogin = userInfo != null;
    bangumiDetail.listen((value) {
      final VideoDetailController videoDetailCtr =
          Get.find<VideoDetailController>(tag: heroTag);
      final cid = videoDetailCtr.cid.value;
      final current =
          value.episodes?.firstWhere((element) => element.cid == cid);

      videoPlayerServiceHandler.onVideoDetailChange(
        current?.longTitle ?? "",
        value.title ?? "",
        Duration(milliseconds: current?.duration ?? 0),
        value.cover ?? "",
      );
    });
  }

  void openVideoDetail() {
    Get.toNamed(
        '/video?bvid=$bvid&cid=${lastPlayCid.value}&seasonId=$seasonId&epId=$epId&resume=true');
  }

  // 获取番剧简介&选集
  Future queryBangumiIntro() async {
    if (userLogin) {
      // 获取点赞状态
      queryHasLikeVideo();
      // 获取投币状态
      queryHasCoinVideo();
      // 获取收藏状态
      queryHasFavVideo();
    }
    var result = await SearchHttp.bangumiInfo(seasonId: seasonId, epId: epId);
    if (result['status']) {
      bangumiDetail.value = result['data'];
      epId = bangumiDetail.value.episodes!.first.id;

      // 🔍 调试日志：查看番剧详情中的type字段
      print('🔍 [queryBangumiIntro] 番剧详情获取成功:');
      print('   - seasonId: ${bangumiDetail.value.seasonId}');
      print('   - title: ${bangumiDetail.value.title}');
      print('   - type: ${bangumiDetail.value.type}');
      print('   - 类型说明: 1=番剧, 2=电影, 3=纪录片, 4=国创, 5=电视剧, 7=综艺');
    } else {
      SmartDialog.showToast(result['msg']);
    }
    return result;
  }

  // 获取点赞状态
  Future queryHasLikeVideo() async {
    var result = await VideoHttp.hasLikeVideo(bvid: bvid);
    // data	num	被点赞标志	0：未点赞  1：已点赞
    hasLike.value = result["data"] == 1 ? true : false;
  }

  // 获取投币状态
  Future queryHasCoinVideo() async {
    var result = await VideoHttp.hasCoinVideo(bvid: bvid);
    hasCoin.value = result["data"]['multiply'] == 0 ? false : true;
  }

  // 获取收藏状态
  Future queryHasFavVideo() async {
    var result = await VideoHttp.hasFavVideo(aid: IdUtils.bv2av(bvid));
    if (result['status']) {
      hasFav.value = result["data"]['favoured'];
    } else {
      hasFav.value = false;
    }
  }

  // （取消）点赞
  Future actionLikeVideo() async {
    var result = await VideoHttp.likeVideo(bvid: bvid, type: !hasLike.value);
    if (result['status']) {
      SmartDialog.showToast(!hasLike.value ? result['data']['toast'] : '取消赞');
      hasLike.value = !hasLike.value;
      bangumiDetail.value.stat!['likes'] =
          bangumiDetail.value.stat!['likes'] + (!hasLike.value ? 1 : -1);
      hasLike.refresh();
    } else {
      SmartDialog.showToast(result['msg']);
    }
  }

  // 投币
  Future actionCoinVideo() async {
    if (userInfo == null) {
      SmartDialog.showToast('账号未登录');
      return;
    }
    showDialog(
        context: Get.context!,
        builder: (context) {
          return AlertDialog(
            title: const Text('选择投币个数'),
            contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
            content: StatefulBuilder(builder: (context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                    value: 1,
                    title: const Text('1枚'),
                    groupValue: _tempThemeValue,
                    onChanged: (value) {
                      _tempThemeValue = value!;
                      Get.appUpdate();
                    },
                  ),
                  RadioListTile(
                    value: 2,
                    title: const Text('2枚'),
                    groupValue: _tempThemeValue,
                    onChanged: (value) {
                      _tempThemeValue = value!;
                      Get.appUpdate();
                    },
                  ),
                ],
              );
            }),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('取消')),
              TextButton(
                  onPressed: () async {
                    var res = await VideoHttp.coinVideo(
                        bvid: bvid, multiply: _tempThemeValue);
                    if (res['status']) {
                      SmartDialog.showToast('投币成功');
                      hasCoin.value = true;
                      bangumiDetail.value.stat!['coins'] =
                          bangumiDetail.value.stat!['coins'] + _tempThemeValue;
                    } else {
                      SmartDialog.showToast(res['msg']);
                    }
                    Get.back();
                  },
                  child: const Text('确定'))
            ],
          );
        });
  }

  // （取消）收藏
  Future actionFavVideo() async {
    try {
      for (var i in favFolderData.value.list!.toList()) {
        if (i.favState == 1) {
          addMediaIdsNew.add(i.id);
        } else {
          delMediaIdsNew.add(i.id);
        }
      }
    } catch (_) {}
    var result = await VideoHttp.favVideo(
        aid: IdUtils.bv2av(bvid),
        addIds: addMediaIdsNew.join(','),
        delIds: delMediaIdsNew.join(','));
    if (result['status']) {
      addMediaIdsNew = [];
      delMediaIdsNew = [];
      // 重新获取收藏状态
      queryHasFavVideo();
      SmartDialog.showToast('操作成功');
      Get.back();
    }
  }

  // 分享视频
  Future actionShareVideo() async {
    showDialog(
        context: Get.context!,
        builder: (context) {
          String videoUrl = '${HttpString.baseUrl}/video/$bvid';
          return AlertDialog(
            title: const Text('请选择'),
            actions: [
              TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: videoUrl));
                    SmartDialog.showToast('已复制');
                  },
                  child: const Text('复制链接到剪贴板')),
              TextButton(
                  onPressed: () {
                    launchUrl(
                      Uri.parse(videoUrl),
                      mode: LaunchMode.externalApplication,
                      webViewConfiguration: WebViewConfiguration(
                        headers: {
                          'harmony_browser_page': 'pages/LaunchInAppPage'
                        },
                      ),
                    );
                  },
                  child: const Text('其它app打开')),
              TextButton(
                  onPressed: () async {
                    await Share.share(videoUrl).whenComplete(() {});
                  },
                  child: const Text('分享视频')),
            ],
          );
        });
  }

  // 选择文件夹
  onChoose(bool checkValue, int index) {
    feedBack();
    List<FavFolderItemData> datalist = favFolderData.value.list!;
    for (var i = 0; i < datalist.length; i++) {
      if (i == index) {
        datalist[i].favState = checkValue == true ? 1 : 0;
        datalist[i].mediaCount = checkValue == true
            ? datalist[i].mediaCount! + 1
            : datalist[i].mediaCount! - 1;
      }
    }
    favFolderData.value.list = datalist;
    favFolderData.refresh();
  }

  // 修改分P或番剧分集
  Future changeSeasonOrbangu(bvid, cid, aid,
      {int? epid, bool useHistory = false}) async {
    // 重新获取视频资源
    VideoDetailController videoDetailCtr =
        Get.find<VideoDetailController>(tag: heroTag);

    // 暂停当前播放
    if (videoDetailCtr.plPlayerController != null) {
      videoDetailCtr.plPlayerController!.pause();
    }

    videoDetailCtr.bvid = bvid;
    videoDetailCtr.cid.value = cid;
    videoDetailCtr.danmakuCid.value = cid;

    // 更新 epId（如果提供了）
    if (epid != null) {
      epId = epid;
    }

    // 🔥 修复：根据 useHistory 参数决定播放位置
    // useHistory = true: 使用历史记录位置（首次打开或自动跳转）
    // useHistory = false: 从头播放（手动切换选集）
    if (useHistory) {
      videoDetailCtr.defaultST = null; // 使用历史记录
    } else {
      videoDetailCtr.defaultST = Duration.zero; // 从头播放
    }

    videoDetailCtr.queryVideoUrl();
    lastPlayCid.value = cid;
    // 触发媒体通知更新
    bangumiDetail.refresh();
    // 重新请求评论
    try {
      /// 未渲染回复组件时可能异常
      VideoReplyController videoReplyCtr =
          Get.find<VideoReplyController>(tag: heroTag);
      videoReplyCtr.aid = aid;
      videoReplyCtr.queryReplyList(type: 'init');
    } catch (_) {}
  }

  // 追番
  Future bangumiAdd() async {
    var result =
        await VideoHttp.bangumiAdd(seasonId: bangumiDetail.value.seasonId);
    SmartDialog.showToast(result['msg']);
  }

  // 取消追番
  Future bangumiDel() async {
    var result =
        await VideoHttp.bangumiDel(seasonId: bangumiDetail.value.seasonId);
    SmartDialog.showToast(result['msg']);
  }

  Future queryVideoInFolder() async {
    var result = await VideoHttp.videoInFolder(
        mid: userInfo.mid, rid: IdUtils.bv2av(bvid));
    if (result['status']) {
      favFolderData.value = result['data'];
    }
    return result;
  }

  bool prevPlay() {
    late List episodes;
    if (bangumiDetail.value.episodes != null) {
      episodes = bangumiDetail.value.episodes!;
    }
    int currentIndex = episodes.indexWhere((e) => e.cid == lastPlayCid.value);
    int prevIndex = currentIndex - 1;
    PlayRepeat playRepeat = PlPlayerController.getInstance().playRepeat;
    if (prevIndex < 0) {
      if (playRepeat == PlayRepeat.listCycle) {
        prevIndex = episodes.length - 1;
      } else {
        return false;
      }
    }
    int cid = episodes[prevIndex].cid!;
    String bvid = episodes[prevIndex].bvid!;
    int aid = episodes[prevIndex].aid!;
    int? epid = episodes[prevIndex].id;
    changeSeasonOrbangu(bvid, cid, aid, epid: epid);
    return true;
  }

  bool hasNextEpisode() {
    late List episodes;
    if (bangumiDetail.value.episodes == null) {
      return false;
    }
    episodes = bangumiDetail.value.episodes!;
    PlayRepeat playRepeat = PlPlayerController.getInstance().playRepeat;
    if (playRepeat == PlayRepeat.listCycle) {
      return true;
    }
    int currentIndex = episodes.indexWhere((e) => e.cid == lastPlayCid.value);
    return currentIndex < episodes.length - 1;
  }

  /// 列表循环或者顺序播放时，自动播放下一个；自动连播时，播放相关视频
  bool nextPlay() {
    late List episodes;
    PlayRepeat playRepeat = PlPlayerController.getInstance().playRepeat;

    if (bangumiDetail.value.episodes != null) {
      episodes = bangumiDetail.value.episodes!;
    } else {
      if (playRepeat == PlayRepeat.autoPlayRelated) {
        return playRelated();
      }
      return false;
    }

    int currentIndex = episodes.indexWhere((e) => e.cid == lastPlayCid.value);

    // 如果找不到当前集数，返回false
    if (currentIndex == -1) {
      return false;
    }

    int nextIndex = currentIndex + 1;

    // 🔥 修复：检查是否已经是最后一集
    if (nextIndex >= episodes.length) {
      // 已经是最后一集
      if (playRepeat == PlayRepeat.listCycle) {
        // 列表循环，回到第一集
        nextIndex = 0;
      } else if (playRepeat == PlayRepeat.autoPlayRelated) {
        // 自动连播相关视频
        return playRelated();
      } else {
        // 顺序播放或暂停，停止播放
        return false;
      }
    }

    int cid = episodes[nextIndex].cid!;
    String bvid = episodes[nextIndex].bvid!;
    int aid = episodes[nextIndex].aid!;
    int? epid = episodes[nextIndex].id;
    changeSeasonOrbangu(bvid, cid, aid, epid: epid);
    return true;
  }

  bool playRelated() {
    SmartDialog.showToast('番剧暂无相关视频');
    return false;
  }

  // 下载番剧
  Future actionDownloadVideo() async {
    try {
      final downloadService = Get.find<DownloadService>();

      // 获取当前播放的剧集
      EpisodeItem? currentEpisode;
      if (bangumiDetail.value.episodes != null &&
          bangumiDetail.value.episodes!.isNotEmpty) {
        // 查找当前播放的剧集
        currentEpisode = bangumiDetail.value.episodes!.firstWhereOrNull(
          (e) => e.cid == lastPlayCid.value,
        );
        // 如果没找到，使用第一个
        currentEpisode ??= bangumiDetail.value.episodes!.first;
      }

      if (currentEpisode == null) {
        SmartDialog.showToast('无法获取剧集信息');
        return;
      }

      // 如果有多集，显示选择对话框
      if (bangumiDetail.value.episodes!.length > 1) {
        showDialog(
          context: Get.context!,
          builder: (context) {
            return AlertDialog(
              title: const Text('下载选项'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('下载当前集'),
                    subtitle: Text(currentEpisode!.longTitle ?? ''),
                    onTap: () {
                      Get.back();
                      _showQualityDialog(downloadService, currentEpisode!);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.download_for_offline),
                    title: const Text('批量下载'),
                    subtitle:
                        Text('共 ${bangumiDetail.value.episodes!.length} 集'),
                    onTap: () {
                      Get.back();
                      _showBatchDownloadPanel();
                    },
                  ),
                ],
              ),
            );
          },
        );
      } else {
        // 只有一集，直接显示画质选择
        _showQualityDialog(downloadService, currentEpisode);
      }
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('下载失败: $e');
    }
  }

  // 显示画质选择对话框
  Future<void> _showQualityDialog(
    DownloadService downloadService,
    EpisodeItem currentEpisode,
  ) async {
    // 显示加载提示
    SmartDialog.showLoading(msg: '获取画质信息...');

    // 获取视频真实可用的画质列表
    final res = await VideoHttp.videoUrl(
      bvid: currentEpisode.bvid!,
      cid: currentEpisode.cid!,
    );

    SmartDialog.dismiss();

    if (!res['status']) {
      SmartDialog.showToast('获取画质信息失败: ${res['msg']}');
      return;
    }

    final PlayUrlModel playUrlData = res['data'];
    final List<FormatItem>? supportFormats = playUrlData.supportFormats;

    if (supportFormats == null || supportFormats.isEmpty) {
      SmartDialog.showToast('无可用画质');
      return;
    }

    // 显示画质选择对话框
    showDialog(
      context: Get.context!,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择画质'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: supportFormats.map((format) {
                final quality = VideoQualityCode.fromCode(format.quality!);
                if (quality == null) return const SizedBox.shrink();

                return ListTile(
                  title: Text(format.newDesc ?? quality.description),
                  onTap: () {
                    Get.back();
                    _startDownload(downloadService, currentEpisode, quality);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // 显示批量下载面板
  void _showBatchDownloadPanel() {
    if (bangumiDetail.value.episodes == null ||
        bangumiDetail.value.episodes!.isEmpty) {
      SmartDialog.showToast('无可用剧集');
      return;
    }

    // 导入批量下载面板
    final episodes = bangumiDetail.value.episodes!.map((episode) {
      return BatchDownloadItem(
        index: episode.id ?? 0,
        title: episode.title ?? '',
        subtitle: episode.longTitle,
        cid: episode.cid!,
        bvid: episode.bvid!,
        aid: episode.aid!,
        duration: episode.duration ?? 0,
        cover: episode.cover,
        danmakuCount: null,
        page: 1,
        part: null,
        episodeId: episode.id,
        longTitle: episode.longTitle,
      );
    }).toList();

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      builder: (context) {
        return BatchDownloadPanel(
          episodes: episodes,
          title: bangumiDetail.value.title ?? '',
          cover: bangumiDetail.value.cover ?? '',
          ownerId: null,
          ownerName: null,
          seasonId: seasonId?.toString(),
          seasonType: bangumiDetail.value.type,
        );
      },
    );
  }

  void _startDownload(
    DownloadService downloadService,
    EpisodeItem currentEpisode,
    VideoQuality quality,
  ) {
    // 构建EpInfo
    final epInfo = EpInfo(
      avId: currentEpisode.aid!,
      page: 1,
      danmaku: 0, // EpisodeItem没有danmaku字段
      cover: currentEpisode.cover ?? '',
      episodeId: currentEpisode.id ?? 0,
      index: currentEpisode.title ?? '',
      indexTitle: currentEpisode.longTitle ?? '',
      showTitle: currentEpisode.longTitle,
      from: 'bangumi',
      seasonType: bangumiDetail.value.type ?? 1,
      width: 0,
      height: 0,
      rotate: 0,
      link: currentEpisode.link ?? '',
      bvid: currentEpisode.bvid ?? '',
      sortIndex: currentEpisode.id ?? 0,
    );

    downloadService.downloadVideo(
      cid: currentEpisode.cid!,
      page: 1,
      bvid: currentEpisode.bvid!,
      aid: currentEpisode.aid!,
      part: currentEpisode.longTitle,
      title: bangumiDetail.value.title ?? '',
      cover: currentEpisode.cover ?? bangumiDetail.value.cover ?? '',
      duration: currentEpisode.duration ?? 0,
      danmakuCount: bangumiDetail.value.stat?['danmaku'],
      ownerId: null,
      ownerName: null,
      videoQuality: quality,
      seasonId: seasonId?.toString(),
      epInfo: epInfo,
    );
    SmartDialog.showToast('已添加到下载队列');
  }
}
