import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:PiliPalaX/http/constants.dart';
import 'package:PiliPalaX/http/video.dart';
import 'package:PiliPalaX/models/common/reply_type.dart';
import 'package:PiliPalaX/models/common/search_type.dart';
import 'package:PiliPalaX/models/download/download_entry_info.dart';
import 'package:PiliPalaX/models/download/download_media_info.dart';
import 'package:PiliPalaX/models/video/play/quality.dart';
import 'package:PiliPalaX/models/video/play/url.dart';
import 'package:PiliPalaX/models/video/reply/item.dart';
import 'package:PiliPalaX/pages/video/reply_reply/index.dart';
import 'package:PiliPalaX/pages/video/introduction/detail/controller.dart';
import 'package:PiliPalaX/pages/video/introduction/bangumi/controller.dart';
import 'package:PiliPalaX/plugin/pl_player/index.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:PiliPalaX/utils/utils.dart';
import 'package:PiliPalaX/utils/video_utils.dart';
import 'package:path/path.dart' as path;

import '../../../utils/id_utils.dart';
import 'widgets/header_control.dart';

class VideoDetailController extends GetxController
    with GetSingleTickerProviderStateMixin {
  /// 路由传参
  String bvid = Get.parameters['bvid']!;
  RxInt cid = int.parse(Get.parameters['cid']!).obs;
  // 用于小窗返回
  bool resumePlay = Get.parameters['resume']?.toLowerCase() == 'true';
  RxInt danmakuCid = 0.obs;
  String heroTag = Get.arguments['heroTag'];
  // 视频详情
  Map videoItem = {};
  // 视频类型 默认投稿视频
  SearchType videoType = Get.arguments['videoType'] ?? SearchType.video;

  /// tabs相关配置
  int tabInitialIndex = 0;
  late TabController tabCtr;
  RxList<String> tabs = <String>['简介', '评论'].obs;

  // 请求返回的视频信息
  late PlayUrlModel data;
  // 请求状态
  RxBool isLoading = false.obs;

  /// 播放器配置 画质 音质 解码格式
  late VideoQuality currentVideoQa;
  AudioQuality? currentAudioQa;
  late VideoDecodeFormats currentDecodeFormats;
  // 是否开始自动播放 存在多p的情况下，第二p需要为true
  RxBool autoPlay = true.obs;
  // 视频资源是否有效
  RxBool isEffective = true.obs;
  // 封面图的展示
  RxBool isShowCover = true.obs;
  // 硬解
  RxBool enableHA = true.obs;
  RxString hwdec = 'auto'.obs;

  /// 本地存储
  Box userInfoCache = GStorage.userInfo;
  Box localCache = GStorage.localCache;
  Box setting = GStorage.setting;

  RxInt oid = 0.obs;
  // 评论id 请求楼中楼评论使用
  int fRpid = 0;
  // 目标回复id 用于定位高亮
  int? targetReplyRpid;

  ReplyItemModel? firstFloor;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  RxString bgCover = ''.obs;
  PlPlayerController? plPlayerController;

  late VideoItem firstVideo;
  late AudioItem firstAudio;
  late String videoUrl;
  late String audioUrl;
  Duration? defaultST;
  // 亮度
  double? brightness;
  // 默认记录历史记录
  bool enableHeart = true;
  var userInfo;
  late bool isFirstTime = true;
  PreferredSizeWidget? headerControl;

  // late bool enableCDN;
  late int? cacheVideoQa;
  late String cacheDecode;
  late String cacheSecondDecode;
  late int cacheAudioQa;

  PersistentBottomSheetController? replyReplyBottomSheetCtr;

  // 继续播放自动跳转
  bool showContinuePlayTip = true;

  @override
  void onInit() async {
    super.onInit();
    final Map argMap = Get.arguments ?? {};
    print("🔍 VideoDetailController.onInit() - 开始初始化");
    print("🔍 Get.arguments: $argMap");
    print("🔍 Get.parameters: ${Get.parameters}");
    userInfo = userInfoCache.get('userInfoCache');

    var keys = argMap.keys.toList();
    if (keys.isNotEmpty) {
      if (keys.contains('videoItem')) {
        var args = argMap['videoItem'];
        if (args.pic != null && args.pic != '') {
          videoItem['pic'] = args.pic;
        }
        try {
          if (args.dimension != null) {
            videoItem['dimension'] = args.dimension;
          }
        } catch (_) {}
        try {
          if (args.rcmdReason != null) {
            videoItem['rcmdReason'] = args.rcmdReason;
          }
        } catch (_) {}
      }
      if (keys.contains('pic')) {
        if (argMap['pic'] != null && argMap['pic'] != '') {
          videoItem['pic'] = argMap['pic'];
        }
      }
    }
    bool defaultShowComment =
        setting.get(SettingBoxKey.defaultShowComment, defaultValue: false);
    tabCtr = TabController(
        length: 2, vsync: this, initialIndex: defaultShowComment ? 1 : 0);
    autoPlay.value = resumePlay ||
        setting.get(SettingBoxKey.autoPlayEnable, defaultValue: true);
    if (autoPlay.value) {
      isShowCover.value = false;
      plPlayerController = PlPlayerController.getInstance();
      plPlayerController!.controls = false;
      if (!resumePlay) {
        plPlayerController!.direction.value = 'horizontal';
        if (videoItem['dimension'] != null) {
          if (videoItem['dimension'].width < videoItem['dimension'].height) {
            plPlayerController!.direction.value = 'vertical';
          }
        } else if (videoItem['rcmdReason'] != null &&
            videoItem['rcmdReason'].contains('竖屏')) {
          plPlayerController!.direction.value = 'vertical';
        }
      }
      headerControl = HeaderControl(
        controller: plPlayerController,
        videoDetailCtr: this,
        heroTag: heroTag,
      );
    }
    if (videoItem['pic']?.isEmpty != false) {
      VideoHttp.videoIntro(bvid: bvid).then(
        (value) {
          if (value['status']) {
            videoItem['pic'] = value['data'].pic;
            isShowCover.refresh();
          } else {
            SmartDialog.showToast("视频封面获取失败：${value['msg']}");
          }
        },
      );
    }
    enableHA.value = setting.get(SettingBoxKey.enableHA, defaultValue: true);
    hwdec.value = setting.get(SettingBoxKey.hardwareDecoding,
        defaultValue: 'auto'); //Platform.isAndroid ? 'auto-safe' : 'auto');
    if (userInfo == null ||
        localCache.get(LocalCacheKey.historyPause) == true) {
      enableHeart = false;
    }
    danmakuCid.value = cid.value;

    // CDN优化
    // enableCDN = setting.get(SettingBoxKey.enableCDN, defaultValue: true);

    // 预设的画质
    cacheVideoQa = setting.get(SettingBoxKey.defaultVideoQa,
        defaultValue: VideoQuality.values.last.code);
    // 预设的解码格式
    cacheDecode = setting.get(SettingBoxKey.defaultDecode,
        defaultValue: VideoDecodeFormats.values.last.code);
    cacheSecondDecode = setting.get(SettingBoxKey.secondDecode,
        defaultValue: VideoDecodeFormats.values[1].code);
    cacheAudioQa = setting.get(SettingBoxKey.defaultAudioQa,
        defaultValue: AudioQuality.hiRes.code);
    if (Get.parameters['bvid'] != null && Get.parameters['bvid']!.isNotEmpty) {
      oid.value = IdUtils.bv2av(Get.parameters['bvid']!);
    } else {
      SmartDialog.showToast('视频信息获取失败，可能为充电视频等特殊情况');
      oid.value = 0;
    }
  }

  showReplyReplyPanel() {
    replyReplyBottomSheetCtr =
        scaffoldKey.currentState?.showBottomSheet((BuildContext context) {
      // SmartDialog.show(
      //     alignment: Alignment.bottomRight,
      //     builder: (context) {
      return VideoReplyReplyPanel(
        oid: oid.value,
        rpid: fRpid,
        closePanel: () => {
          fRpid = 0,
        },
        firstFloor: firstFloor,
        replyType: ReplyType.video,
        source: 'videoDetail',
        id: targetReplyRpid,
      );
    });
    replyReplyBottomSheetCtr?.closed.then((value) {
      fRpid = 0;
      targetReplyRpid = null;
    });
  }

  /// 更新画质、音质
  /// TODO 继续进度播放
  updatePlayer() async {
    if (plPlayerController == null) return;
    isShowCover.value = false;
    defaultST = plPlayerController!.position.value;
    plPlayerController!.removeListeners();
    plPlayerController!.isBuffering.value = false;
    plPlayerController!.buffered.value = Duration.zero;

    /// 根据currentVideoQa和currentDecodeFormats 重新设置videoUrl
    List<VideoItem> videoList =
        data.dash!.video!.where((i) => i.id == currentVideoQa.code).toList();

    final List supportDecodeFormats = videoList.map((e) => e.codecs!).toList();
    VideoDecodeFormats defaultDecodeFormats =
        VideoDecodeFormatsCode.fromString(cacheDecode)!;
    VideoDecodeFormats secondDecodeFormats =
        VideoDecodeFormatsCode.fromString(cacheSecondDecode)!;
    try {
      // 当前视频没有对应格式返回第一个
      int flag = 0;
      for (var i in supportDecodeFormats) {
        if (i.startsWith(currentDecodeFormats.code)) {
          flag = 1;
          break;
        } else if (i.startsWith(defaultDecodeFormats.code)) {
          flag = 2;
        } else if (i.startsWith(secondDecodeFormats.code)) {
          if (flag == 0) {
            flag = 4;
          }
        }
      }
      if (flag == 1) {
        //currentDecodeFormats
        firstVideo = videoList.firstWhere(
            (i) => i.codecs!.startsWith(currentDecodeFormats.code),
            orElse: () => videoList.first);
      } else {
        if (currentVideoQa == VideoQuality.dolbyVision) {
          currentDecodeFormats =
              VideoDecodeFormatsCode.fromString(videoList.first.codecs!)!;
          firstVideo = videoList.first;
        } else if (flag == 2) {
          //defaultDecodeFormats
          currentDecodeFormats = defaultDecodeFormats;
          firstVideo = videoList.firstWhere(
            (i) => i.codecs!.startsWith(defaultDecodeFormats.code),
            orElse: () => videoList.first,
          );
        } else if (flag == 4) {
          //secondDecodeFormats
          currentDecodeFormats = secondDecodeFormats;
          firstVideo = videoList.firstWhere(
            (i) => i.codecs!.startsWith(secondDecodeFormats.code),
            orElse: () => videoList.first,
          );
        } else if (flag == 0) {
          currentDecodeFormats =
              VideoDecodeFormatsCode.fromString(supportDecodeFormats.first)!;
          firstVideo = videoList.first;
        }
      }
    } catch (err) {
      SmartDialog.showToast('DecodeFormats error: $err');
    }

    videoUrl = firstVideo.baseUrl!;

    /// 根据currentAudioQa 重新设置audioUrl
    if (currentAudioQa != null) {
      final AudioItem firstAudio = data.dash!.audio!.firstWhere(
        (AudioItem i) => i.id == currentAudioQa!.code,
        orElse: () => data.dash!.audio!.first,
      );
      audioUrl = firstAudio.baseUrl ?? '';
    }

    playerInit();
  }

  Future playerInit({
    video,
    audio,
    seekToTime,
    duration,
    bool autoplay = true,
  }) async {
    /// 设置/恢复 屏幕亮度
    // if (brightness != null) {
    //   ScreenBrightness().setScreenBrightness(brightness!);
    // }
    plPlayerController ??= PlPlayerController.getInstance();
    headerControl ??= HeaderControl(
      controller: plPlayerController,
      videoDetailCtr: this,
      heroTag: heroTag,
    );
    // print("resumePlay:$resumePlay,isFirstTime:$isFirstTime");
    if (!resumePlay) {
      // 获取番剧参数（如果是番剧的话）
      int? epid;
      int? seasonId;
      if (videoType == SearchType.media_bangumi) {
        try {
          final bangumiCtr = Get.find<BangumiIntroController>(tag: heroTag);
          epid = bangumiCtr.epId;
          seasonId = bangumiCtr.seasonId;
        } catch (e) {
          print('⚠️ 获取番剧参数失败: $e');
        }
      }

      // 🔥 优化：检测 4K 视频并记录日志
      bool is4K = firstVideo.width != null && firstVideo.width! >= 3840;
      if (is4K) {
        print('🎬 准备播放 4K 视频: ${firstVideo.width}x${firstVideo.height}');
        print('   编码格式: ${firstVideo.codecs}');
        print(
            '   码率: ${firstVideo.bandWidth != null ? (firstVideo.bandWidth! / 1000000).toStringAsFixed(2) : "未知"} Mbps');
      }

      await plPlayerController!.setDataSource(
        DataSource(
          videoSource: video ?? videoUrl,
          audioSource: audio ?? audioUrl,
          type: DataSourceType.network,
          httpHeaders: {
            'user-agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36',
            'referer': HttpString.baseUrl
          },
        ),
        // 硬解
        enableHA: enableHA.value,
        hwdec: hwdec.value,
        seekTo: seekToTime ?? defaultST,
        duration: duration ?? data.timeLength == null
            ? null
            : Duration(milliseconds: data.timeLength!),
        // 🔥 优化：传递视频分辨率信息，用于播放器优化配置
        width: firstVideo.width?.toDouble(),
        height: firstVideo.height?.toDouble(),
        // 宽>高 水平 否则 垂直
        direction: firstVideo.width != null && firstVideo.height != null
            ? ((firstVideo.width! - firstVideo.height!) > 0
                ? 'horizontal'
                : 'vertical')
            : null,
        bvid: bvid,
        cid: cid.value,
        epid: epid,
        seasonId: seasonId,
        enableHeart: enableHeart,
        autoplay: autoplay,
      );
    }

    /// 开启自动全屏时，在player初始化完成后立即传入headerControl
    plPlayerController!.headerControl = headerControl;
  }

  // 视频链接
  Future queryVideoUrl() async {
    print('🔍 queryVideoUrl() - 方法被调用');
    var result;

    // 调试：打印 arguments
    print('🔍 queryVideoUrl - Get.arguments: ${Get.arguments}');
    print('🔍 queryVideoUrl - Get.parameters: ${Get.parameters}');

    // 检查是否是离线播放
    if (Get.arguments != null && Get.arguments['sourceType'] == 'file') {
      print('🎬 检测到离线播放模式');
      return await _loadOfflineVideo();
    }
    print('🌐 使用在线播放模式');

    // 根据视频类型选择不同的API
    if (videoType == SearchType.media_bangumi) {
      print('🎬 检测到番剧/影视类型，使用番剧API');
      // 获取番剧参数
      int? epid;
      try {
        final bangumiCtr = Get.find<BangumiIntroController>(tag: heroTag);
        epid = bangumiCtr.epId;
        print('🎬 番剧参数: bvid=$bvid, cid=${cid.value}, epId=$epid');
      } catch (e) {
        print('⚠️ 获取番剧参数失败: $e');
      }

      // 使用番剧专用API
      result = await VideoHttp.bangumiVideoUrl(
        cid: cid.value,
        bvid: bvid,
        epId: epid,
      );
      print('🎬 番剧API调用结果: status=${result['status']}');
    } else {
      print('🎬 普通视频类型，使用普通视频API');
      // 使用普通视频API
      result = await VideoHttp.videoUrl(cid: cid.value, bvid: bvid);
    }

    if (result['status']) {
      data = result['data'];

      // 对于普通视频，额外获取播放信息
      if (videoType != SearchType.media_bangumi) {
        try {
          var playInfoResult =
              await VideoHttp.playInfo(bvid: bvid, cid: cid.value);
          if (playInfoResult['status']) {
            final playInfoData = playInfoResult['data'];

            // 使用playInfo的数据更新
            if (playInfoData['last_play_cid'] != null) {
              data.lastPlayCid = playInfoData['last_play_cid'];
            }
            if (playInfoData['last_play_time'] != null) {
              data.lastPlayTime = playInfoData['last_play_time'];
            }
          }
        } catch (e) {
          // 静默失败
        }
      }
      if (data.acceptDesc!.isNotEmpty && data.acceptDesc!.contains('试看')) {
        SmartDialog.showNotify(
          msg: '该视频为专属视频，仅提供试看',
          displayTime: const Duration(seconds: 3),
          notifyType: NotifyType.warning,
        );
      }
      if (data.dash == null && data.durl != null) {
        videoUrl = data.durl!.first.url!;
        audioUrl = '';
        // 只有在defaultST为null时才设置历史记录位置
        // 如果defaultST已经被设置（比如切换选集时设置为Duration.zero），则保持不变
        if (defaultST == null) {
          defaultST = data.lastPlayTime != null
              ? Duration(milliseconds: data.lastPlayTime!)
              : Duration.zero;
        }
        // 实际为FLV/MP4格式，但已被淘汰，这里仅做兜底处理
        firstVideo = VideoItem(
            id: data.quality!,
            baseUrl: videoUrl,
            codecs: 'avc1',
            quality: VideoQualityCode.fromCode(data.quality!)!);
        currentDecodeFormats = VideoDecodeFormatsCode.fromString('avc1')!;
        currentVideoQa = VideoQualityCode.fromCode(data.quality!)!;
        if (autoPlay.value) {
          if (isClosed) return result;
          isShowCover.value = false;
          await playerInit();
        }
        return result;
      }
      if (data.dash == null) {
        SmartDialog.showNotify(
          msg: '视频资源不存在',
          displayTime: const Duration(seconds: 3),
          notifyType: NotifyType.error,
        );
        isShowCover.value = false;
        return result;
      }
      final List<VideoItem> allVideosList = data.dash!.video!;
      // print("allVideosList:${allVideosList}");
      // 当前可播放的最高质量视频
      int currentHighVideoQa = allVideosList.first.quality!.code;
      // 预设的画质为null，则当前可用的最高质量
      cacheVideoQa ??= currentHighVideoQa;
      int resVideoQa = currentHighVideoQa;
      if (cacheVideoQa! <= currentHighVideoQa) {
        // 如果预设的画质低于当前最高
        final List<int> numbers =
            data.acceptQuality!.where((e) => e <= currentHighVideoQa).toList();
        resVideoQa = Utils.findClosestNumber(cacheVideoQa!, numbers);
      }
      currentVideoQa = VideoQualityCode.fromCode(resVideoQa)!;

      /// 取出符合当前画质的videoList
      final List<VideoItem> videosList =
          allVideosList.where((e) => e.quality!.code == resVideoQa).toList();

      /// 优先顺序 设置中指定解码格式 -> 当前可选的首个解码格式
      final List<FormatItem> supportFormats = data.supportFormats!;
      // 根据画质选编码格式
      final List supportDecodeFormats = supportFormats
          .firstWhere((e) => e.quality == resVideoQa,
              orElse: () => supportFormats.first)
          .codecs!;
      // 默认从设置中取AV1
      currentDecodeFormats = VideoDecodeFormatsCode.fromString(cacheDecode)!;
      VideoDecodeFormats secondDecodeFormats =
          VideoDecodeFormatsCode.fromString(cacheSecondDecode)!;
      // 当前视频没有对应格式返回第一个
      int flag = 0;
      for (var i in supportDecodeFormats) {
        if (i.startsWith(currentDecodeFormats.code)) {
          flag = 1;
          break;
        } else if (i.startsWith(secondDecodeFormats.code)) {
          flag = 2;
        }
      }
      if (flag == 2) {
        currentDecodeFormats = secondDecodeFormats;
      } else if (flag == 0) {
        currentDecodeFormats =
            VideoDecodeFormatsCode.fromString(supportDecodeFormats.first)!;
      }

      /// 取出符合当前解码格式的videoItem
      firstVideo = videosList.firstWhere(
          (e) => e.codecs!.startsWith(currentDecodeFormats.code),
          orElse: () => videosList.first);

      // 🔥 优化：4K 视频避免使用 AV1 编码（性能要求太高）
      if (firstVideo.width != null && firstVideo.width! >= 3840) {
        if (firstVideo.codecs!.startsWith('av01')) {
          print('⚠️ 检测到 4K 视频使用 AV1 编码，尝试切换到 HEVC/AVC');

          // 优先级：HEVC (H.265) > AVC (H.264)
          final List<String> preferred4KCodecs = ['hev', 'avc'];
          for (var codec in preferred4KCodecs) {
            try {
              final alternativeVideo = videosList.firstWhere(
                (e) => e.codecs!.startsWith(codec),
              );
              firstVideo = alternativeVideo;
              currentDecodeFormats =
                  VideoDecodeFormatsCode.fromString(alternativeVideo.codecs!)!;
              print('✅ 已切换到 ${currentDecodeFormats.code} 编码');
              break;
            } catch (e) {
              // 继续尝试下一个编码格式
              continue;
            }
          }
        }
      }

      // videoUrl = enableCDN
      //     ? VideoUtils.getCdnUrl(firstVideo)
      //     : (firstVideo.backupUrl ?? firstVideo.baseUrl!);
      videoUrl = VideoUtils.getCdnUrl(firstVideo);

      /// 优先顺序 设置中指定质量 -> 当前可选的最高质量
      late AudioItem? firstAudio;
      final List<AudioItem> audiosList = data.dash!.audio ?? <AudioItem>[];
      if (data.dash!.dolby?.audio != null &&
          data.dash!.dolby!.audio!.isNotEmpty) {
        // 杜比
        audiosList.insert(0, data.dash!.dolby!.audio!.first);
      }

      if (data.dash!.flac?.audio != null) {
        // 无损
        audiosList.insert(0, data.dash!.flac!.audio!);
      }

      if (audiosList.isNotEmpty) {
        final List<int> numbers = audiosList.map((map) => map.id!).toList();
        int closestNumber = Utils.findClosestNumber(cacheAudioQa, numbers);
        if (!numbers.contains(cacheAudioQa) &&
            numbers.any((e) => e > cacheAudioQa)) {
          closestNumber = 30280;
        }
        firstAudio = audiosList.firstWhere((e) => e.id == closestNumber,
            orElse: () => audiosList.first);
        // audioUrl = enableCDN
        //     ? VideoUtils.getCdnUrl(firstAudio)
        //     : (firstAudio.backupUrl ?? firstAudio.baseUrl!);
        audioUrl = VideoUtils.getCdnUrl(firstAudio);
        if (firstAudio.id != null) {
          currentAudioQa = AudioQualityCode.fromCode(firstAudio.id!)!;
        }
      } else {
        firstAudio = AudioItem();
        audioUrl = '';
      }
      //
      // 只有在defaultST为null时才使用lastPlayTime
      // 如果defaultST已经被设置（比如切换选集时设置为Duration.zero），则保持不变
      if (defaultST == null) {
        defaultST = Duration(milliseconds: data.lastPlayTime!);
      }

      // 检查是否需要显示继续播放提示
      checkContinuePlay();

      if (autoPlay.value) {
        if (isClosed) return result;
        isShowCover.value = false;
        await playerInit();
      }
    } else {
      if (result['code'] == -404) {
        isShowCover.value = false;
        SmartDialog.showNotify(
          msg: '视频不存在或已被删除',
          displayTime: const Duration(seconds: 3),
          notifyType: NotifyType.error,
        );
      } else if (result['code'] == 87008) {
        SmartDialog.showNotify(
            msg: "当前视频可能是专属视频，可能需包月充电观看(${result['msg']})",
            displayTime: const Duration(seconds: 3),
            notifyType: NotifyType.warning);
      } else {
        SmartDialog.showNotify(
          msg: '错误（${result['code']}）：${result['msg']}',
          displayTime: const Duration(seconds: 3),
          notifyType: NotifyType.warning,
        );
      }
    }
    return result;
  }

  // mob端全屏状态关闭二级回复
  hiddenReplyReplyPanel() {
    replyReplyBottomSheetCtr != null
        ? replyReplyBottomSheetCtr!.close()
        : null; // print('replyReplyBottomSheetCtr is null');
  }

  // 检查并自动跳转到上次观看位置
  void checkContinuePlay() {
    if (!showContinuePlayTip) {
      return;
    }
    showContinuePlayTip = false;

    // 延迟检查，等待Controller初始化完成
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        // 判断是番剧还是普通视频
        if (videoType == SearchType.media_bangumi) {
          final bangumiIntroController =
              Get.find<BangumiIntroController>(tag: heroTag);
          final episodes = bangumiIntroController.bangumiDetail.value.episodes;

          if (episodes != null &&
              episodes.length > 1 &&
              data.lastPlayCid != null &&
              data.lastPlayCid != 0) {
            if (data.lastPlayCid != cid.value) {
              final index =
                  episodes.indexWhere((ep) => ep.cid == data.lastPlayCid);

              if (index != -1) {
                final episode = episodes[index];

                // 自动跳转到上次观看的集数，并使用历史记录位置
                bangumiIntroController.changeSeasonOrbangu(
                  episode.bvid,
                  episode.cid,
                  episode.aid,
                  epid: episode.id,
                  useHistory: true, // 使用历史记录位置
                );

                // 显示Toast提示
                SmartDialog.showToast('已自动跳转到上次观看的第${episode.title}');
              }
            }
          }
        } else {
          final videoIntroController =
              Get.find<VideoIntroController>(tag: heroTag);
          final pages = videoIntroController.videoDetail.value.pages;

          if (pages != null &&
              pages.length > 1 &&
              data.lastPlayCid != null &&
              data.lastPlayCid != 0) {
            if (data.lastPlayCid != cid.value) {
              final index =
                  pages.indexWhere((page) => page.cid == data.lastPlayCid);

              if (index != -1) {
                final page = pages[index];

                // 自动跳转到上次观看的分P，并使用历史记录位置
                videoIntroController.changeSeasonOrbangu(
                  bvid,
                  page.cid,
                  IdUtils.bv2av(bvid),
                  useHistory: true, // 使用历史记录位置
                );

                // 显示Toast提示
                SmartDialog.showToast('已自动跳转到上次观看的第${index + 1}P');
              }
            }
          }
        }
      } catch (e) {
        // 控制器可能还未初始化，再延迟一次尝试
        Future.delayed(const Duration(milliseconds: 1000), () {
          try {
            if (videoType == SearchType.media_bangumi) {
              final bangumiIntroController =
                  Get.find<BangumiIntroController>(tag: heroTag);
              final episodes =
                  bangumiIntroController.bangumiDetail.value.episodes;

              if (episodes != null &&
                  episodes.length > 1 &&
                  data.lastPlayCid != null &&
                  data.lastPlayCid != 0 &&
                  data.lastPlayCid != cid.value) {
                final index =
                    episodes.indexWhere((ep) => ep.cid == data.lastPlayCid);
                if (index != -1) {
                  final episode = episodes[index];
                  bangumiIntroController.changeSeasonOrbangu(
                    episode.bvid,
                    episode.cid,
                    episode.aid,
                    epid: episode.id,
                    useHistory: true, // 使用历史记录位置
                  );
                  SmartDialog.showToast('已自动跳转到上次观看的第${episode.title}');
                }
              }
            } else {
              final videoIntroController =
                  Get.find<VideoIntroController>(tag: heroTag);
              final pages = videoIntroController.videoDetail.value.pages;

              if (pages != null &&
                  pages.length > 1 &&
                  data.lastPlayCid != null &&
                  data.lastPlayCid != 0 &&
                  data.lastPlayCid != cid.value) {
                final index =
                    pages.indexWhere((page) => page.cid == data.lastPlayCid);
                if (index != -1) {
                  final page = pages[index];
                  videoIntroController.changeSeasonOrbangu(
                    bvid,
                    page.cid,
                    IdUtils.bv2av(bvid),
                    useHistory: true, // 使用历史记录位置
                  );
                  SmartDialog.showToast('已自动跳转到上次观看的第${index + 1}P');
                }
              }
            }
          } catch (e2) {
            // 静默失败
          }
        });
      }
    });
  }

  /// 加载离线视频
  Future<Map<String, dynamic>> _loadOfflineVideo() async {
    try {
      final entry = Get.arguments['entry'] as DownloadEntryInfo;
      final dirPath = Get.arguments['dirPath'] as String;

      print('🎬 开始加载离线视频: ${entry.title}');
      print('🎬 文件路径: $dirPath');

      // 使用 typeTag，如果为空则使用 preferedVideoQuality
      final qualityTag = entry.typeTag ?? entry.preferedVideoQuality.toString();
      print('🎬 使用画质标签: $qualityTag');

      // 构建视频目录路径
      final videoDir = Directory(path.join(dirPath, qualityTag));
      print('🎬 视频目录: ${videoDir.path}');

      if (!videoDir.existsSync()) {
        SmartDialog.showToast('视频文件不存在: $qualityTag');
        return {'status': false, 'msg': '视频文件不存在'};
      }

      // 读取媒体信息
      final mediaJsonFile = File(path.join(videoDir.path, 'index.json'));
      if (!mediaJsonFile.existsSync()) {
        SmartDialog.showToast('视频信息文件不存在');
        return {'status': false, 'msg': '视频信息文件不存在'};
      }

      final mediaJson = jsonDecode(await mediaJsonFile.readAsString());

      // 根据 JSON 结构判断类型
      final bool isType1 = mediaJson.containsKey('segment_list');
      final DownloadMediaInfo mediaInfo = isType1
          ? Type1MediaInfo.fromJson(mediaJson)
          : Type2MediaInfo.fromJson(mediaJson);

      print('🎬 媒体信息类型: ${mediaInfo.runtimeType}');

      // 根据媒体类型加载视频
      if (mediaInfo is Type1MediaInfo) {
        // FLV 格式
        final videoFile = File(path.join(videoDir.path, 'video.flv'));
        if (!videoFile.existsSync()) {
          SmartDialog.showToast('视频文件不存在');
          return {'status': false, 'msg': '视频文件不存在'};
        }

        print('🎬 FLV格式视频: ${videoFile.path}');
        videoUrl = videoFile.path;
        audioUrl = '';
      } else if (mediaInfo is Type2MediaInfo) {
        // DASH 格式
        final videoFile = File(path.join(videoDir.path, 'video.m4s'));
        if (!videoFile.existsSync()) {
          SmartDialog.showToast('视频文件不存在');
          return {'status': false, 'msg': '视频文件不存在'};
        }

        print('🎬 DASH格式视频: ${videoFile.path}');
        videoUrl = videoFile.path;

        // 检查音频文件
        final audioFile = File(path.join(videoDir.path, 'audio.m4s'));
        if (audioFile.existsSync()) {
          print('🎬 DASH格式音频: ${audioFile.path}');
          audioUrl = audioFile.path;
        } else {
          audioUrl = '';
        }
      }

      // 简化：只创建必要的数据，参考 PiliPlus
      firstVideo = VideoItem(
        id: entry.preferedVideoQuality,
        baseUrl: videoUrl,
        codecs: 'avc1',
        quality: VideoQualityCode.fromCode(entry.preferedVideoQuality)!,
      );
      currentVideoQa = VideoQualityCode.fromCode(entry.preferedVideoQuality)!;
      currentDecodeFormats = VideoDecodeFormatsCode.fromString('avc1')!;

      // 设置播放位置
      if (defaultST == null) {
        defaultST = Duration.zero;
      }

      // 创建简单的 PlayUrlModel，设置视频时长以显示进度条
      data = PlayUrlModel(
        timeLength: entry.totalTimeMilli, // 使用下载时保存的视频时长
      );

      print('🎬 视频时长: ${entry.totalTimeMilli}ms (${Duration(milliseconds: entry.totalTimeMilli)})');


      print('🎬 离线视频数据初始化完成');

      // 初始化播放器
      if (autoPlay.value) {
        if (isClosed) return {'status': true};
        isShowCover.value = false;
        await playerInit();
      }

      print('🎬 离线视频加载成功');
      return {'status': true};
    } catch (e) {
      print('❌ 加载离线视频失败: $e');
      SmartDialog.showToast('加载离线视频失败: $e');
      return {'status': false, 'msg': e.toString()};
    }
  }
}
