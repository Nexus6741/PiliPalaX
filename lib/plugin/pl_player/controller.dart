// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:easy_debounce/easy_throttle.dart';
// import 'package:fl_pip/fl_pip.dart';
import 'package:flutter/material.dart';
// import 'package:android_window/main.dart' as android_window;
// import 'android_window.dart';
import 'package:flutter_floating/floating/assist/floating_slide_type.dart';
import 'package:flutter_floating/floating/floating.dart';
import 'package:flutter_floating/floating/manager/floating_manager.dart';
import 'package:flutter_floating/floating_increment.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:PiliPalaX/http/video.dart';
import 'package:PiliPalaX/http/init.dart';
import 'package:PiliPalaX/http/api.dart';
import 'package:PiliPalaX/pages/mine/controller.dart';
import 'package:PiliPalaX/plugin/pl_player/index.dart';
import 'package:PiliPalaX/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPalaX/services/service_locator.dart';
import 'package:PiliPalaX/utils/feed_back.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:PiliPalaX/models/video/video_shot_data.dart';
// import 'package:screen_brightness/screen_brightness.dart';
import 'package:universal_platform/universal_platform.dart';
import '../../models/video/play/subtitle.dart';
import '../../pages/video/controller.dart';
import '../../pages/video/introduction/bangumi/controller.dart';
import '../../pages/video/introduction/detail/controller.dart';
import '../../utils/wakelock_manager.dart';
// import '../../pages/video/controller.dart';
// import 'package:wakelock_plus/wakelock_plus.dart;';

Box videoStorage = GStorage.video;
Box setting = GStorage.setting;
Box localCache = GStorage.localCache;

class PlPlayerController {
  static Player? _videoPlayerController;
  VideoController? _videoController;

  // 添加一个私有静态变量来保存实例
  static PlPlayerController? _instance;

  // 流事件  监听播放状态变化
  StreamSubscription? _playerEventSubs;

  /// [playerStatus] has a [status] observable
  final PlPlayerStatus playerStatus = PlPlayerStatus();

  ///
  final PlPlayerDataStatus dataStatus = PlPlayerDataStatus();

  // bool controlsEnabled = false;

  /// 响应数据
  /// 带有Seconds的变量只在秒数更新时更新，以避免频繁触发重绘
  // 播放位置
  final Rx<Duration> _position = Rx(Duration.zero);
  final RxInt positionSeconds = 0.obs;
  final Rx<Duration> _sliderPosition = Rx(Duration.zero);
  final RxInt sliderPositionSeconds = 0.obs;
  // 展示使用
  final Rx<Duration> _sliderTempPosition = Rx(Duration.zero);
  final Rx<Duration> _duration = Rx(Duration.zero);
  final RxInt durationSeconds = 0.obs;
  final Rx<Duration> _buffered = Rx(Duration.zero);
  final Rx<String> _playerLog = Rx("");
  final RxInt bufferedSeconds = 0.obs;

  final Rx<int> _playerCount = Rx(0);

  final Rx<double> _playbackSpeed = 1.0.obs;
  final Rx<double> _longPressSpeed = 2.0.obs;
  final Rx<double> _currentVolume = 1.0.obs;
  final Rx<double> _currentBrightness = 0.0.obs;

  final Rx<bool> _mute = false.obs;
  final Rx<bool> _showControls = false.obs;
  final Rx<bool> _showVolumeStatus = false.obs;
  final Rx<bool> _showBrightnessStatus = false.obs;
  final Rx<bool> _doubleSpeedStatus = false.obs;
  final Rx<bool> _controlsLock = false.obs;
  final Rx<bool> _isFullScreen = false.obs;
  // 默认投稿视频格式
  static Rx<String> _videoType = 'archive'.obs;
  // 直播间 roomId（用于小窗恢复）
  int? _liveRoomId;

  final Rx<String> _direction = 'horizontal'.obs;

  final Rx<BoxFit> _videoFit = Rx(videoFitType.first['attr']);
  final Rx<String> _videoFitDesc = Rx(videoFitType.first['desc']);
  StreamSubscription<DataStatus>? _dataListenerForVideoFit;
  StreamSubscription<DataStatus>? _dataListenerForEnterFullScreen;
  StreamSubscription<PlayerStatus>? _playerListenerForEnterPip;

  /// 后台播放
  final Rx<bool> _continuePlayInBackground = false.obs;

  final Rx<bool> _onlyPlayAudio = false.obs;

  // 视频是否已加载（第一帧渲染）
  final Rx<bool> isVideoLoaded = false.obs;

  // 🔥 新增：是否正在进行初始 seek（用于历史进度跳转）
  bool _isInitialSeeking = false;

  ///
  // ignore: prefer_final_fields
  Rx<bool> _isSliderMoving = false.obs;
  PlaylistMode _looping = PlaylistMode.none;
  bool _autoPlay = false;
  final bool _listenersInitialized = false;

  // 记录历史记录
  String _bvid = '';
  int _cid = 0;
  int? _epid;
  int? _seasonId;
  int _heartDuration = 0;
  bool _enableHeart = true;

  late DataSource dataSource;
  final RxList<Map<String, String>> _vttSubtitles = <Map<String, String>>[].obs;
  final RxInt _vttSubtitlesIndex = 0.obs;

  Timer? _timer;
  Timer? _timerForSeek;
  Timer? _timerForVolume;
  Timer? _timerForShowingVolume;
  Timer? _timerForGettingVolume;
  Timer? timerForTrackingMouse;

  // final Durations durations;

  static List<Map<String, dynamic>> videoFitType = [
    {'attr': BoxFit.contain, 'desc': '自动', 'toast': '缩放至播放器尺寸，保留黑边'},
    {'attr': BoxFit.cover, 'desc': '裁剪', 'toast': '缩放至填满播放器，裁剪超出部分'},
    {'attr': BoxFit.fill, 'desc': '拉伸', 'toast': '拉伸至播放器尺寸，将产生变形（竖屏改为自动）'},
    {'attr': BoxFit.none, 'desc': '原始', 'toast': '不缩放，以视频原始尺寸显示'},
    {'attr': BoxFit.fitHeight, 'desc': '等高', 'toast': '缩放至撑满播放器高度'},
    {'attr': BoxFit.fitWidth, 'desc': '等宽', 'toast': '缩放至撑满播放器宽度'},
    {'attr': BoxFit.scaleDown, 'desc': '限制', 'toast': '仅超出时缩小至播放器尺寸'},
  ];

  PreferredSizeWidget? headerControl;
  PreferredSizeWidget? bottomControl;
  Widget? danmuWidget;

  String get bvid => _bvid;
  int get cid => _cid;

  /// 数据加载监听
  Stream<DataStatus> get onDataStatusChanged => dataStatus.status.stream;

  /// 播放状态监听
  Stream<PlayerStatus> get onPlayerStatusChanged => playerStatus.status.stream;

  /// 视频时长
  Rx<Duration> get duration => _duration;
  Stream<Duration> get onDurationChanged => _duration.stream;

  /// 视频当前播放位置
  Rx<Duration> get position => _position;
  Stream<Duration> get onPositionChanged => _position.stream;

  /// 视频播放速度
  double get playbackSpeed => _playbackSpeed.value;

  // 长按倍速
  double get longPressSpeed => _longPressSpeed.value;

  /// 视频缓冲
  Rx<Duration> get buffered => _buffered;
  Stream<Duration> get onBufferedChanged => _buffered.stream;

  /// 视频日志
  Rx<String> get playerLog => _playerLog;

  // 视频静音
  Rx<bool> get mute => _mute;
  Stream<bool> get onMuteChanged => _mute.stream;

  // 视频字幕
  RxList<Map<String, String>> get vttSubtitles => _vttSubtitles;
  RxInt get vttSubtitlesIndex => _vttSubtitlesIndex;

  /// [videoPlayerController] instance of Player
  Player? get videoPlayerController => _videoPlayerController;

  /// [videoController] instance of Player
  VideoController? get videoController => _videoController;

  /// 设置直播间 roomId
  void setLiveRoomId(int roomId) {
    _liveRoomId = roomId;
  }

  Rx<bool> get isSliderMoving => _isSliderMoving;

  /// 进度条位置及监听
  Rx<Duration> get sliderPosition => _sliderPosition;
  Stream<Duration> get onSliderPositionChanged => _sliderPosition.stream;

  Rx<Duration> get sliderTempPosition => _sliderTempPosition;
  // Stream<Duration> get onSliderPositionChanged => _sliderPosition.stream;

  /// 是否展示控制条及监听
  Rx<bool> get showControls => _showControls;
  Stream<bool> get onShowControlsChanged => _showControls.stream;

  /// 音量控制条展示/隐藏
  Rx<bool> get showVolumeStatus => _showVolumeStatus;
  Stream<bool> get onShowVolumeStatusChanged => _showVolumeStatus.stream;

  /// 亮度控制条展示/隐藏
  Rx<bool> get showBrightnessStatus => _showBrightnessStatus;
  Stream<bool> get onShowBrightnessStatusChanged =>
      _showBrightnessStatus.stream;

  /// 音量控制条
  Rx<double> get volume => _currentVolume;
  Stream<double> get onVolumeChanged => _currentVolume.stream;

  /// 亮度控制条
  Rx<double> get brightness => _currentBrightness;
  Stream<double> get onBrightnessChanged => _currentBrightness.stream;

  /// 是否循环
  PlaylistMode get looping => _looping;

  /// 是否自动播放
  bool get autoplay => _autoPlay;

  /// 视频比例
  Rx<BoxFit> get videoFit => _videoFit;
  Rx<String> get videoFitDEsc => _videoFitDesc;

  /// 后台播放
  Rx<bool> get continuePlayInBackground => _continuePlayInBackground;

  /// 听视频
  Rx<bool> get onlyPlayAudio => _onlyPlayAudio;

  /// 是否长按倍速
  Rx<bool> get doubleSpeedStatus => _doubleSpeedStatus;

  Rx<bool> isBuffering = true.obs;

  /// 进度条预览相关
  Map<String, WeakReference<ui.Image>>? previewCache;
  VideoShotData? _videoShotData;
  bool _videoShotLoading = false;
  bool _videoShotError = false;
  final RxBool showPreview = false.obs;
  late final bool showSeekPreview =
      setting.get(SettingBoxKey.showSeekPreview, defaultValue: true);
  final RxnInt previewIndex = RxnInt();

  /// 视频截图数据
  VideoShotData? get videoShotData => _videoShotData;

  /// 屏幕锁 为true时，关闭控制栏
  Rx<bool> get controlsLock => _controlsLock;

  /// 是否正在跳转下一集
  Rx<bool> isSkipping = false.obs;

  /// 全屏状态
  Rx<bool> get isFullScreen => _isFullScreen;

  /// 全屏方向
  Rx<String> get direction => _direction;

  // Rx<int> get playerCount => _playerCount;

  ///
  Rx<String> get videoType => _videoType;

  /// 弹幕开关
  Rx<bool> isOpenDanmu = false.obs;

  /// 弹幕权重
  ValueNotifier<int> danmakuWeight = ValueNotifier(0);
  ValueNotifier<List<Map<String, dynamic>>> danmakuFilterRule =
      ValueNotifier([]);
  // 关联弹幕控制器
  DanmakuController? danmakuController;
  // 弹幕相关配置
  late List blockTypes;
  late double showArea;
  late double opacityVal;
  late double fontSizeVal;
  late double strokeWidth;
  late int fontWeight;
  late int danmakuDurationVal;
  late bool massiveMode;
  late List<double> speedsList;
  // int? defaultDuration;
  late bool enableAutoLongPressSpeed = false;
  late bool enableLongShowControl;

  // 播放顺序相关
  PlayRepeat playRepeat = PlayRepeat.pause;

  List<StreamSubscription> subscriptions = [];
  String? _currentServiceId;

  void updateSliderPositionSecond() {
    int newSecond =
        (_sliderPosition.value.inMicroseconds / Duration.microsecondsPerSecond)
            .ceil();
    if (sliderPositionSeconds.value != newSecond) {
      sliderPositionSeconds.value = newSecond;
    }
  }

  void updatePositionSecond() {
    int newSecond =
        (_position.value.inMicroseconds / Duration.microsecondsPerSecond)
            .ceil();
    if (positionSeconds.value != newSecond) {
      positionSeconds.value = newSecond;
    }
  }

  void updateDurationSecond() {
    int newSecond =
        (_duration.value.inMicroseconds / Duration.microsecondsPerSecond)
            .ceil();
    if (durationSeconds.value != newSecond) {
      durationSeconds.value = newSecond;
    }
  }

  void updateBufferedSecond() {
    int newSecond =
        (_buffered.value.inMicroseconds / Duration.microsecondsPerSecond)
            .ceil();
    if (bufferedSeconds.value != newSecond) {
      bufferedSeconds.value = newSecond;
    }
  }

  static bool instanceExists() {
    return _instance != null;
  }

  static Future<void> playIfExists(
      {bool repeat = false, bool hideControls = true}) async {
    await _instance?.play(repeat: repeat, hideControls: hideControls);
  }

  // try to get PlayerStatus
  static PlayerStatus? getPlayerStatusIfExists() {
    return _instance?.playerStatus.status.value;
  }

  static Future<void> pauseIfExists(
      {bool notify = true, bool isInterrupt = false}) async {
    if (_instance?.playerStatus.status.value == PlayerStatus.playing) {
      await _instance?.pause(notify: notify, isInterrupt: isInterrupt);
    }
  }

  static Future<void> seekToIfExists(Duration position, {type = 'seek'}) async {
    await _instance?.seekTo(position, type: type);
  }

  static double? getVolumeIfExists() {
    return _instance?.volume.value;
  }

  static Future<void> setVolumeIfExists(double volumeNew,
      {bool videoPlayerVolume = false}) async {
    await _instance?.setVolume(volumeNew, videoPlayerVolume: videoPlayerVolume);
  }

  // 添加一个私有构造函数
  PlPlayerController._() {
    _videoType = videoType;
    isOpenDanmu.value =
        setting.get(SettingBoxKey.enableShowDanmaku, defaultValue: true);
    danmakuWeight.value =
        setting.get(SettingBoxKey.danmakuWeight, defaultValue: 0);
    danmakuFilterRule.value = localCache.get(LocalCacheKey.danmakuFilterRule,
        defaultValue: []).map<Map<String, dynamic>>((e) {
      return Map<String, dynamic>.from(e);
    }).toList();
    blockTypes = setting.get(SettingBoxKey.danmakuBlockType, defaultValue: []);
    showArea = setting.get(SettingBoxKey.danmakuShowArea, defaultValue: 0.5);
    // 不透明度
    opacityVal = setting.get(SettingBoxKey.danmakuOpacity, defaultValue: 1.0);
    // 字体大小
    fontSizeVal =
        setting.get(SettingBoxKey.danmakuFontScale, defaultValue: 1.0);
    // 弹幕时间
    danmakuDurationVal =
        setting.get(SettingBoxKey.danmakuDuration, defaultValue: 7.29).round();
    // 描边粗细
    strokeWidth = setting.get(SettingBoxKey.strokeWidth, defaultValue: 1.5);
    // 弹幕字体粗细
    fontWeight = setting.get(SettingBoxKey.fontWeight, defaultValue: 5);
    // 弹幕海量模式
    massiveMode =
        setting.get(SettingBoxKey.danmakuMassiveMode, defaultValue: false);
    playRepeat = PlayRepeat.values.toList().firstWhere(
          (e) =>
              e.value ==
              videoStorage.get(VideoBoxKey.playRepeat,
                  defaultValue: PlayRepeat.pause.value),
        );
    _playbackSpeed.value =
        videoStorage.get(VideoBoxKey.playSpeedDefault, defaultValue: 1.0);
    enableAutoLongPressSpeed = setting
        .get(SettingBoxKey.enableAutoLongPressSpeed, defaultValue: false);
    // 后台播放
    _continuePlayInBackground.value = setting
        .get(SettingBoxKey.continuePlayInBackground, defaultValue: false);
    if (!enableAutoLongPressSpeed) {
      _longPressSpeed.value = videoStorage
          .get(VideoBoxKey.longPressSpeedDefault, defaultValue: 3.0);
    }
    enableLongShowControl =
        setting.get(SettingBoxKey.enableLongShowControl, defaultValue: false);
    speedsList = List<double>.from(videoStorage
        .get(VideoBoxKey.customSpeedsList, defaultValue: <double>[]));
    for (final PlaySpeed i in PlaySpeed.values) {
      speedsList.add(i.value);
    }
    speedsList.sort();
    // _playerEventSubs = onPlayerStatusChanged.listen((PlayerStatus status) {
    //   if (status == PlayerStatus.playing) {
    //     WakelockPlus.enable();
    //   } else {
    //     WakelockPlus.disable();
    //   }
    // });
    enableAutoPip();
  }

  void enableAutoPip() async {
    if (!GStorage.setting.get(SettingBoxKey.autoPiP, defaultValue: false)) {
      return;
    }
    // if (!await FlPiP().isAvailable) return;
    // _playerListenerForEnterPip =
    //     onPlayerStatusChanged.listen((PlayerStatus status) async {
    //   if (status != PlayerStatus.playing) {
    //     bool isActive = (await FlPiP().isActive)?.status == PiPStatus.enabled;
    //     if (isActive) return;
    //     FlPiP().disable();
    //     print('disabled pip');
    //     return;
    //   }
    //   print('enable pip');
    //   FlPiP().enable(
    //     ios: FlPiPiOSConfig(
    //         enabledWhenBackground: true,
    //         videoPath: dataSource.videoSource!,
    //         audioPath: dataSource.audioSource!,
    //         packageName: 'PiliPalaX'),
    //     android: FlPiPAndroidConfig(
    //       enabledWhenBackground: true,
    //       aspectRatio: Rational(
    //         direction.value == 'vertical' ? 9 : 16,
    //         direction.value == 'horizontal' ? 9 : 16,
    //       ),
    //     ),
    //   );
    //   print('enabled pip');
    // });
  }

  // 获取实例 传参
  static PlPlayerController getInstance({
    String videoType = 'archive',
  }) {
    // 如果实例尚未创建，则创建一个新实例
    _instance ??= PlPlayerController._();
    // print('getInstance');
    // print(StackTrace.current);
    // _instance!._playerCount.value += 1;
    // print("_playerCount");
    // print(_instance!._playerCount.value);
    _videoType.value = videoType;
    return _instance!;
  }

  // 初始化资源
  Future<bool> setDataSource(
    DataSource dataSource, {
    bool autoplay = true,
    // 默认不循环
    PlaylistMode looping = PlaylistMode.none,
    // 初始化播放位置
    Duration seekTo = Duration.zero,
    // 初始化播放速度
    double speed = 1.0,
    // 硬件加速
    bool enableHA = true,
    String? hwdec,
    double? width,
    double? height,
    Duration? duration,
    // 方向
    String? direction,
    // 记录历史记录
    String bvid = '',
    int cid = 0,
    int? epid,
    int? seasonId,
    // 历史记录开关
    bool enableHeart = true,
    String? serviceId,
  }) async {
    try {
      // if (playerStatus.status.value == PlayerStatus.disabled) return;
      _currentServiceId = serviceId;

      this.dataSource = dataSource;
      // 重置控制条状态
      _showControls.value = false;
      _controlsLock.value = false;
      _autoPlay = autoplay;
      _looping = looping;
      isSkipping.value = false;
      // 初始化视频倍速
      // _playbackSpeed.value = speed;
      // 初始化数据加载状态
      dataStatus.status.value = DataStatus.loading;
      // 初始化全屏方向
      _direction.value = direction ?? 'horizontal';
      _bvid = bvid;
      _cid = cid;
      _epid = epid;
      _seasonId = seasonId;
      _enableHeart = enableHeart;
      isVideoLoaded.value = false;
      print('🔥 [Controller] isVideoLoaded 设置为 false');

      // 切换视频时清除预览缓存
      if (showSeekPreview) {
        _clearPreview();
      }

      // 重置全屏状态
      bool enableKeepFullScreen =
          setting.get(SettingBoxKey.enableKeepFullScreen, defaultValue: true);
      if (_isFullScreen.value && !enableKeepFullScreen) {
        await triggerFullScreen(status: false);
      }

      if (_videoPlayerController != null &&
          _videoPlayerController!.state.playing) {
        await pause(notify: false);
      }

      // if (_playerCount.value == 0) {
      //   return;
      // }
      // 配置Player 音轨、字幕等等
      _videoPlayerController = await _createVideoController(
          dataSource, _looping, enableHA, hwdec, width, height);
      if (_currentServiceId != serviceId) return false;
      // 获取视频时长 00:00
      _duration.value = duration ?? _videoPlayerController!.state.duration;
      updateDurationSecond();
      // 数据加载完成
      dataStatus.status.value = DataStatus.loaded;

      // listen the video player events
      if (!_listenersInitialized) {
        startListeners();
      }
      await _initializePlayer(seekTo: seekTo);
      if (_currentServiceId != serviceId) return false;
      if (videoType.value != 'live' && _cid != 0) {
        refreshSubtitles(serviceId).then((value) {
          if (_currentServiceId != serviceId) return;
          if (_vttSubtitles.isNotEmpty) {
            if (_vttSubtitlesIndex > 0 &&
                _vttSubtitlesIndex < _vttSubtitles.length) {
              setSubtitle(_vttSubtitlesIndex.value);
            } else {
              String preference = setting.get(SettingBoxKey.subtitlePreference,
                  defaultValue: SubtitlePreference.values.first.code);
              if (preference == 'on') {
                setSubtitle(1);
              } else if (preference == 'withoutAi') {
                bool found = false;
                for (int i = 1; i < _vttSubtitles.length; i++) {
                  if (_vttSubtitles[i]['language']!.startsWith('ai')) {
                    continue;
                  }
                  found = true;
                  setSubtitle(i);
                  break;
                }
                if (!found) _vttSubtitlesIndex.value = 0;
              } else {
                _vttSubtitlesIndex.value = 0;
              }
            }
          }
        });
      }
    } catch (err, stackTrace) {
      dataStatus.status.value = DataStatus.error;
      debugPrint(stackTrace.toString());
      print('plPlayer err:  $err');
      return false;
    }
    return true;
  }

  // 配置播放器
  Future<Player> _createVideoController(
    DataSource dataSource,
    PlaylistMode looping,
    bool enableHA,
    String? hwdec,
    double? width,
    double? height,
  ) async {
    // 每次配置时先移除监听
    removeListeners();
    isBuffering.value = true;
    print('🔥 [Controller] setDataSource: isBuffering 设置为 true');
    buffered.value = Duration.zero;
    _heartDuration = 0;
    _position.value = Duration.zero;
    // 初始化时清空弹幕，防止上次重叠
    danmakuController?.clear();

    // 🔥 优化：检测是否为 4K 视频
    bool is4K =
        (width != null && width >= 3840) || (height != null && height >= 2160);

    // 🔥 优化：根据视频分辨率动态调整缓冲区
    int bufferSize;
    if (is4K) {
      // 4K 视频使用更大的缓冲区 (128MB)
      bufferSize = 128 * 1024 * 1024;
      print('🎬 检测到 4K 视频，使用 128MB 缓冲区');
    } else {
      // 原有逻辑
      bufferSize = setting.get(SettingBoxKey.expandBuffer, defaultValue: false)
          ? (videoType.value == 'live' ? 64 * 1024 * 1024 : 32 * 1024 * 1024)
          : (videoType.value == 'live' ? 16 * 1024 * 1024 : 4 * 1024 * 1024);
    }

    Player player = _videoPlayerController ??
        Player(
          configuration: PlayerConfiguration(
            // 默认缓冲 4M 大小
            bufferSize: bufferSize,
          ),
        );
    var pp = player.platform as NativePlayer;

    // 🔥 优化：4K 视频额外配置
    if (is4K) {
      print('🎬 应用 4K 视频优化配置');
      // 增加预读取缓冲
      await pp.setProperty("demuxer-max-bytes", "200M");
      await pp.setProperty("demuxer-readahead-secs", "10");

      // 允许丢帧以保持流畅
      await pp.setProperty("framedrop", "vo");

      // 缓存配置
      await pp.setProperty("cache", "yes");
      await pp.setProperty("cache-secs", "15");

      // 4K 视频强制使用安全的硬件解码
      if (enableHA) {
        hwdec = 'auto-safe';
        await pp.setProperty("hwdec-codecs", "h264,hevc,vp9");
      }
    }

    // 解除倍速限制
    await pp.setProperty("af", "scaletempo2=max-speed=8");
    //  音量不一致
    if (Platform.isAndroid) {
      await pp.setProperty("volume-max", "100");
      String ao = setting.get(SettingBoxKey.useOpenSLES, defaultValue: false)
          ? "opensles,audiotrack"
          : "audiotrack,opensles";
      await pp.setProperty("ao", ao);
    }
    // video-sync=display-resample
    await pp.setProperty("video-sync",
        setting.get(SettingBoxKey.videoSync, defaultValue: 'display-resample'));
    // // vo=gpu-next & gpu-context=android & gpu-api=opengl
    // await pp.setProperty("vo", "gpu-next");
    // await pp.setProperty("gpu-context", "android");
    // await pp.setProperty("gpu-api", "opengl");
    await player.setAudioTrack(
      AudioTrack.auto(),
    );
    // 音轨
    if (dataSource.audioSource?.isNotEmpty ?? false) {
      await pp.setProperty(
        'audio-files',
        UniversalPlatform.isWindows
            ? dataSource.audioSource!.replaceAll(';', '\\;')
            : dataSource.audioSource!.replaceAll(':', '\\:'),
      );
    } else {
      await pp.setProperty(
        'audio-files',
        '',
      );
    }

    // 字幕
    if (dataSource.subFiles != '' && dataSource.subFiles != null) {
      await pp.setProperty(
        'sub-files',
        UniversalPlatform.isWindows
            ? dataSource.subFiles!.replaceAll(';', '\\;')
            : dataSource.subFiles!.replaceAll(':', '\\:'),
      );
      await pp.setProperty("subs-with-matching-audio", "no");
      await pp.setProperty("sub-forced-only", "yes");
      await pp.setProperty("blend-subtitles", "video");
    }

    _videoController = _videoController ??
        VideoController(
          player,
          configuration: VideoControllerConfiguration(
            enableHardwareAcceleration: enableHA,
            androidAttachSurfaceAfterVideoParameters: false,
            hwdec: enableHA ? hwdec : null,
          ),
        );

    player.setPlaylistMode(looping);
    if (dataSource.type == DataSourceType.asset) {
      final assetUrl = dataSource.videoSource!.startsWith("asset://")
          ? dataSource.videoSource!
          : "asset://${dataSource.videoSource!}";
      await player.open(
        Media(assetUrl, httpHeaders: dataSource.httpHeaders),
        play: false,
      );
    } else {
      await player.open(
        Media(dataSource.videoSource!, httpHeaders: dataSource.httpHeaders),
        play: false,
      );
    }
    // 音轨
    // player.setAudioTrack(
    //   AudioTrack.uri(dataSource.audioSource!),
    // );

    // 🔥 修复：初始化时将播放器音量设置为 100%
    // 只通过系统音量控制，避免双重音量调节
    try {
      await player.setVolume(100);
    } catch (_) {}

    return player;
  }

  Future refreshPlayer() async {
    Duration currentPos = _position.value;
    if (_videoPlayerController == null) {
      SmartDialog.showToast('视频播放器为空，请重新进入本页面');
      return;
    }
    if (dataSource.videoSource?.isEmpty ?? true) {
      SmartDialog.showToast('视频源为空，请重新进入本页面');
      return;
    }
    if (dataSource.audioSource?.isEmpty ?? true) {
      SmartDialog.showToast('音频源为空');
    } else {
      await (_videoPlayerController!.platform as NativePlayer).setProperty(
        'audio-files',
        UniversalPlatform.isWindows
            ? dataSource.audioSource!.replaceAll(';', '\\;')
            : dataSource.audioSource!.replaceAll(':', '\\:'),
      );
    }
    await _videoPlayerController!.open(
      Media(
        dataSource.videoSource!,
        httpHeaders: dataSource.httpHeaders,
      ),
      play: true,
    );
    seekTo(currentPos);
  }

  // 开始播放
  Future _initializePlayer({Duration seekTo = Duration.zero}) async {
    if (_instance == null) return;
    // 设置倍速
    if (videoType.value == 'live') {
      await setPlaybackSpeed(1.0);
    } else {
      if (_playbackSpeed.value != 1.0) {
        await setPlaybackSpeed(_playbackSpeed.value);
      } else {
        await setPlaybackSpeed(1.0);
      }
    }
    getVideoFit();
    // if (_looping) {
    //   await setLooping(_looping);
    // }

    // 跳转播放
    if (seekTo != Duration.zero) {
      // 🔥 修复：标记正在进行初始 seek，防止 isVideoLoaded 过早变为 true
      _isInitialSeeking = true;
      print('🔥 [Controller] 开始初始 seek，_isInitialSeeking = true');
      await this.seekTo(seekTo);
      // 🔥 修复：seek 完成后，延迟一小段时间再允许 isVideoLoaded 变为 true
      // 这样可以确保视频帧已经渲染
      await Future.delayed(const Duration(milliseconds: 100));
      _isInitialSeeking = false;
      print('🔥 [Controller] 初始 seek 完成，_isInitialSeeking = false');
    }

    // 自动播放
    if (_autoPlay) {
      await playIfExists();
      // await play(duration: duration);
    }
  }

  Future<void> autoEnterFullScreen() async {
    bool autoEnterFullscreen = GStorage.setting
        .get(SettingBoxKey.enableAutoEnter, defaultValue: false);
    if (autoEnterFullscreen) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (dataStatus.status.value != DataStatus.loaded) {
          _dataListenerForEnterFullScreen = dataStatus.status.listen((status) {
            if (status == DataStatus.loaded) {
              _dataListenerForEnterFullScreen?.cancel();
              triggerFullScreen(status: true);
            }
          });
        } else {
          triggerFullScreen(status: true);
        }
      });
    }
  }

  final List<Function(Duration position)> _positionListeners = [];
  final List<Function(PlayerStatus status)> _statusListeners = [];

  /// 播放事件监听
  void startListeners() {
    subscriptions.addAll(
      [
        videoPlayerController!.stream.playing.listen((event) {
          print(
              '🔥 [Controller] stream.playing: $event, isBuffering: ${isBuffering.value}, _isInitialSeeking: $_isInitialSeeking');
          if (event) {
            playerStatus.status.value = PlayerStatus.playing;
            // 🔥 修复：只有在非初始 seek 期间才设置 isVideoLoaded
            if (!isBuffering.value && !_isInitialSeeking) {
              isVideoLoaded.value = true;
              print(
                  '🔥 [Controller] isVideoLoaded 设置为 true (playing && !isBuffering && !_isInitialSeeking)');
            }
            // 播放时启用防休眠
            // ignore: avoid_print
            // print('🟢 播放状态监听器：视频开始播放，启用防休眠');
            WakelockManager.instance.enable();
          } else {
            playerStatus.status.value = PlayerStatus.paused;
            // 暂停时禁用防休眠
            // ignore: avoid_print
            // print('🔴 播放状态监听器：视频已暂停，禁用防休眠');
            WakelockManager.instance.disable();
          }
          videoPlayerServiceHandler.onStatusChange(
              playerStatus.status.value, isBuffering.value);

          /// 触发回调事件
          for (var element in _statusListeners) {
            // if (element != null) {
            element(event ? PlayerStatus.playing : PlayerStatus.paused);
            // }
          }
          if (videoPlayerController!.state.position.inSeconds != 0) {
            makeHeartBeat(positionSeconds.value, type: 'status');
          }
        }),
        videoPlayerController!.stream.completed.listen((event) {
          if (event) {
            playerStatus.status.value = PlayerStatus.completed;

            /// 触发回调事件
            for (var element in _statusListeners) {
              element(PlayerStatus.completed);
            }
            makeHeartBeat(positionSeconds.value, type: 'completed');
          } else {
            if (playerStatus.status.value == PlayerStatus.completed) {
              playerStatus.status.value = videoPlayerController!.state.playing
                  ? PlayerStatus.playing
                  : PlayerStatus.paused;
            }
          }
        }),
        videoPlayerController!.stream.position.listen((event) {
          _position.value = event;
          updatePositionSecond();
          if (!isSliderMoving.value) {
            _sliderPosition.value = event;
            updateSliderPositionSecond();
          }

          /// 触发回调事件
          for (var element in _positionListeners) {
            element(event);
          }
          makeHeartBeat(event.inSeconds);
        }),
        videoPlayerController!.stream.duration.listen((Duration event) {
          duration.value = event;
        }),
        videoPlayerController!.stream.buffer.listen((Duration event) {
          _buffered.value = event;
          updateBufferedSecond();
        }),
        videoPlayerController!.stream.buffering.listen((bool event) {
          print(
              '🔥 [Controller] stream.buffering: $event, playerStatus: ${playerStatus.status.value}, _isInitialSeeking: $_isInitialSeeking');
          isBuffering.value = event;
          videoPlayerServiceHandler.onStatusChange(
              playerStatus.status.value, event);
          // 🔥 修复：只有在非初始 seek 期间才设置 isVideoLoaded
          if (!event &&
              playerStatus.status.value == PlayerStatus.playing &&
              !_isInitialSeeking) {
            isVideoLoaded.value = true;
            print(
                '🔥 [Controller] isVideoLoaded 设置为 true (buffering=false && playing && !_isInitialSeeking)');
          }
        }),
        // videoPlayerController!.stream.log.listen((event) {
        //   print('videoPlayerController!.stream.log.listen');
        //   print(event);
        //   SmartDialog.showToast('视频加载日志： $event');
        // }),
        videoPlayerController!.stream.error.listen((String event) {
          // 直播的错误提示没有参考价值，均不予显示
          if (videoType.value == 'live') return;
          if (event.startsWith("Failed to open https://") ||
              event.startsWith("Can not open external file https://") ||
              //tcp: ffurl_read returned 0xdfb9b0bb
              //tcp: ffurl_read returned 0xffffff99
              event.startsWith('tcp: ffurl_read returned ')) {
            EasyThrottle.throttle('videoPlayerController!.stream.error.listen',
                const Duration(milliseconds: 10000), () {
              Future.delayed(const Duration(milliseconds: 3000), () {
                print("isBuffering.value: ${isBuffering.value}");
                print("_buffered.value: ${_buffered.value}");
                if (isBuffering.value && _buffered.value == Duration.zero) {
                  refreshPlayer();
                  SmartDialog.showToast('视频链接打开失败，重试中',
                      displayTime: const Duration(milliseconds: 500));
                }
              });
            });
            return;
          }
          print('videoPlayerController!.stream.error.listen');
          print(event);
          if (event.startsWith('Could not open codec')) {
            SmartDialog.showToast('无法加载解码器, $event，可能会切换至软解');
            return;
          }
          SmartDialog.showToast('视频加载错误，请稍等或切换网络重试');
        }),
        // videoPlayerController!.stream.volume.listen((event) {
        //   if (!mute.value && _volumeBeforeMute != event) {
        //     _volumeBeforeMute = event / 100;
        //   }
        // }),
        // 媒体通知监听
        // onPlayerStatusChanged.listen((PlayerStatus event) {
        //   videoPlayerServiceHandler.onStatusChange(event, isBuffering.value);
        // }),
        onPositionChanged.listen((Duration event) {
          EasyThrottle.throttle(
              'mediaServicePosition',
              const Duration(seconds: 1),
              () => videoPlayerServiceHandler.onPositionChange(event));
        }),
      ],
    );
  }

  /// 移除事件监听
  void removeListeners() {
    for (final s in subscriptions) {
      s.cancel();
    }
  }

  /// 跳转至指定位置
  Future<void> seekTo(Duration position, {type = 'seek'}) async {
    // if (position >= duration.value) {
    //   position = duration.value - const Duration(milliseconds: 100);
    // }
    if (position < Duration.zero) {
      position = Duration.zero;
    }
    _position.value = position;
    updatePositionSecond();
    _heartDuration = position.inSeconds;
    if (duration.value.inSeconds != 0) {
      if (type != 'slider') {
        /// 拖动进度条调节时，不等待第一帧，防止抖动
        await _videoPlayerController?.stream.buffer.first;
      }
      danmakuController?.clear();
      await _videoPlayerController?.seek(position);
      // if (playerStatus.stopped) {
      //   play();
      // }
    } else {
      print('seek duration else');
      _timerForSeek?.cancel();
      _timerForSeek =
          Timer.periodic(const Duration(milliseconds: 200), (Timer t) async {
        //_timerForSeek = null;
        if (duration.value.inSeconds != 0) {
          await _videoPlayerController?.stream.buffer.first;
          danmakuController?.clear();
          await _videoPlayerController?.seek(position);
          // if (playerStatus.status.value == PlayerStatus.paused) {
          //   play();
          // }
          t.cancel();
          _timerForSeek = null;
        }
      });
    }
  }

  /// 设置倍速
  Future<void> setPlaybackSpeed(double speed) async {
    /// TODO  _duration.value丢失
    await _videoPlayerController?.setRate(speed);
    // 移除倍速时改变弹幕速度的能力
    // try {
    //   DanmakuOption currentOption = danmakuController!.option;
    //   defaultDuration ??= currentOption.duration;
    //   DanmakuOption updatedOption = currentOption.copyWith(
    //       duration: ((defaultDuration! / speed) * playbackSpeed).round());
    //   danmakuController!.updateOption(updatedOption);
    // } catch (_) {}
    // fix 长按倍速后放开不恢复
    if (!doubleSpeedStatus.value) {
      _playbackSpeed.value = speed;
    }
  }

  // 还原默认速度
  Future<void> setDefaultSpeed() async {
    double speed =
        videoStorage.get(VideoBoxKey.playSpeedDefault, defaultValue: 1.0);
    await _videoPlayerController?.setRate(speed);
    _playbackSpeed.value = speed;
  }

  /// 设置倍速
  // Future<void> togglePlaybackSpeed() async {
  //   List<double> allowedSpeeds =
  //       PlaySpeed.values.map<double>((e) => e.value).toList();
  //   int index = allowedSpeeds.indexOf(_playbackSpeed.value);
  //   if (index < allowedSpeeds.length - 1) {
  //     setPlaybackSpeed(allowedSpeeds[index + 1]);
  //   } else {
  //     setPlaybackSpeed(allowedSpeeds[0]);
  //   }
  // }

  /// 播放视频
  /// TODO  _duration.value丢失
  Future<void> play({bool repeat = false, bool hideControls = true}) async {
    // ignore: avoid_print
    // print('🟢 PlPlayerController.play() 被调用');

    // String top = Get.currentRoute;
    // print("top:$top");
    // if (!top.startsWith('/video')) {
    //   return;
    // }
    // if (_playerCount.value == 0) return;
    // if (playerStatus.status.value == PlayerStatus.disabled) return;
    // 播放时自动隐藏控制条
    controls = !hideControls;
    // repeat为true，将从头播放
    if (repeat) {
      // await seekTo(Duration.zero);
      await seekTo(Duration.zero, type: "slider");
    }

    await _videoPlayerController?.play();

    playerStatus.status.value = PlayerStatus.playing;
    // screenManager.setOverlays(false);

    audioSessionHandler.setActive(true);

    // 启用防休眠
    // ignore: avoid_print
    // print('🟢 准备调用 WakelockManager.instance.enable()');
    WakelockManager.instance.enable();
    // ignore: avoid_print
    // print('🟢 已调用 WakelockManager.instance.enable()');

    // Future.delayed(const Duration(milliseconds: 100), () {
    //   getCurrentVolume();
    // });
  }

  /// 暂停播放
  Future<void> pause({bool notify = true, bool isInterrupt = false}) async {
    // ignore: avoid_print
    // print('🔴 PlPlayerController.pause() 被调用');

    await _videoPlayerController?.pause();
    playerStatus.status.value = PlayerStatus.paused;

    // 主动暂停时让出音频焦点
    if (!isInterrupt) {
      audioSessionHandler.setActive(false);
    }

    // 禁用防休眠
    // ignore: avoid_print
    // print('🔴 准备调用 WakelockManager.instance.disable()');
    WakelockManager.instance.disable();
    // ignore: avoid_print
    // print('🔴 已调用 WakelockManager.instance.disable()');
  }

  // 感觉用这个管理状态也不是很好用
  void disable() async {
    if (floatingManager.containsFloating(globalId)) return;
    String top = Get.currentRoute;
    // print("top:$top");
    if (!top.startsWith('/video') && !top.startsWith('/live')) {
      // playerStatus.status.value = PlayerStatus.disabled;
      _heartDuration = 0;
      _videoPlayerController?.stop();
      videoPlayerServiceHandler.clear();
      return;
    }
  }

  /// 更改播放状态
  Future<void> togglePlay() async {
    feedBack();
    if (playerStatus.playing) {
      pause();
    } else {
      play();
    }
  }

  /// 隐藏控制条
  void _hideTaskControls() {
    if (_timer != null) {
      _timer!.cancel();
    }
    Duration waitingTime = Duration(seconds: enableLongShowControl ? 30 : 3);
    _timer = Timer(waitingTime, () {
      if (!isSliderMoving.value) {
        controls = false;
      }
      _timer = null;
    });
  }

  /// 调整播放时间
  onChangedSlider(double v) {
    _sliderPosition.value = Duration(seconds: v.floor());
    updateSliderPositionSecond();
  }

  void onChangedSliderStart() {
    _isSliderMoving.value = true;
  }

  void onUpdatedSliderProgress(Duration value) {
    _sliderTempPosition.value = value;
    _sliderPosition.value = value;
    updateSliderPositionSecond();
  }

  void onChangedSliderEnd() {
    feedBack();
    _isSliderMoving.value = false;
    _hideTaskControls();
  }

  /// 音量
  Future<void> getCurrentVolume() async {
    // mac try...catch
    try {
      _currentVolume.value = (await FlutterVolumeController.getVolume())!;
    } catch (_) {}
  }

  Future<void> setVolume(double volumeNew,
      {bool videoPlayerVolume = false}) async {
    if (volumeNew < 0.0) {
      volumeNew = 0.0;
    } else if (volumeNew > 1.0) {
      volumeNew = 1.0;
    }
    if (volume.value == volumeNew) {
      return;
    }
    volume.value = volumeNew;

    // 🔥 修复：只调节系统音量，不调节播放器音量
    // 播放器音量保持在 100%，避免双重音量调节导致音量过小
    try {
      FlutterVolumeController.updateShowSystemUI(false);
      await FlutterVolumeController.setVolume(volumeNew);
    } catch (err) {
      print(err);
    }

    // 确保播放器音量始终为 100%
    try {
      await _videoPlayerController?.setVolume(100);
    } catch (_) {}
  }

  void volumeUpdated() {
    showVolumeStatus.value = true;
    _timerForShowingVolume?.cancel();
    _timerForShowingVolume = Timer(const Duration(seconds: 1), () {
      showVolumeStatus.value = false;
    });
  }

  /// 亮度
  // Future<void> getCurrentBrightness() async {
  //   try {
  //     _currentBrightness.value = await ScreenBrightness().current;
  //   } catch (e) {
  //     throw 'Failed to get current brightness';
  //     //return 0;
  //   }
  // }

  // Future<void> setBrightness(double brightness) async {
  //   try {
  //     this.brightness.value = brightness;
  //     await ScreenBrightness.instance.setSystemScreenBrightness(brightness);
  //   } catch (e) {
  //     throw 'Failed to set brightness';
  //   }
  // }

  // Future<void> resetBrightness() async {
  //   try {
  //     await ScreenBrightness().resetScreenBrightness();
  //   } catch (e) {
  //     throw 'Failed to reset brightness';
  //   }
  // }

  /// Toggle Change the videofit accordingly
  void toggleVideoFit() {
    showDialog(
      context: Get.context!,
      builder: (context) {
        return AlertDialog(
          title: const Text('视频尺寸'),
          content: StatefulBuilder(builder: (context, StateSetter setState) {
            return Wrap(
              alignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 2,
              children: [
                for (var i in videoFitType) ...[
                  if (_videoFit.value == i['attr']) ...[
                    FilledButton(
                      onPressed: () async {
                        _videoFit.value = i['attr'];
                        _videoFitDesc.value = i['desc'];
                        setVideoFit();
                        Get.back();
                      },
                      child: Text(i['desc']),
                    ),
                  ] else ...[
                    FilledButton.tonal(
                      onPressed: () async {
                        _videoFit.value = i['attr'];
                        _videoFitDesc.value = i['desc'];
                        setVideoFit();
                        Get.back();
                      },
                      child: Text(i['desc']),
                    ),
                  ]
                ]
              ],
            );
          }),
        );
      },
    );
  }

  /// 缓存fit
  Future<void> setVideoFit() async {
    List attrs = videoFitType.map((e) => e['attr']).toList();
    int index = attrs.indexOf(_videoFit.value);
    SmartDialog.showToast(videoFitType[index]['toast'],
        displayTime: const Duration(seconds: 1));
    videoStorage.put(VideoBoxKey.cacheVideoFit, index);
  }

  /// 读取fit
  Future<void> getVideoFit() async {
    int fitValue = videoStorage.get(VideoBoxKey.cacheVideoFit, defaultValue: 0);
    var attr = videoFitType[fitValue]['attr'];
    // 由于none与scaleDown涉及视频原始尺寸，需要等待视频加载后再设置，否则尺寸会变为0，出现错误;
    if (attr == BoxFit.none || attr == BoxFit.scaleDown) {
      if (buffered.value == Duration.zero) {
        attr = BoxFit.contain;
        _dataListenerForVideoFit = dataStatus.status.listen((status) {
          if (status == DataStatus.loaded) {
            _dataListenerForVideoFit?.cancel();
            int fitValue =
                videoStorage.get(VideoBoxKey.cacheVideoFit, defaultValue: 0);
            var attr = videoFitType[fitValue]['attr'];
            if (attr == BoxFit.none || attr == BoxFit.scaleDown) {
              _videoFit.value = attr;
            }
          }
        });
      }
      // fill不应该在竖屏视频生效
    } else if (attr == BoxFit.fill && direction.value == 'vertical') {
      attr = BoxFit.contain;
    }
    _videoFit.value = attr;
    _videoFitDesc.value = videoFitType[fitValue]['desc'];
  }

  /// 设置后台播放
  Future<void> setBackgroundPlay(bool val) async {
    setting.put(SettingBoxKey.enableBackgroundPlay, val);
    videoPlayerServiceHandler.revalidateSetting();
  }

  /// 读取亮度
  // Future<void> getVideoBrightness() async {
  //   double brightnessValue =
  //       videoStorage.get(VideoBoxKey.videoBrightness, defaultValue: 0.5);
  //   setBrightness(brightnessValue);
  // }

  set controls(bool visible) {
    _showControls.value = visible;
    _timer?.cancel();
    if (visible) {
      _hideTaskControls();
    }
  }

  void hiddenControls(bool val) {
    showControls.value = val;
  }

  /// 设置长按倍速状态 live模式下禁用
  void setDoubleSpeedStatus(bool val) async {
    if (videoType.value == 'live') {
      return;
    }
    if (controlsLock.value) {
      return;
    }
    _doubleSpeedStatus.value = val;
    if (val) {
      await setPlaybackSpeed(
          enableAutoLongPressSpeed ? playbackSpeed * 2 : longPressSpeed);
    } else {
      print(playbackSpeed);
      await setPlaybackSpeed(playbackSpeed);
    }
  }

  /// 关闭控制栏
  void onLockControl(bool val) {
    feedBack();
    _controlsLock.value = val;
    showControls.value = !val;
  }

  void toggleFullScreen(bool val) {
    _isFullScreen.value = val;
  }

  // 应用内小窗
  bool triggerFloatingWindow(VideoIntroController? videoIntroController,
      BangumiIntroController? bangumiIntroController) {
    if (videoController == null) {
      return false;
    }
    Widget iconButton(IconData icon, VoidCallback onPressed) {
      return Expanded(
        child: IconButton(
          constraints: const BoxConstraints(),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
              return Theme.of(Get.context!)
                  .colorScheme
                  .surface
                  .withOpacity(0.9);
            }),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
          ),
          onPressed: onPressed,
          icon: Icon(icon, color: Theme.of(Get.context!).colorScheme.onSurface),
        ),
      );
    }

    const TextStyle subTitleStyle = TextStyle(
      height: 1.3,
      fontSize: 60.0,
      letterSpacing: 0.1,
      wordSpacing: 0.1,
      color: Color(0xffffffff),
      fontWeight: FontWeight.normal,
      backgroundColor: Color(0xaa000000),
    );

    bool isLive =
        videoIntroController == null && bangumiIntroController == null;
    double? videoHeight = videoPlayerController?.state.height?.toDouble();
    double? videoWidth = videoPlayerController?.state.width?.toDouble();
    // bool isVertical = direction.value == 'vertical';
    // 长宽比
    double aspectRatio =
        direction.value == 'horizontal' ? 9.0 / 16.0 : 16.0 / 9.0;

    if (videoWidth != null && videoHeight != null) {
      if ((videoWidth > videoHeight) ^ (direction.value != 'horizontal')) {
        aspectRatio = videoHeight / videoWidth;
      }
    }

    double floatingWidth = aspectRatio > 1 ? 150.0 : 240.0;
    double extentHeight = 40.0;
    double floatingHeight = floatingWidth * aspectRatio + extentHeight;

    Widget baseWindow = SizedBox(
      width: floatingWidth,
      height: floatingHeight,
      child: Column(
        children: [
          SizedBox(
            width: floatingWidth,
            height: floatingHeight - extentHeight,
            child: InkWell(
              onTap: () {
                floatingManager.closeFloating(globalId);
                if (videoIntroController != null) {
                  videoIntroController.openVideoDetail();
                } else if (bangumiIntroController != null) {
                  bangumiIntroController.openVideoDetail();
                } else {
                  // 直播模式：重新打开直播间
                  if (videoType.value == 'live' && _liveRoomId != null) {
                    Get.toNamed('/liveRoom?roomid=$_liveRoomId');
                  } else {
                    pauseIfExists();
                  }
                }
              },
              child: Video(
                controller: videoController!,
                controls: NoVideoControls,
                pauseUponEnteringBackgroundMode:
                    !_continuePlayInBackground.value,
                resumeUponEnteringForegroundMode: true,
                // 字幕尺寸调节
                subtitleViewConfiguration: const SubtitleViewConfiguration(
                    style: subTitleStyle, padding: EdgeInsets.all(24.0)),
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(
            width: floatingWidth,
            height: extentHeight,
            child: Row(children: [
              // if (videoIntroController != null &&
              //         videoIntroController.hasNextEpisode() ||
              //     bangumiIntroController != null &&
              //         bangumiIntroController.hasNextEpisode())
              // iconButton(Icons.skip_next, () {
              //   if (videoIntroController != null) {
              //     videoIntroController.nextPlay();
              //   } else if (bangumiIntroController != null) {
              //     bangumiIntroController.nextPlay();
              //   }
              // }),
              if (!isLive)
                iconButton(
                  MdiIcons.rewind10,
                  () => seekTo(position.value - const Duration(seconds: 10),
                      type: 'slide'),
                ),
              // 直播和视频都显示播放/暂停按钮
              Obx(
                () => iconButton(
                  playerStatus.playing ? Icons.pause : Icons.play_arrow,
                  () => togglePlay(),
                ),
              ),
              if (!isLive)
                iconButton(
                  MdiIcons.fastForward10,
                  () => seekTo(position.value + const Duration(seconds: 10),
                      type: 'slide'),
                ),
              iconButton(Icons.close, () {
                floatingManager.closeFloating(globalId);
                pauseIfExists();
              }),
            ]),
          ),
        ],
      ),
    );
    // pauseIfExists();
    // int maxLength = max(videoPlayerController!.state.width!,
    //     videoPlayerController!.state.height!);
    // if (maxLength <= 0) {
    //   SmartDialog.showToast('视频尺寸异常，无法开启小窗');
    //   return;
    // }
    // // dp 转像素
    // double lengthLimit = 0.8 *
    //     min(Get.width, Get.height) *
    //     MediaQuery.of(Get.context!).devicePixelRatio;
    // android_window.open(
    //   size: Size(
    //     videoPlayerController!.state.width! / maxLength * lengthLimit,
    //     videoPlayerController!.state.height! / maxLength * lengthLimit,
    //   ),
    //   position: const Offset(100, 300),
    // );
    // await Future.delayed(const Duration(milliseconds: 300));
    // dataSource.startAt = position.value;
    // final response = await android_window.post(
    //   'play',
    //   // dataSource,
    //   json.encode(dataSource.toJson()),
    // );
    // SmartDialog.showToast(response.toString());

    // if (floatingWindow != null) {
    //   floatingWindow!.close();
    // }
    // floatingManager.closeFloating(globalId);
    // 对于直播流，确保播放器状态正常
    if (videoType.value == 'live') {
      // 如果播放器已暂停，尝试恢复播放
      if (videoPlayerController?.state.playing == false) {
        playIfExists();
      }
    }

    floatingWindow = floatingManager.createFloating(
      globalId,
      Floating(
        ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: baseWindow,
        ),
        isPosCache: true,
        slideType: FloatingSlideType.onRightAndTop,
        right: 10,
        top: 100,
        moveOpacity: 0.5,
        slideBottomHeight: 20,
      ),
    );
    floatingWindow!.open(Get.context!);
    return true;
  }

  // 全屏
  Future<void> triggerFullScreen({bool status = true}) async {
    // print('triggerFullScreen: status=$status, current=${isFullScreen.value}');
    stopScreenTimer();
    FullScreenMode mode = FullScreenModeCode.fromCode(
        setting.get(SettingBoxKey.fullScreenMode, defaultValue: 0))!;
    bool removeSafeArea = setting.get(SettingBoxKey.videoPlayerRemoveSafeArea,
        defaultValue: false);
    if (!isFullScreen.value && status) {
      // StatusBarControl.setHidden(true, animation: StatusBarAnimation.FADE);
      toggleStatusBar(true);

      /// 按照视频宽高比决定全屏方向
      toggleFullScreen(true);
      await Future.delayed(const Duration(milliseconds: 10));

      /// 进入全屏
      if (mode == FullScreenMode.none) {
        return;
      }
      if (mode == FullScreenMode.gravity) {
        fullAutoModeForceSensor();
        return;
      }
      if (mode == FullScreenMode.vertical ||
          (mode == FullScreenMode.auto && direction.value == 'vertical') ||
          (mode == FullScreenMode.ratio &&
              (Get.height / Get.width < 1.25 ||
                  direction.value == 'vertical'))) {
        await verticalScreenForTwoSeconds();
      } else {
        await landScape();
      }
    } else if (isFullScreen.value && !status) {
      // StatusBarControl.setHidden(false, animation: StatusBarAnimation.FADE);
      // print('Exiting fullscreen, removeSafeArea: $removeSafeArea');
      if (!removeSafeArea) showStatusBar();
      toggleFullScreen(false);
      if (mode == FullScreenMode.none) {
        return;
      }
      if (!setting.get(SettingBoxKey.horizontalScreen, defaultValue: false)) {
        await verticalScreenForTwoSeconds();
      } else {
        await autoScreen();
      }
    }
  }

  void addPositionListener(Function(Duration position) listener) =>
      _positionListeners.add(listener);
  void removePositionListener(Function(Duration position) listener) =>
      _positionListeners.remove(listener);
  void addStatusLister(Function(PlayerStatus status) listener) =>
      _statusListeners.add(listener);
  void removeStatusLister(Function(PlayerStatus status) listener) =>
      _statusListeners.remove(listener);

  /// 截屏
  Future screenshot() async {
    final Uint8List? screenshot =
        await _videoPlayerController!.screenshot(format: 'image/png');
    return screenshot;
  }

  Future<void> videoPlayerClosed() async {
    _timer?.cancel();
    _timerForVolume?.cancel();
    _timerForGettingVolume?.cancel();
    timerForTrackingMouse?.cancel();
    _timerForSeek?.cancel();

    // 释放防休眠锁
    WakelockManager.instance.disable();
  }

  // 记录播放记录
  Future makeHeartBeat(int progress, {type = 'playing'}) async {
    if (!_enableHeart || MineController.anonymity) {
      return false;
    }
    if (videoType.value == 'live') {
      return;
    }
    // print("playerStatus.status.value: ${playerStatus.status.value}");
    // print("type: $type");
    bool isComplete = playerStatus.status.value == PlayerStatus.completed ||
        type == 'completed';
    // 播放状态变化时，更新
    if (type == 'status' || type == 'completed') {
      await VideoHttp.heartBeat(
        bvid: _bvid,
        cid: _cid,
        progress: isComplete ? -1 : progress,
        epid: _epid,
        seasonId: _seasonId,
      );
      return;
    }
    // 正常播放时，间隔3秒更新一次
    if (progress - _heartDuration >= 3) {
      _heartDuration = progress;
      await VideoHttp.heartBeat(
        bvid: _bvid,
        cid: _cid,
        progress: progress,
        epid: _epid,
        seasonId: _seasonId,
      );
    }
  }

  setPlayRepeat(PlayRepeat type) {
    playRepeat = type;
    videoStorage.put(VideoBoxKey.playRepeat, type.value);
  }

  void putDanmakuSettings() {
    setting.put(SettingBoxKey.danmakuWeight, danmakuWeight.value);
    setting.put(SettingBoxKey.danmakuBlockType, blockTypes);
    setting.put(SettingBoxKey.danmakuShowArea, showArea);
    setting.put(SettingBoxKey.danmakuOpacity, opacityVal);
    setting.put(SettingBoxKey.danmakuFontScale, fontSizeVal);
    setting.put(SettingBoxKey.danmakuDuration, danmakuDurationVal);
    setting.put(SettingBoxKey.strokeWidth, strokeWidth);
    setting.put(SettingBoxKey.fontWeight, fontWeight);
    setting.put(SettingBoxKey.danmakuMassiveMode, massiveMode);
  }

  /// 上次请求预览时的秒数
  int _lastPreviewSeconds = 0;

  /// 更新预览索引
  void updatePreviewIndex(int seconds) {
    _lastPreviewSeconds = seconds;
    if (_videoShotError) return;
    if (_videoShotData == null) {
      if (!_videoShotLoading) {
        _videoShotLoading = true;
        getVideoShot().then((_) {
          // 数据加载完成后，如果仍在拖动进度条，重新调用更新预览索引
          if (_videoShotData != null && _isSliderMoving.value) {
            updatePreviewIndex(_lastPreviewSeconds);
          }
        });
      }
      return;
    }
    if (!showPreview.value) {
      showPreview.value = true;
    }
    previewIndex.value = max(
      0,
      (_videoShotData!.index.where((item) => item <= seconds).length - 2),
    );
  }

  /// 清除预览缓存
  void _clearPreview() {
    showPreview.value = false;
    previewIndex.value = null;
    _videoShotData = null;
    _videoShotLoading = false;
    _videoShotError = false;
    previewCache
      ?..forEach((_, ref) {
        try {
          ref.target?.dispose();
        } catch (_) {}
      })
      ..clear();
    previewCache = null;
  }

  /// 获取视频截图数据
  Future<void> getVideoShot() async {
    if (_bvid.isEmpty || _cid == 0) {
      _videoShotError = true;
      _videoShotLoading = false;
      return;
    }
    try {
      var res = await Request().get(
        Api.videoShot,
        data: {
          'bvid': _bvid,
          'cid': _cid,
          'index': 1,
        },
        options: Options(
          headers: {
            'user-agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'referer': 'https://www.bilibili.com/video/$_bvid',
          },
        ),
      );
      if (res.data['code'] == 0) {
        final data = VideoShotData.fromJson(res.data['data']);
        if (data.index.isNotEmpty) {
          _videoShotData = data;
          _videoShotLoading = false;
          return;
        }
      }
      _videoShotError = true;
      _videoShotLoading = false;
    } catch (_) {
      _videoShotError = true;
      _videoShotLoading = false;
    }
  }

  Future<void> dispose() async {
    // 每次减1，最后销毁
    // if (type == 'single' && playerCount.value > 1) {
    //   _playerCount.value -= 1;
    //   _heartDuration = 0;
    //   pause();
    //   return;
    // }
    // _playerCount.value = 0;
    pause();

    // 释放防休眠锁
    WakelockManager.instance.disable();

    try {
      _clearPreview();
      _timer?.cancel();
      _timerForVolume?.cancel();
      _timerForGettingVolume?.cancel();
      timerForTrackingMouse?.cancel();
      _timerForSeek?.cancel();
      // _position.close();
      _playerEventSubs?.cancel();
      // _sliderPosition.close();
      // _sliderTempPosition.close();
      // _isSliderMoving.close();
      // _duration.close();
      // _buffered.close();
      // _showControls.close();
      // _controlsLock.close();

      // playerStatus.status.close();
      // dataStatus.status.close();
      _dataListenerForVideoFit?.cancel();
      _dataListenerForEnterFullScreen?.cancel();
      _playerListenerForEnterPip?.cancel();

      if (_videoPlayerController != null) {
        var pp = _videoPlayerController!.platform as NativePlayer;
        await pp.setProperty('audio-files', '');
        removeListeners();
        await _videoPlayerController?.dispose();
        _videoPlayerController = null;
      }
      _instance = null;
      videoPlayerServiceHandler.clear();
    } catch (err) {
      print(err);
    }
  }

  Future refreshSubtitles([String? serviceId]) async {
    if (serviceId != null && serviceId != _currentServiceId) return;
    _vttSubtitles.clear();
    Map res = await VideoHttp.subtitlesJson(bvid: _bvid, cid: _cid);
    if (serviceId != null && serviceId != _currentServiceId) return;
    if (!res["status"]) {
      // SmartDialog.showToast('查询字幕错误，${res["msg"]}');
      SmartDialog.showToast('查询字幕错误');
    }
    if (res["data"].length == 0) {
      return;
    }
    var subs = await VideoHttp.vttSubtitles(res["data"]);
    if (serviceId != null && serviceId != _currentServiceId) return;
    _vttSubtitles.value = subs;
    // if (_vttSubtitles.isEmpty) {
    //   SmartDialog.showToast('字幕均加载失败');
    // }
    return;
  }

  // 设定字幕轨道
  setSubtitle(int index) {
    if (index == 0) {
      _videoPlayerController?.setSubtitleTrack(SubtitleTrack.no());
      _vttSubtitlesIndex.value = 0;
      return;
    }
    Map<String, String> s = _vttSubtitles[index];
    debugPrint(s['text']);
    _videoPlayerController?.setSubtitleTrack(SubtitleTrack.data(
      s['text']!,
      title: s['title']!,
      language: s['language']!,
    ));
    _vttSubtitlesIndex.value = index;
  }

  void setContinuePlayInBackground(bool? status) {
    _continuePlayInBackground.value =
        status ?? !_continuePlayInBackground.value;
    setting.put(SettingBoxKey.continuePlayInBackground,
        _continuePlayInBackground.value);
  }

  void setOnlyPlayAudio(bool? status) {
    _onlyPlayAudio.value = status ?? !_onlyPlayAudio.value;
    videoPlayerController?.setVideoTrack(
        _onlyPlayAudio.value ? VideoTrack.no() : VideoTrack.auto());
  }
}
