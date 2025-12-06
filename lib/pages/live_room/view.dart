import 'dart:math';

import 'package:PiliPalaX/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating/floating/manager/floating_manager.dart';
import 'package:get/get.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:PiliPalaX/common/widgets/network_img_layer.dart';
import 'package:PiliPalaX/plugin/pl_player/index.dart';
import 'package:PiliPalaX/utils/storage.dart';

import 'controller.dart';
import 'widgets/bottom_control.dart';
import 'widgets/chat_panel.dart';

class LiveRoomPage extends StatefulWidget {
  const LiveRoomPage({super.key});

  @override
  State<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends State<LiveRoomPage> {
  final LiveRoomController _liveRoomController = Get.put(LiveRoomController());
  PlPlayerController? plPlayerController;
  late Future? _futureBuilder;
  late Future? _futureBuilderFuture;

  bool isShowCover = true;
  bool isPlay = true;

  @override
  void initState() {
    super.initState();
    videoSourceInit();
    _futureBuilderFuture = _liveRoomController.queryLiveInfo();
    // 初始化直播弹幕显示状态
    plPlayerController!.isOpenDanmu.value = GStorage.setting.get(
      SettingBoxKey.enableShowLiveDanmaku,
      defaultValue: true,
    );
    plPlayerController!.autoEnterFullScreen();
    floatingManager.closeFloating(globalId);
  }

  Future<void> videoSourceInit() async {
    _futureBuilder = _liveRoomController.queryLiveInfoH5();
    plPlayerController = _liveRoomController.plPlayerController;
  }

  @override
  void dispose() {
    plPlayerController!.disable();
    super.dispose();
  }

  Widget _buildDanmakuWidget() {
    final blockTypes = plPlayerController!.blockTypes;
    final showArea = plPlayerController!.showArea;
    final opacityVal = plPlayerController!.opacityVal;
    final fontSizeVal = plPlayerController!.fontSizeVal;
    final strokeWidth = plPlayerController!.strokeWidth;
    final fontWeight = plPlayerController!.fontWeight;
    final danmakuDurationVal = plPlayerController!.danmakuDurationVal;

    Widget danmakuWidget = DanmakuScreen(
      createdController: (DanmakuController e) {
        _liveRoomController.danmakuController = e;
        plPlayerController!.danmakuController = e;
      },
      option: DanmakuOption(
        fontSize: 15 * fontSizeVal,
        fontWeight: fontWeight,
        area: showArea,
        opacity: opacityVal,
        hideTop: blockTypes.contains(5),
        hideScroll: blockTypes.contains(2),
        hideBottom: blockTypes.contains(4),
        duration: danmakuDurationVal,
        strokeWidth: strokeWidth,
      ),
    );

    return Obx(() {
      return AnimatedOpacity(
        opacity: plPlayerController!.isOpenDanmu.value ? opacityVal : 0,
        duration: const Duration(milliseconds: 100),
        child: danmakuWidget,
      );
    });
  }

  Widget _buildVideoPlayer() {
    return FutureBuilder(
      future: _futureBuilderFuture,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData && snapshot.data['status']) {
          return PLVideoPlayer(
            controller: plPlayerController!,
            danmuWidget: _buildDanmakuWidget(),
            bottomControl: BottomControl(
              plPlayerController: plPlayerController!,
              liveRoomCtr: _liveRoomController,
              onRefresh: () {
                _futureBuilderFuture = _liveRoomController.queryLiveInfo();
                setState(() {});
              },
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  // 竖屏布局
  Widget _buildPortraitLayout() {
    return Column(
      children: [
        _buildAppBar(),
        PopScope(
          canPop: plPlayerController?.isFullScreen.value != true,
          onPopInvoked: (bool didPop) {
            if (plPlayerController?.isFullScreen.value == true) {
              plPlayerController!.triggerFullScreen(status: false);
            }
          },
          child: SizedBox(
            width: Get.size.width,
            height: Get.size.width * 9 / 16,
            child: _buildVideoPlayer(),
          ),
        ),
        Expanded(
          child: LiveRoomChatPanel(
            roomId: _liveRoomController.roomId,
            liveRoomController: _liveRoomController,
          ),
        ),
      ],
    );
  }

  // 横屏布局 - 左边视频右边聊天
  Widget _buildLandscapeLayout() {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final isFullScreen = plPlayerController?.isFullScreen.value ?? false;

    // 计算视频宽度和聊天区宽度
    double videoWidth = size.height / size.width * 1.08;
    videoWidth = videoWidth.clamp(0.56, 0.7) * size.width;
    final rightWidth = min(400.0, size.width - videoWidth - padding.horizontal);
    videoWidth = size.width - rightWidth - padding.horizontal;
    final videoHeight = size.height - padding.top;

    final actualWidth = isFullScreen ? size.width : videoWidth;
    final actualHeight = isFullScreen ? size.height - padding.top : videoHeight;

    return PopScope(
      canPop: !isFullScreen,
      onPopInvoked: (bool didPop) {
        if (isFullScreen) {
          plPlayerController!.triggerFullScreen(status: false);
        } else {
          verticalScreenForTwoSeconds();
        }
      },
      child: Padding(
        padding: isFullScreen
            ? EdgeInsets.zero
            : EdgeInsets.only(left: padding.left, right: padding.right),
        child: Row(
          children: [
            // 左边视频区域
            Container(
              width: actualWidth,
              height: actualHeight,
              margin: EdgeInsets.only(bottom: padding.bottom),
              child: _buildVideoPlayer(),
            ),
            // 右边聊天区域（全屏时隐藏）
            if (!isFullScreen)
              SizedBox(
                width: rightWidth,
                height: videoHeight,
                child: Column(
                  children: [
                    // 标题栏
                    _buildLandscapeHeader(),
                    // 聊天面板
                    Expanded(
                      child: LiveRoomChatPanel(
                        roomId: _liveRoomController.roomId,
                        liveRoomController: _liveRoomController,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 横屏模式下右侧的头部信息
  Widget _buildLandscapeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: FutureBuilder(
        future: _futureBuilder,
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return const SizedBox(height: 50);
          }
          Map data = snapshot.data as Map;
          if (data['status']) {
            return Obx(
              () => Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final uid =
                          _liveRoomController.roomInfoH5.value?.roomInfo?.uid;
                      if (uid != null && uid > 0) {
                        Get.toNamed('/member?mid=$uid');
                      }
                    },
                    child: NetworkImgLayer(
                      width: 40,
                      height: 40,
                      type: 'avatar',
                      src: _liveRoomController.roomInfoH5.value?.anchorInfo
                              ?.baseInfo?.face ??
                          '',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _liveRoomController.roomInfoH5.value?.anchorInfo
                                  ?.baseInfo?.uname ??
                              '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            _liveRoomController.watchedWidget,
                            _liveRoomController.onlineWidget,
                            _liveRoomController.timeWidget,
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '返回',
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    iconSize: 20,
                  ),
                ],
              ),
            );
          } else {
            return const SizedBox(height: 50);
          }
        },
      ),
    );
  }

  // 竖屏模式下的 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: false,
      titleSpacing: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      title: FutureBuilder(
        future: _futureBuilder,
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return const SizedBox();
          }
          Map data = snapshot.data as Map;
          if (data['status']) {
            return Obx(
              () => Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final uid =
                          _liveRoomController.roomInfoH5.value?.roomInfo?.uid;
                      if (uid != null && uid > 0) {
                        Get.toNamed('/member?mid=$uid');
                      }
                    },
                    child: NetworkImgLayer(
                      width: 34,
                      height: 34,
                      type: 'avatar',
                      src: _liveRoomController.roomInfoH5.value?.anchorInfo
                              ?.baseInfo?.face ??
                          '',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _liveRoomController.roomInfoH5.value?.anchorInfo
                                  ?.baseInfo?.uname ??
                              '',
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            _liveRoomController.watchedWidget,
                            _liveRoomController.onlineWidget,
                            _liveRoomController.timeWidget,
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: '刷新',
                    onPressed: () {
                      _futureBuilderFuture =
                          _liveRoomController.queryLiveInfo();
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    tooltip: '内置浏览器打开',
                    onPressed: () {
                      Get.offNamed(
                        '/webview',
                        parameters: {
                          'url':
                              'https://live.bilibili.com/h5/${_liveRoomController.roomId}',
                          'type': 'liveRoom',
                          'pageTitle': _liveRoomController.roomInfoH5.value
                                  ?.anchorInfo?.baseInfo?.uname ??
                              '',
                        },
                      );
                    },
                    icon: const Icon(Icons.open_in_browser),
                  ),
                ],
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      primary: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/live/default_bg.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 自定义背景
          Obx(
            () {
              final background = _liveRoomController
                  .roomInfoH5.value?.roomInfo?.background;
              if (background != null && background.isNotEmpty) {
                return Positioned.fill(
                  child: Opacity(
                    opacity: 0.8,
                    child: NetworkImgLayer(
                      width: Get.width,
                      height: Get.height,
                      type: 'bg',
                      src: background,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // 主内容
          Obx(() {
            // 需要监听全屏状态变化以触发重建
            plPlayerController?.isFullScreen.value;
            if (isPortrait) {
              return _buildPortraitLayout();
            } else {
              return _buildLandscapeLayout();
            }
          }),
        ],
      ),
    );
  }
}
