import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:PiliPalaX/services/service_locator.dart';
import 'package:auto_orientation/auto_orientation.dart';
// import 'package:fl_pip/fl_pip.dart';
// import 'package:fl_pip/fl_pip.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:nil/nil.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/common/widgets/enhanced_hero.dart';
import 'package:PiliPalaX/http/user.dart';
import 'package:PiliPalaX/models/common/search_type.dart';
import 'package:PiliPalaX/pages/video/introduction/bangumi/index.dart';
import 'package:PiliPalaX/pages/danmaku/view.dart';
import 'package:PiliPalaX/pages/video/reply/index.dart';
import 'package:PiliPalaX/pages/video/controller.dart';
import 'package:PiliPalaX/pages/video/introduction/detail/index.dart';
import 'package:PiliPalaX/pages/video/related/index.dart';
import 'package:PiliPalaX/plugin/pl_player/index.dart';
import 'package:PiliPalaX/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPalaX/utils/storage.dart';

import '../../../services/shutdown_timer_service.dart';
import 'widgets/header_control.dart';
import 'package:PiliPalaX/common/widgets/spring_physics.dart';
import 'package:flutter_floating/floating/floating.dart';
import 'package:flutter_floating/floating/manager/floating_manager.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class VideoDetailPage extends StatefulWidget {
  const VideoDetailPage({super.key});

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();
}

class _VideoDetailPageState extends State<VideoDetailPage>
    with TickerProviderStateMixin, RouteAware {
  late VideoDetailController videoDetailController;
  PlPlayerController? plPlayerController;
  late StreamController<double> appbarStream;
  late VideoIntroController videoIntroController;
  late BangumiIntroController bangumiIntroController;
  late String heroTag;

  PlayerStatus playerStatus = PlayerStatus.playing;
  double doubleOffset = 0;

  final Box<dynamic> localCache = GStorage.localCache;
  final Box<dynamic> setting = GStorage.setting;
  late Future _futureBuilderFuture;
  // 自动退出全屏
  late bool autoExitFullscreen;
  late bool horizontalScreen;
  late bool enableVerticalExpand;
  late bool autoPiP;
  late bool pipNoDanmaku;
  late bool removeSafeArea;
  late bool showStatusBarBackgroundColor;
  // 生命周期监听
  // late final AppLifecycleListener _lifecycleListener;
  // bool isShowing = true;
  RxBool isFullScreen = false.obs;
  late StreamSubscription<bool> fullScreenStatusListener;
  // late final MethodChannel onUserLeaveHintListener;
  // StreamSubscription<Duration>? _bufferedListener;
  final RxString _layoutDirection = 'horizontal'.obs;
  StreamSubscription<String>? _directionSubscription;
  bool _playerInitFinished = false;
  bool _introInitFinished = false;
  bool _replyInitFinished = false;

  Widget _buildIntroDelayed(Widget child) {
    if (!_introInitFinished) return const SizedBox();
    return child;
  }

  Widget _buildReplyDelayed(Widget child) {
    if (!_replyInitFinished) return const SizedBox();
    return child;
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        videoSourceInit();
        setState(() {
          _playerInitFinished = true;
        });
      }
    })
        .then((_) => Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                setState(() {
                  _introInitFinished = true;
                });
              }
            }))
        .then((_) => Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                setState(() {
                  _replyInitFinished = true;
                });
              }
            }));
    if (Get.arguments != null) {
      if (Get.arguments['heroTag'] != null) {
        heroTag = Get.arguments['heroTag'];
      }
      if (Get.arguments['videoItem'] != null) {
        var videoItem = Get.arguments['videoItem'];
        try {
          if (videoItem.isVertical) {
            _layoutDirection.value = 'vertical';
          }
        } catch (e) {
          // 兼容旧逻辑或未实现isVertical的模型
          try {
            var dimension = videoItem.dimension;
            if (dimension != null) {
              if (dimension.width < dimension.height) {
                _layoutDirection.value = 'vertical';
              }
            } else {
              try {
                if (videoItem.rcmdReason != null &&
                    videoItem.rcmdReason.contains('竖屏')) {
                  _layoutDirection.value = 'vertical';
                }
              } catch (_) {}
            }
          } catch (_) {}
        }
      }
    }
    videoDetailController = Get.put(VideoDetailController(), tag: heroTag);
    if (!videoDetailController.autoPlay.value &&
        floatingManager.containsFloating(globalId)) {
      PlPlayerController.pauseIfExists();
    }
    videoIntroController = Get.put(VideoIntroController(), tag: heroTag);
    // videoIntroController.videoDetail.listen((value) {
    //   if (!context.mounted) return;
    //   videoPlayerServiceHandler.onVideoDetailChange(
    //       value, videoDetailController.cid.value);
    // });
    bangumiIntroController = Get.put(BangumiIntroController(), tag: heroTag);
    // bangumiIntroController.bangumiDetail.listen((value) {
    //   if (!context.mounted) return;
    //   videoPlayerServiceHandler.onVideoDetailChange(
    //       value, videoDetailController.cid.value);
    // });
    // videoDetailController.cid.listen((p0) {
    //   if (!context.mounted) return;
    //   videoPlayerServiceHandler.onVideoDetailChange(
    //       bangumiIntroController.bangumiDetail.value, p0);
    // });
    autoExitFullscreen =
        setting.get(SettingBoxKey.enableAutoExit, defaultValue: true);
    horizontalScreen =
        setting.get(SettingBoxKey.horizontalScreen, defaultValue: false);
    autoPiP = setting.get(SettingBoxKey.autoPiP, defaultValue: false);
    pipNoDanmaku = setting.get(SettingBoxKey.pipNoDanmaku, defaultValue: true);
    enableVerticalExpand =
        setting.get(SettingBoxKey.enableVerticalExpand, defaultValue: false);
    removeSafeArea = setting.get(SettingBoxKey.videoPlayerRemoveSafeArea,
        defaultValue: false);
    showStatusBarBackgroundColor = setting.get(
        SettingBoxKey.videoPlayerShowStatusBarBackgroundColor,
        defaultValue: false);
    if (removeSafeArea) toggleStatusBar(true);
    floatingManager.closeFloating(globalId);
    // videoSourceInit();
    appbarStreamListen();
    // lifecycleListener();
    autoScreen();

    // onUserLeaveHintListener = const MethodChannel("onUserLeaveHint");
    // onUserLeaveHintListener.setMethodCallHandler((call) async {
    //   if (call.method == 'onUserLeaveHint') {
    //     if (autoPiP &&
    //         plPlayerController != null &&
    //         playerStatus == PlayerStatus.playing) {
    //       autoEnterPip();
    //     }
    //   }
    // });
    // _animationController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(milliseconds: 300),
    // );
    // _animation = Tween<double>(
    //   begin: MediaQuery.of(context).orientation == Orientation.landscape
    //       ? context.height
    //       : ((enableVerticalExpand &&
    //               plPlayerController?.direction.value == 'vertical')
    //           ? context.width * 5 / 4
    //           : context.width * 9 / 16),
    //   end: 0,
    // ).animate(_animationController);
  }

  // 获取视频资源，初始化播放器
  Future<void> videoSourceInit() async {
    _futureBuilderFuture = videoDetailController.queryVideoUrl();
    if (videoDetailController.autoPlay.value) {
      plPlayerController = videoDetailController.plPlayerController;
      plPlayerController!.addStatusLister(playerListener);
      listenFullScreenStatus();
      listenDirectionStatus();
      await plPlayerController!.autoEnterFullScreen();
      // Future.wait([_futureBuilderFuture]).then((result) {
      //   autoEnterPip();
      // });
    } else {
      _futureBuilderFuture.then((value) async {
        if (!mounted) return;
        if (value['status']) {
          // fix: 手动播放首个视频前媒体通知不完整
          videoPlayerServiceHandler.onStatusChange(PlayerStatus.paused, false);
          videoDetailController.playerInit(autoplay: false);
          plPlayerController = videoDetailController.plPlayerController;
          plPlayerController!.addStatusLister(playerListener);
          listenFullScreenStatus();
          listenDirectionStatus();
        }
      });
    }
  }

  void listenDirectionStatus() {
    if (plPlayerController != null) {
      _layoutDirection.value = plPlayerController!.direction.value;
      _directionSubscription = plPlayerController!.direction.listen((value) {
        _layoutDirection.value = value;
      });
    }
  }

  // void autoEnterPip() {
  //   String top = Get.currentRoute;
  //   if (autoPiP && (top.startsWith('/video') || top.startsWith('/live') || floatingManager.containsFloating(globalId))) {
  //     FlPiP().enable(
  //         ios: FlPiPiOSConfig(
  //             enabledWhenBackground: true,
  //             videoPath: videoDetailController.videoUrl,
  //             audioPath: videoDetailController.audioUrl,
  //             packageName: null),
  //         android: FlPiPAndroidConfig(
  //           enabledWhenBackground: true,
  //           aspectRatio: Rational(
  //             videoDetailController.data.dash!.video!.first.width!,
  //             videoDetailController.data.dash!.video!.first.height!,
  //           ),
  //         ));
  //   }
  // }

  // 流
  appbarStreamListen() {
    appbarStream = StreamController<double>();
  }

  // 播放器状态监听
  void playerListener(PlayerStatus? status) async {
    playerStatus = status!;
    switch (status) {
      case PlayerStatus.playing:
        if (videoDetailController.isShowCover.value) {
          videoDetailController.isShowCover.value = false;
        }
        break;
      case PlayerStatus.completed:
        shutdownTimerService.handleWaitingFinished();
        bool notExitFlag = false;

        /// 顺序播放 列表循环
        if (plPlayerController!.playRepeat != PlayRepeat.singleCycle) {
          if (videoDetailController.videoType == SearchType.video) {
            notExitFlag = videoIntroController.nextPlay();
          }
          if (videoDetailController.videoType == SearchType.media_bangumi ||
              videoDetailController.videoType == SearchType.media_ft) {
            notExitFlag = bangumiIntroController.nextPlay();
          }
        }

        /// 单个循环
        if (plPlayerController!.playRepeat == PlayRepeat.singleCycle) {
          notExitFlag = true;
          plPlayerController!.play(repeat: true);
        }

        if (notExitFlag) {
          plPlayerController!.isSkipping.value = true;
        }

        // 结束播放退出全屏
        // if (!notExitFlag && autoExitFullscreen) {
        //   plPlayerController!.triggerFullScreen(status: false);
        // }
        // 播放完展示控制栏
        // if (videoDetailController.floating != null && !notExitFlag) {
        //   PiPStatus currentStatus =
        //       await videoDetailController.floating!.pipStatus;
        //   if (currentStatus == PiPStatus.disabled) {
        //     plPlayerController!.onLockControl(false);
        //   }
        // }
        break;
      case PlayerStatus.paused:
        break;
      case PlayerStatus.disabled:
        videoDetailController.isShowCover.value = true;
        break;
    }
  }

  // 继续播放或重新播放
  void continuePlay() async {
    plPlayerController!.play();
  }

  /// 未开启自动播放时触发播放
  Future<void> handlePlay() async {
    if (plPlayerController == null) {
      SmartDialog.showToast('播放器初始化失败，请重新进入本页面');
      return;
    }
    plPlayerController!.play();
    await plPlayerController!.autoEnterFullScreen();
    videoDetailController.autoPlay.value = true;
    // autoEnterPip();
  }

  // // 生命周期监听
  // void lifecycleListener() {
  //   _lifecycleListener = AppLifecycleListener(
  //     onResume: () => _handleTransition('resume'),
  //     // 后台
  //     onInactive: () => _handleTransition('inactive'),
  //     // 在Android和iOS端不生效
  //     onHide: () => _handleTransition('hide'),
  //     onShow: () => _handleTransition('show'),
  //     onPause: () => _handleTransition('pause'),
  //     onRestart: () => _handleTransition('restart'),
  //     onDetach: () => _handleTransition('detach'),
  //     // 只作用于桌面端
  //     onExitRequested: () {
  //       ScaffoldMessenger.maybeOf(context)
  //           ?.showSnackBar(const SnackBar(content: Text("拦截应用退出")));
  //       return Future.value(AppExitResponse.cancel);
  //     },
  //   );
  // }

  void listenFullScreenStatus() {
    isFullScreen.value = plPlayerController!.isFullScreen.value;
    fullScreenStatusListener =
        plPlayerController!.isFullScreen.listen((bool status) {
      if (status) {
        videoDetailController.hiddenReplyReplyPanel();
        // hideStatusBar();
      }
      isFullScreen.value = status;
      // if (mounted) {
      //   setState(() {});
      // }
      // if (!status) {
      // showStatusBar();
      // if (horizontalScreen) {
      //   autoScreen();
      // } else {
      //   verticalScreenForTwoSeconds();
      // }
      // }
    });
  }

  @override
  void dispose() {
    // floating.dispose();
    // videoDetailController.floating?.dispose();
    videoDetailController.cid.close();
    if (!horizontalScreen) {
      AutoOrientation.portraitUpMode();
    }
    shutdownTimerService.handleWaitingFinished();
    // _bufferedListener?.cancel();
    if (plPlayerController != null) {
      if (!floatingManager.containsFloating(globalId)) {
        videoIntroController.videoDetail.close();
        bangumiIntroController.bangumiDetail.close();
        plPlayerController!.removeStatusLister(playerListener);
        fullScreenStatusListener.cancel();
        _directionSubscription?.cancel();

        // 🔥 优化：在页面销毁前先暂停播放器，避免Hero动画时的掉帧
        // 延迟销毁播放器，让Hero动画先完成
        plPlayerController!.pause(notify: false);
        Future.delayed(const Duration(milliseconds: 100), () {
          if (plPlayerController != null) {
            plPlayerController!.disable();
          }
        });
      }
    }
    // videoPlayerServiceHandler.onVideoDetailDispose();
    VideoDetailPage.routeObserver.unsubscribe(this);
    // _lifecycleListener.dispose();
    showStatusBar();
    // _animationController.dispose();
    super.dispose();
  }

  @override
  // 离开当前页面时
  void didPushNext() async {
    // _bufferedListener?.cancel();
    if (!triggerFloatingWindowWhenLeaving() &&
        !floatingManager.containsFloating(globalId)) {
      if (plPlayerController != null) {
        videoDetailController.defaultST = plPlayerController!.position.value;
        videoIntroController.isPaused = true;
        plPlayerController!.pause();
        plPlayerController!.removeStatusLister(playerListener);
        fullScreenStatusListener.cancel();
        _directionSubscription?.cancel();
        plPlayerController!.disable();
      }
      if (mounted) {
        setState(() {
          _playerInitFinished = false;
        });
      }
    }
    // isShowing = false;
    // if (mounted) {
    //   setState(() => {});
    // }
    super.didPushNext();
  }

  @override
  // 返回当前页面时
  void didPopNext() async {
    if (mounted) {
      setState(() {
        _playerInitFinished = false;
      });
    }
    videoDetailController.isFirstTime = false;
    if (!videoDetailController.autoPlay.value &&
        floatingManager.containsFloating(globalId)) {
      PlPlayerController.pauseIfExists();
    }
    floatingManager.closeFloating(globalId);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        videoDetailController.playerInit(
            autoplay: videoDetailController.autoPlay.value);
        plPlayerController = videoDetailController.plPlayerController;

        videoDetailController.autoPlay.value =
            !videoDetailController.isShowCover.value;

        if (videoDetailController.videoType == SearchType.video) {
          final videoIntroController =
              Get.find<VideoIntroController>(tag: Get.arguments['heroTag']);
          videoIntroController.videoDetail.refresh();
        } else if (videoDetailController.videoType ==
                SearchType.media_bangumi ||
            videoDetailController.videoType == SearchType.media_ft) {
          final bangumiIntroController =
              Get.find<BangumiIntroController>(tag: Get.arguments['heroTag']);
          bangumiIntroController.bangumiDetail.refresh();
        }

        /// 未开启自动播放时，未播放跳转下一页返回/播放后跳转下一页返回
        videoIntroController.isPaused = videoDetailController.autoPlay.value;

        plPlayerController?.addStatusLister(playerListener);
        if (plPlayerController != null) {
          listenFullScreenStatus();
          listenDirectionStatus();
        }
        setState(() {
          _playerInitFinished = true;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      AutoOrientation.fullAutoMode();
    });
    super.didPopNext();
  }

  bool triggerFloatingWindowWhenLeaving() {
    if (GStorage.setting.get('autoMiniPlayer', defaultValue: false) &&
        plPlayerController?.playerStatus.status.value == PlayerStatus.playing) {
      return plPlayerController!
          .triggerFloatingWindow(videoIntroController, bangumiIntroController);
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    VideoDetailPage.routeObserver
        .subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  // void _handleTransition(String name) {
  //   switch (name) {
  //     case 'inactive':
  //       if (plPlayerController != null &&
  //           playerStatus == PlayerStatus.playing) {
  //         autoEnterPip();
  //       }
  //       break;
  //   }
  // }

  // void autoEnterPip() {
  //   final String routePath = Get.currentRoute;
  //
  //   if (autoPiP && routePath.startsWith('/video')) {
  //     floating.enable(OnLeavePiP(
  //       aspectRatio: plPlayerController != null
  //           ? Rational(
  //               videoDetailController.data.dash!.video!.first.width!,
  //               videoDetailController.data.dash!.video!.first.height!,
  //             )
  //           : const Rational.landscape(),
  //       sourceRectHint: Rectangle<int>(
  //         0,
  //         0,
  //         context.width.toInt(),
  //         context.height.toInt(),
  //       ),
  //     ));
  //     print("enabled");
  //   }
  // }

  Widget get plPlayer {
    // 🔥 修复：当播放器还没准备好时，显示缓冲 logo
    Widget buildBufferingOverlay() {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.black26, Colors.transparent],
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(
              'assets/images/loading.gif',
              height: 25,
              semanticLabel: "加载中",
            ),
            const Text(
              'Buffering...',
              style: TextStyle(color: Colors.white, fontSize: 12),
              semanticsLabel: '',
            ),
          ]),
        ),
      );
    }

    if (!_playerInitFinished) {
      // 播放器初始化未完成，显示缓冲 logo
      if (videoDetailController.autoPlay.value) {
        return buildBufferingOverlay();
      }
      return const SizedBox();
    }
    return FutureBuilder(
        future: _futureBuilderFuture,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData && snapshot.data['status']) {
            return Obx(
              () {
                // 🔥 修复：当播放器还没准备好时，显示缓冲 logo
                if ((!videoDetailController.autoPlay.value &&
                        videoDetailController.isShowCover.value) ||
                    plPlayerController == null ||
                    plPlayerController!.videoController == null) {
                  // 如果是自动播放模式，显示缓冲 logo
                  if (videoDetailController.autoPlay.value) {
                    return buildBufferingOverlay();
                  }
                  return nil;
                }
                return PLVideoPlayer(
                  key: Key(heroTag),
                  controller: plPlayerController!,
                  videoIntroController:
                      videoDetailController.videoType == SearchType.video
                          ? videoIntroController
                          : null,
                  bangumiIntroController: videoDetailController.videoType ==
                              SearchType.media_bangumi ||
                          videoDetailController.videoType == SearchType.media_ft
                      ? bangumiIntroController
                      : null,
                  headerControl: videoDetailController.headerControl,
                  danmuWidget: Obx(
                    () => PlDanmaku(
                      key: Key(
                          videoDetailController.danmakuCid.value.toString()),
                      cid: videoDetailController.danmakuCid.value,
                      playerController: plPlayerController!,
                    ),
                  ),
                );
              },
            );
          } else {
            // 🔥 修复：FutureBuilder 还没有数据时，显示缓冲 logo
            if (videoDetailController.autoPlay.value) {
              return buildBufferingOverlay();
            }
            return const SizedBox();
          }
        });
  }

  Widget get manualPlayerWidget => Obx(() => Visibility(
      visible: videoDetailController.isShowCover.value &&
          videoDetailController.isEffective.value,
      child: Stack(children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppBar(
            primary: false,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: '稍后再看',
                onPressed: () async {
                  var res = await UserHttp.toViewLater(
                      bvid: videoDetailController.bvid);
                  SmartDialog.showToast(res['msg']);
                },
                icon: const Icon(Icons.history_outlined),
              ),
              const SizedBox(width: 14)
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: 10,
          child: IconButton(
              tooltip: '播放',
              onPressed: handlePlay,
              icon: Image.asset(
                'assets/images/play.png',
                width: 60,
                height: 60,
              )),
        ),
      ])));

  Widget get childWhenDisabled => SafeArea(
        top: !removeSafeArea &&
            MediaQuery.of(context).orientation == Orientation.portrait &&
            isFullScreen.value == true,
        bottom: !removeSafeArea &&
            MediaQuery.of(context).orientation == Orientation.portrait &&
            isFullScreen.value == true,
        left: false, //isFullScreen != true,
        right: false, //isFullScreen != true,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          key: videoDetailController.scaffoldKey,
          // backgroundColor: Colors.black,
          appBar: removeSafeArea
              ? null
              : AppBar(
                  backgroundColor:
                      showStatusBarBackgroundColor ? null : Colors.black,
                  elevation: 0,
                  toolbarHeight: 0,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarIconBrightness:
                        Theme.of(context).brightness == Brightness.dark ||
                                !showStatusBarBackgroundColor
                            ? Brightness.light
                            : Brightness.dark,
                    systemNavigationBarColor: Colors.transparent,
                  ),
                ),
          body: Column(
            children: [
              // const SizedBox(
              //   height: 300,
              //   child:
              //     TextButton(onPressed: (){
              //
              //     })
              // ),
              Obx(
                () {
                  double videoHeight = context.width * 9 / 16;
                  final double videoWidth = context.width;
                  // print(videoDetailController.tabCtr.index);
                  if (enableVerticalExpand &&
                      _layoutDirection.value == 'vertical') {
                    videoHeight = context.width;
                  }
                  if (MediaQuery.of(context).orientation ==
                          Orientation.landscape &&
                      !horizontalScreen &&
                      !isFullScreen.value &&
                      // isShowing &&
                      mounted) {
                    toggleStatusBar(true);
                  }
                  if (MediaQuery.of(context).orientation ==
                          Orientation.portrait &&
                      !isFullScreen.value &&
                      // isShowing &&
                      mounted) {
                    if (!removeSafeArea) showStatusBar();
                  }
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.fastOutSlowIn,
                    color: showStatusBarBackgroundColor ? null : Colors.black,
                    height: MediaQuery.of(context).orientation ==
                                Orientation.landscape ||
                            isFullScreen.value == true
                        ? MediaQuery.sizeOf(context).height -
                            (MediaQuery.of(context).orientation ==
                                        Orientation.landscape ||
                                    removeSafeArea
                                ? 0
                                : MediaQuery.of(context).padding.top)
                        : videoHeight,
                    width: context.width,
                    child: PopScope(
                        canPop: isFullScreen.value != true &&
                            (horizontalScreen ||
                                MediaQuery.of(context).orientation ==
                                    Orientation.portrait),
                        onPopInvoked: (bool didPop) async {
                          if (isFullScreen.value == true) {
                            plPlayerController!
                                .triggerFullScreen(status: false);
                          }
                          if (MediaQuery.of(context).orientation ==
                                  Orientation.landscape &&
                              !horizontalScreen) {
                            verticalScreenForTwoSeconds();
                          }
                          if (didPop) {
                            // 🔥 优化：在退出前暂停播放器，减少Hero动画掉帧
                            if (plPlayerController != null &&
                                !floatingManager.containsFloating(globalId)) {
                              await plPlayerController!.pause(notify: false);
                            }
                            triggerFloatingWindowWhenLeaving();
                          }
                        },
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: VideoHero(
                                tag: heroTag,
                                width: videoWidth,
                                height: videoHeight,
                                child: NetworkImgLayer(
                                  src: videoDetailController.videoItem['pic'],
                                  width: videoWidth,
                                  height: videoHeight,
                                ),
                              ),
                            ),
                            // if (isShowing) plPlayer,
                            plPlayer,

                            /// 关闭自动播放时 手动播放
                            if (!videoDetailController
                                .autoPlay.value) ...<Widget>[
                              Obx(
                                () => Visibility(
                                  visible:
                                      videoDetailController.isShowCover.value,
                                  child: Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: handlePlay,
                                      child: NetworkImgLayer(
                                        type: 'emote',
                                        src: videoDetailController
                                            .videoItem['pic'],
                                        width: videoWidth,
                                        height: videoHeight,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              manualPlayerWidget,
                            ]
                          ],
                        )),
                  );
                },
              ),
              Expanded(
                child: AnimatedOpacity(
                  opacity: isFullScreen.value ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: ColoredBox(
                    key: Key(heroTag),
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      children: [
                        // Opacity(
                        //   opacity: 0,
                        //   child: SizedBox(
                        //     width: context.width,
                        //     height: 0,
                        //     child: Obx(
                        //       () => TabBar(
                        //         controller: videoDetailController.tabCtr,
                        //         dividerColor: Colors.transparent,
                        //         indicatorColor:
                        //             Theme.of(context).colorScheme.background,
                        //         tabs: videoDetailController.tabs
                        //             .map((String name) => Tab(text: name))
                        //             .toList(),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        Expanded(
                          child: TabBarView(
                            physics: const CustomTabBarViewScrollPhysics(),
                            controller: videoDetailController.tabCtr,
                            children: <Widget>[
                              _buildIntroDelayed(CustomScrollView(
                                key: const PageStorageKey<String>('简介'),
                                slivers: <Widget>[
                                  if (videoDetailController.videoType ==
                                      SearchType.video) ...[
                                    VideoIntroPanel(heroTag: heroTag),
                                  ] else if (videoDetailController.videoType ==
                                          SearchType.media_bangumi ||
                                      videoDetailController.videoType ==
                                          SearchType.media_ft) ...[
                                    Obx(() => BangumiIntroPanel(
                                        heroTag: heroTag,
                                        cid: videoDetailController.cid.value)),
                                  ],
                                  SliverToBoxAdapter(
                                    child: Divider(
                                      indent: 12,
                                      endIndent: 12,
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.06),
                                    ),
                                  ),
                                  RelatedVideoPanel(heroTag: heroTag),
                                ],
                              )),
                              _buildReplyDelayed(Obx(
                                () => VideoReplyPanel(
                                  key: const PageStorageKey<String>('评论'),
                                  bvid: videoDetailController.bvid,
                                  oid: videoDetailController.oid.value,
                                  heroTag: heroTag,
                                ),
                              ))
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  Widget get childWhenDisabledAlmostSquareInner => Obx(() {
        if (enableVerticalExpand && _layoutDirection.value == 'vertical') {
          final double videoHeight = context.height -
              (removeSafeArea
                  ? 0
                  : (MediaQuery.of(context).padding.top +
                      MediaQuery.of(context).padding.bottom));
          final double videoWidth = videoHeight * 9 / 16;
          final double sidePanelWidth = context.width - videoWidth;
          return Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              height: videoHeight,
              width: isFullScreen.value == true ? context.width : videoWidth,
              child: PopScope(
                canPop: isFullScreen.value != true,
                onPopInvoked: (bool didPop) async {
                  if (isFullScreen.value == true) {
                    plPlayerController!.triggerFullScreen(status: false);
                  }
                  if (MediaQuery.of(context).orientation ==
                          Orientation.landscape &&
                      !horizontalScreen) {
                    verticalScreenForTwoSeconds();
                  }
                  if (didPop) {
                    // 🔥 优化：在退出前暂停播放器，减少Hero动画掉帧
                    if (plPlayerController != null &&
                        !floatingManager.containsFloating(globalId)) {
                      await plPlayerController!.pause(notify: false);
                    }
                    triggerFloatingWindowWhenLeaving();
                  }
                },
                child: Stack(children: <Widget>[
                  Positioned.fill(
                    child: VideoHero(
                      tag: heroTag,
                      width: videoWidth,
                      height: videoHeight,
                      child: NetworkImgLayer(
                        src: videoDetailController.videoItem['pic'],
                        width: videoWidth,
                        height: videoHeight,
                      ),
                    ),
                  ),
                  // if (isShowing) plPlayer,
                  plPlayer,

                  /// 关闭自动播放时 手动播放
                  if (!videoDetailController.autoPlay.value) ...<Widget>[
                    Obx(
                      () => Visibility(
                        visible: videoDetailController.isShowCover.value,
                        child: Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: handlePlay,
                            child: NetworkImgLayer(
                              type: 'emote',
                              src: videoDetailController.videoItem['pic'],
                              width: videoWidth,
                              height: videoHeight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    manualPlayerWidget,
                  ]
                ]),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              width: isFullScreen.value ? 0 : sidePanelWidth,
              height: videoHeight,
              child: AnimatedOpacity(
                opacity: isFullScreen.value ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 250),
                child: ClipRect(
                  child: OverflowBox(
                    minWidth: sidePanelWidth,
                    maxWidth: sidePanelWidth,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: sidePanelWidth,
                      height: videoHeight,
                      child: TabBarView(
                        physics: const CustomTabBarViewScrollPhysics(),
                        controller: videoDetailController.tabCtr,
                        children: <Widget>[
                          _buildIntroDelayed(CustomScrollView(
                            key: const PageStorageKey<String>('简介'),
                            slivers: <Widget>[
                              if (videoDetailController.videoType ==
                                  SearchType.video) ...[
                                VideoIntroPanel(heroTag: heroTag),
                              ] else if (videoDetailController.videoType ==
                                      SearchType.media_bangumi ||
                                  videoDetailController.videoType ==
                                      SearchType.media_ft) ...[
                                Obx(() => BangumiIntroPanel(
                                    heroTag: heroTag,
                                    cid: videoDetailController.cid.value)),
                              ],
                              SliverToBoxAdapter(
                                child: Divider(
                                  indent: 12,
                                  endIndent: 12,
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withOpacity(0.06),
                                ),
                              ),
                              RelatedVideoPanel(heroTag: heroTag),
                            ],
                          )),
                          _buildReplyDelayed(Obx(
                            () => VideoReplyPanel(
                              key: const PageStorageKey<String>('评论'),
                              bvid: videoDetailController.bvid,
                              oid: videoDetailController.oid.value,
                              heroTag: heroTag,
                            ),
                          ))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        }
        final double videoHeight = context.height / 2.5;
        final double videoWidth = context.width;
        final double bottomHeight = context.height - videoHeight;
        return Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.fastOutSlowIn,
            width: videoWidth,
            height: isFullScreen.value == true
                ? context.height -
                    (removeSafeArea
                        ? 0
                        : (MediaQuery.of(context).padding.top +
                            MediaQuery.of(context).padding.bottom))
                : videoHeight,
            child: PopScope(
              canPop: isFullScreen.value != true,
              onPopInvoked: (bool didPop) async {
                if (isFullScreen.value == true) {
                  plPlayerController!.triggerFullScreen(status: false);
                }
                if (MediaQuery.of(context).orientation ==
                        Orientation.landscape &&
                    !horizontalScreen) {
                  verticalScreenForTwoSeconds();
                }
                if (didPop) {
                  // 🔥 优化：在退出前暂停播放器，减少Hero动画掉帧
                  if (plPlayerController != null &&
                      !floatingManager.containsFloating(globalId)) {
                    await plPlayerController!.pause(notify: false);
                  }
                  triggerFloatingWindowWhenLeaving();
                }
              },
              child: Stack(children: <Widget>[
                // if (isShowing) plPlayer,
                plPlayer,

                /// 关闭自动播放时 手动播放
                if (!videoDetailController.autoPlay.value) ...<Widget>[
                  Obx(
                    () => Visibility(
                      visible: videoDetailController.isShowCover.value,
                      child: Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: handlePlay,
                          child: NetworkImgLayer(
                            type: 'emote',
                            src: videoDetailController.videoItem['pic'],
                            width: videoWidth,
                            height: videoHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  manualPlayerWidget,
                ]
              ]),
            ),
          ),
          Expanded(
              child: AnimatedOpacity(
            opacity: isFullScreen.value ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 250),
            child: ClipRect(
              child: OverflowBox(
                minHeight: bottomHeight,
                maxHeight: bottomHeight,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: bottomHeight,
                  child: Row(children: [
                    Expanded(
                        child: _buildIntroDelayed(CustomScrollView(
                      key: PageStorageKey<String>(
                          '简介${videoDetailController.bvid}'),
                      slivers: <Widget>[
                        if (videoDetailController.videoType ==
                            SearchType.video) ...[
                          VideoIntroPanel(heroTag: heroTag),
                          RelatedVideoPanel(heroTag: heroTag),
                        ] else if (videoDetailController.videoType ==
                                SearchType.media_bangumi ||
                            videoDetailController.videoType ==
                                SearchType.media_ft) ...[
                          Obx(() => BangumiIntroPanel(
                              heroTag: heroTag,
                              cid: videoDetailController.cid.value)),
                        ]
                      ],
                    ))),
                    Expanded(
                      child: _buildReplyDelayed(Obx(
                        () => VideoReplyPanel(
                          key: const PageStorageKey<String>('评论'),
                          bvid: videoDetailController.bvid,
                          oid: videoDetailController.oid.value,
                          heroTag: heroTag,
                        ),
                      )),
                    )
                  ]),
                ),
              ),
            ),
          ))
        ]);
      });
  Widget get childWhenDisabledLandscapeInner => Obx(() {
        if (enableVerticalExpand && _layoutDirection.value == 'vertical') {
          final double videoHeight = context.height -
              (removeSafeArea ? 0 : MediaQuery.of(context).padding.top);
          final double videoWidth = videoHeight * 9 / 16;
          final double sidePanelWidth = (context.width - videoWidth) / 2;
          return Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              width: isFullScreen.value ? 0 : sidePanelWidth,
              height: videoHeight,
              child: AnimatedOpacity(
                opacity: isFullScreen.value ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 250),
                child: ClipRect(
                  child: OverflowBox(
                    minWidth: sidePanelWidth,
                    maxWidth: sidePanelWidth,
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: sidePanelWidth,
                      height: videoHeight,
                      child: _buildIntroDelayed(CustomScrollView(
                        key: PageStorageKey<String>(
                            '简介${videoDetailController.bvid}'),
                        slivers: <Widget>[
                          if (videoDetailController.videoType ==
                              SearchType.video) ...[
                            VideoIntroPanel(heroTag: heroTag),
                            RelatedVideoPanel(heroTag: heroTag),
                          ] else if (videoDetailController.videoType ==
                                  SearchType.media_bangumi ||
                              videoDetailController.videoType ==
                                  SearchType.media_ft) ...[
                            Obx(() => BangumiIntroPanel(
                                heroTag: heroTag,
                                cid: videoDetailController.cid.value)),
                          ]
                        ],
                      )),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              height: videoHeight,
              width: isFullScreen.value == true ? context.width : videoWidth,
              child: PopScope(
                canPop: isFullScreen.value != true,
                onPopInvoked: (bool didPop) async {
                  if (isFullScreen.value == true) {
                    plPlayerController!.triggerFullScreen(status: false);
                  }
                  if (MediaQuery.of(context).orientation ==
                          Orientation.landscape &&
                      !horizontalScreen) {
                    verticalScreenForTwoSeconds();
                  }
                  if (didPop) {
                    // 🔥 优化：在退出前暂停播放器，减少Hero动画掉帧
                    if (plPlayerController != null &&
                        !floatingManager.containsFloating(globalId)) {
                      await plPlayerController!.pause(notify: false);
                    }
                    triggerFloatingWindowWhenLeaving();
                  }
                },
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: VideoHero(
                        tag: heroTag,
                        width: videoWidth,
                        height: videoHeight,
                        child: NetworkImgLayer(
                          src: videoDetailController.videoItem['pic'],
                          width: videoWidth,
                          height: videoHeight,
                        ),
                      ),
                    ),
                    // if (isShowing) plPlayer,
                    plPlayer,

                    /// 关闭自动播放时 手动播放
                    if (!videoDetailController.autoPlay.value) ...<Widget>[
                      Obx(
                        () => Visibility(
                          visible: videoDetailController.isShowCover.value,
                          child: Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: handlePlay,
                              child: NetworkImgLayer(
                                type: 'emote',
                                src: videoDetailController.videoItem['pic'],
                                width: videoWidth,
                                height: videoHeight,
                              ),
                            ),
                          ),
                        ),
                      ),
                      manualPlayerWidget,
                    ]
                  ],
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              width: isFullScreen.value ? 0 : sidePanelWidth,
              height: videoHeight,
              child: AnimatedOpacity(
                opacity: isFullScreen.value ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 250),
                child: ClipRect(
                  child: OverflowBox(
                    minWidth: sidePanelWidth,
                    maxWidth: sidePanelWidth,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: sidePanelWidth,
                      height: videoHeight,
                      child: _buildReplyDelayed(Obx(
                        () => VideoReplyPanel(
                          key: const PageStorageKey<String>('评论'),
                          bvid: videoDetailController.bvid,
                          oid: videoDetailController.oid.value,
                          heroTag: heroTag,
                        ),
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        }
        final double videoWidth =
            max(context.height / context.width * 1.04, 1 / 2) * context.width;
        final double videoHeight = videoWidth * 9 / 16;

        final double bottomHeight = context.height -
            videoHeight -
            (removeSafeArea ? 0 : MediaQuery.of(context).padding.top);
        final double rightWidth = (context.width -
            videoWidth -
            (removeSafeArea
                ? 0
                : (MediaQuery.of(context).padding.left +
                    MediaQuery.of(context).padding.right)));
        final double rightHeight = context.height -
            (removeSafeArea ? 0 : MediaQuery.of(context).padding.top);

        return Row(children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.fastOutSlowIn,
                width: isFullScreen.value == true ? context.width : videoWidth,
                height:
                    isFullScreen.value == true ? context.height : videoHeight,
                child: PopScope(
                  canPop: isFullScreen.value != true,
                  onPopInvoked: (bool didPop) async {
                    if (isFullScreen.value == true) {
                      plPlayerController!.triggerFullScreen(status: false);
                    }
                    if (MediaQuery.of(context).orientation ==
                            Orientation.landscape &&
                        !horizontalScreen) {
                      verticalScreenForTwoSeconds();
                    }
                    if (didPop) {
                      // 🔥 优化：在退出前暂停播放器，减少Hero动画掉帧
                      if (plPlayerController != null &&
                          !floatingManager.containsFloating(globalId)) {
                        await plPlayerController!.pause(notify: false);
                      }
                      triggerFloatingWindowWhenLeaving();
                    }
                  },
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: VideoHero(
                          tag: heroTag,
                          width: videoWidth,
                          height: videoHeight,
                          child: NetworkImgLayer(
                            src: videoDetailController.videoItem['pic'],
                            width: videoWidth,
                            height: videoHeight,
                          ),
                        ),
                      ),
                      // if (isShowing) plPlayer,
                      plPlayer,

                      /// 关闭自动播放时 手动播放
                      if (!videoDetailController.autoPlay.value) ...<Widget>[
                        Obx(
                          () => Visibility(
                            visible: videoDetailController.isShowCover.value,
                            child: Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: handlePlay,
                                child: NetworkImgLayer(
                                  type: 'emote',
                                  src: videoDetailController.videoItem['pic'],
                                  width: videoWidth,
                                  height: videoHeight,
                                ),
                              ),
                            ),
                          ),
                        ),
                        manualPlayerWidget,
                      ]
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.fastOutSlowIn,
                height: isFullScreen.value ? 0 : bottomHeight,
                width: videoWidth,
                child: AnimatedOpacity(
                  opacity: isFullScreen.value ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: ClipRect(
                    child: OverflowBox(
                      minHeight: bottomHeight,
                      maxHeight: bottomHeight,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: videoWidth,
                        height: bottomHeight,
                        child: _buildIntroDelayed(CustomScrollView(
                          key: PageStorageKey<String>(
                              '简介${videoDetailController.bvid}'),
                          slivers: <Widget>[
                            if (videoDetailController.videoType ==
                                SearchType.video) ...[
                              VideoIntroPanel(heroTag: heroTag),
                              // RelatedVideoPanel(heroTag: heroTag),
                            ] else if (videoDetailController.videoType ==
                                    SearchType.media_bangumi ||
                                videoDetailController.videoType ==
                                    SearchType.media_ft) ...[
                              Obx(() => BangumiIntroPanel(
                                  heroTag: heroTag,
                                  cid: videoDetailController.cid.value)),
                            ]
                          ],
                        )),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.fastOutSlowIn,
            width: isFullScreen.value ? 0 : rightWidth,
            height: rightHeight,
            child: AnimatedOpacity(
              opacity: isFullScreen.value ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: ClipRect(
                child: OverflowBox(
                  minWidth: rightWidth,
                  maxWidth: rightWidth,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: rightWidth,
                    height: rightHeight,
                    child: TabBarView(
                      physics: const CustomTabBarViewScrollPhysics(),
                      controller: videoDetailController.tabCtr,
                      children: <Widget>[
                        if (videoDetailController.videoType == SearchType.video)
                          _buildIntroDelayed(CustomScrollView(
                            slivers: [
                              RelatedVideoPanel(heroTag: heroTag),
                            ],
                          )),
                        _buildReplyDelayed(Obx(
                          () => VideoReplyPanel(
                            key: const PageStorageKey<String>('评论'),
                            bvid: videoDetailController.bvid,
                            oid: videoDetailController.oid.value,
                            heroTag: heroTag,
                          ),
                        ))
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ]);
      });
  Widget get childWhenDisabledLandscape => Scaffold(
        resizeToAvoidBottomInset: false,
        key: videoDetailController.scaffoldKey,
        // backgroundColor: Colors.black,
        appBar: removeSafeArea
            ? null
            : AppBar(
                backgroundColor:
                    showStatusBarBackgroundColor ? null : Colors.black,
                elevation: 0,
                toolbarHeight: 0,
                systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarIconBrightness:
                        Theme.of(context).brightness == Brightness.dark ||
                                !showStatusBarBackgroundColor
                            ? Brightness.light
                            : Brightness.dark,
                    systemNavigationBarColor: Colors.transparent),
              ),
        body: Container(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
              left: !removeSafeArea && isFullScreen.value != true,
              right: !removeSafeArea && isFullScreen.value != true,
              top: !removeSafeArea,
              bottom: false, //!removeSafeArea,
              child: childWhenDisabledLandscapeInner),
        ),
      );
  Widget get childWhenDisabledAlmostSquare => Scaffold(
        resizeToAvoidBottomInset: false,
        key: videoDetailController.scaffoldKey,
        // backgroundColor: Colors.black,
        appBar: removeSafeArea
            ? null
            : AppBar(
                backgroundColor:
                    showStatusBarBackgroundColor ? null : Colors.black,
                elevation: 0,
                toolbarHeight: 0,
                systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarIconBrightness:
                        Theme.of(context).brightness == Brightness.dark ||
                                !showStatusBarBackgroundColor
                            ? Brightness.light
                            : Brightness.dark,
                    systemNavigationBarColor: Colors.transparent),
              ),
        body: Container(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
              left: !removeSafeArea && isFullScreen.value != true,
              right: !removeSafeArea && isFullScreen.value != true,
              top: !removeSafeArea,
              bottom: false, //!removeSafeArea,
              child: childWhenDisabledAlmostSquareInner),
        ),
      );
  Widget get childWhenEnabled => Obx(
        () => !videoDetailController.autoPlay.value
            ? const SizedBox()
            : PLVideoPlayer(
                key: Key(heroTag),
                controller: plPlayerController!,
                videoIntroController:
                    videoDetailController.videoType == SearchType.video
                        ? videoIntroController
                        : null,
                bangumiIntroController: videoDetailController.videoType ==
                            SearchType.media_bangumi ||
                        videoDetailController.videoType == SearchType.media_ft
                    ? bangumiIntroController
                    : null,
                headerControl: HeaderControl(
                  controller: plPlayerController,
                  videoDetailCtr: videoDetailController,
                  heroTag: heroTag,
                ),
                danmuWidget: pipNoDanmaku
                    ? null
                    : Obx(
                        () => PlDanmaku(
                          key: Key(videoDetailController.danmakuCid.value
                              .toString()),
                          cid: videoDetailController.danmakuCid.value,
                          playerController: plPlayerController!,
                        ),
                      ),
              ),
      );
  Widget autoChoose(Widget childWhenDisabled) {
    if (!Platform.isAndroid) {
      return childWhenDisabled;
    }
    // return PiPBuilder(builder: (PiPStatusInfo? statusInfo) {
    //   print("PiPStatusInfo${statusInfo?.status}");
    //   switch (statusInfo?.status) {
    //     case PiPStatus.enabled:
    //       return childWhenEnabled;
    //     case PiPStatus.disabled:
    //       return childWhenDisabled;
    //     case PiPStatus.unavailable:
    //       return childWhenDisabled;
    //     case null:
    //       return childWhenDisabled;
    //   }
    // });
    return childWhenDisabled;
    // if (Platform.isAndroid) {
    //   return PiPSwitcher(
    //     childWhenDisabled: childWhenDisabled,
    //     childWhenEnabled: childWhenEnabled,
    //     floating: floating,
    //   );
    // }
    // return childWhenDisabled;
  }

  @override
  Widget build(BuildContext context) {
    if (!horizontalScreen) {
      return autoChoose(childWhenDisabled);
    }

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      // if (!isShowing) {
      //   return ColoredBox(color: Theme.of(context).colorScheme.background);
      // }
      if (constraints.maxWidth > constraints.maxHeight * 1.25) {
//             hideStatusBar();
//             videoDetailController.hiddenReplyReplyPanel();
        return autoChoose(childWhenDisabledLandscape);
      } else if (constraints.maxWidth * (9 / 16) <
          (2 / 5) * constraints.maxHeight) {
        if (!isFullScreen.value) {
          if (!removeSafeArea) showStatusBar();
        }
        return autoChoose(childWhenDisabled);
      } else {
        if (!isFullScreen.value) {
          if (!removeSafeArea) showStatusBar();
        }
        return autoChoose(childWhenDisabledAlmostSquare);
      }
      //
      // final Orientation orientation =
      //     constraints.maxWidth > constraints.maxHeight * 1.25
      //         ? Orientation.landscape
      //         : Orientation.portrait;
      // if (orientation == Orientation.landscape) {
      //   if (!horizontalScreen) {
      //     hideStatusBar();
      //     videoDetailController.hiddenReplyReplyPanel();
      //   }
      // } else {
      //   if (!isFullScreen.value) {
      //     showStatusBar();
      //   }
      // }
      // if (Platform.isAndroid) {
      //   return PiPSwitcher(
      //     childWhenDisabled:
      //         !horizontalScreen || orientation == Orientation.portrait
      //             ? childWhenDisabled
      //             : childWhenDisabledLandscape,
      //     childWhenEnabled: childWhenEnabled,
      //     floating: floating,
      //   );
      // }
      // return !horizontalScreen || orientation == Orientation.portrait
      //     ? childWhenDisabled
      //     : childWhenDisabledLandscape;
    });
  }
}
