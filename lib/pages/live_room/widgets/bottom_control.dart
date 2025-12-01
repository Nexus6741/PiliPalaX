import 'dart:math';

import 'package:PiliPalaX/common/widgets/custom_icon.dart';
import 'package:PiliPalaX/pages/live_room/controller.dart';
import 'package:PiliPalaX/plugin/pl_player/controller.dart';
import 'package:PiliPalaX/plugin/pl_player/widgets/common_btn.dart';
import 'package:PiliPalaX/plugin/pl_player/widgets/play_pause_btn.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/pages/video/introduction/widgets/menu_row.dart';

class BottomControl extends StatefulWidget implements PreferredSizeWidget {
  const BottomControl({
    super.key,
    required this.plPlayerController,
    required this.liveRoomCtr,
    required this.onRefresh,
    this.subTitleStyle = const TextStyle(fontSize: 12),
    this.titleStyle = const TextStyle(fontSize: 14),
  });

  final PlPlayerController plPlayerController;
  final LiveRoomController liveRoomCtr;
  final VoidCallback onRefresh;

  final TextStyle subTitleStyle;
  final TextStyle titleStyle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<BottomControl> createState() => _BottomControlState();
}

class _BottomControlState extends State<BottomControl> {
  late final LiveRoomController liveRoomCtr = widget.liveRoomCtr;
  late final PlPlayerController plPlayerController = widget.plPlayerController;

  @override
  Widget build(BuildContext context) {
    final isFullScreen = plPlayerController.isFullScreen.value;
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      primary: false,
      automaticallyImplyLeading: false,
      titleSpacing: 14,
      title: Row(
        children: [
          PlayOrPauseButton(controller: plPlayerController),
          ComBtn(
            height: 30,
            tooltip: '刷新',
            icon: const Icon(
              Icons.refresh,
              size: 18,
              color: Colors.white,
            ),
            onTap: widget.onRefresh,
          ),
          const Spacer(),
          ComBtn(
            height: 30,
            tooltip: '屏蔽',
            icon: const Icon(
              size: 18,
              Icons.block,
              color: Colors.white,
            ),
            onTap: () {
              if (liveRoomCtr.isLogin) {
                Get.toNamed(
                  '/liveDmBlockPage',
                  parameters: {
                    'roomId': liveRoomCtr.roomId.toString(),
                  },
                );
              } else {
                SmartDialog.showToast('账号未登录');
              }
            },
          ),
          const SizedBox(width: 3),
          Obx(
            () {
              final enableShowLiveDanmaku =
                  plPlayerController.isOpenDanmu.value;
              return ComBtn(
                height: 30,
                tooltip: "${enableShowLiveDanmaku ? '关闭' : '开启'}弹幕",
                icon: enableShowLiveDanmaku
                    ? const Icon(
                        size: 18,
                        CustomIcons.dm_on,
                        color: Colors.white,
                      )
                    : const Icon(
                        size: 18,
                        CustomIcons.dm_off,
                        color: Colors.white,
                      ),
                onTap: () {
                  final newVal = !enableShowLiveDanmaku;
                  plPlayerController.isOpenDanmu.value = newVal;
                  // if (!plPlayerController.tempPlayerConf) {
                  GStorage.setting.put(
                    SettingBoxKey.enableShowLiveDanmaku,
                    newVal,
                  );
                  // }
                },
              );
            },
          ),
          ComBtn(
            height: 30,
            tooltip: '弹幕设置',
            icon: const Icon(
              size: 18,
              CustomIcons.dm_settings,
              color: Colors.white,
            ),
            onTap: () => showSetDanmaku(isLive: true),
          ),
          Obx(
            () => TextButton(
              onPressed: () => plPlayerController.toggleVideoFit(),
              child: Text(
                plPlayerController.videoFitDEsc.value,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
          Obx(
            () => PopupMenuButton<int>(
              tooltip: '画质',
              padding: EdgeInsets.zero,
              initialValue: liveRoomCtr.currentQn.value,
              color: Colors.black.withOpacity(0.8),
              itemBuilder: (context) {
                return liveRoomCtr.acceptQnList
                    .map(
                      (e) => PopupMenuItem<int>(
                        height: 35,
                        padding: const EdgeInsets.only(left: 30),
                        value: e['code'],
                        onTap: () => liveRoomCtr.changeQn(e['code']),
                        child: Text(
                          e['desc'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  liveRoomCtr.currentQnDesc.value,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
          // if (!plPlayerController.isDesktopPip)
          ComBtn(
            height: 30,
            tooltip: isFullScreen ? '退出全屏' : '全屏',
            icon: isFullScreen
                ? const Icon(
                    Icons.fullscreen_exit,
                    size: 24,
                    color: Colors.white,
                  )
                : const Icon(
                    Icons.fullscreen,
                    size: 24,
                    color: Colors.white,
                  ),
            onTap: () =>
                plPlayerController.triggerFullScreen(status: !isFullScreen),
            onSecondaryTap: () => plPlayerController.triggerFullScreen(
              status: !isFullScreen,
              // inAppFullScreen: true,
            ),
          ),
        ],
      ),
    );
  }

  /// 弹幕功能
  void showSetDanmaku({bool isLive = false}) async {
    // 屏蔽类型
    final List<Map<String, dynamic>> blockTypesList = [
      {'value': 5, 'label': '顶部'},
      {'value': 2, 'label': '滚动'},
      {'value': 4, 'label': '底部'},
      {'value': 6, 'label': '彩色'},
    ];
    final List blockTypes = plPlayerController.blockTypes;
    // 显示区域
    final List<Map<String, dynamic>> showAreas = [
      {'value': 0.25, 'label': '1/4'},
      {'value': 0.5, 'label': '半屏'},
      {'value': 0.75, 'label': '3/4'},
      {'value': 1.0, 'label': '满屏'},
    ];
    // 智能云屏蔽
    int danmakuWeight = plPlayerController.danmakuWeight.value;
    // 显示区域
    double showArea = plPlayerController.showArea;
    // 不透明度
    double opacityVal = plPlayerController.opacityVal;
    // 字体大小
    double fontSizeVal = plPlayerController.fontSizeVal;
    // 弹幕速度
    int danmakuDurationVal = plPlayerController.danmakuDurationVal;
    // 弹幕描边
    double strokeWidth = plPlayerController.strokeWidth;
    // 字体粗细
    int fontWeight = plPlayerController.fontWeight;
    // 海量模式
    bool massiveMode = plPlayerController.massiveMode;

    final DanmakuController? danmakuController =
        plPlayerController.danmakuController;

    if (danmakuController == null) {
      SmartDialog.showToast('弹幕控制器未初始化');
      return;
    }

    await showModalBottomSheet(
      context: context,
      elevation: 0,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Container(
            width: double.infinity,
            height: 580,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.only(left: 14, right: 14),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 45,
                    child:
                        Center(child: Text('弹幕设置', style: widget.titleStyle)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('智能云屏蔽 $danmakuWeight 级'),
                      const Spacer(),
                      TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => {
                                Get.back(),
                                Get.toNamed('/danmakuBlock',
                                    arguments: plPlayerController)
                              },
                          child: Text(
                              "屏蔽管理(${plPlayerController.danmakuFilterRule.value.length})")),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackShape: MSliderTrackShape(),
                        thumbColor: Theme.of(context).colorScheme.primary,
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        trackHeight: 10,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0),
                      ),
                      child: Slider(
                        min: 0,
                        max: 10,
                        value: danmakuWeight.toDouble(),
                        divisions: 10,
                        label: '$danmakuWeight',
                        onChanged: (double val) {
                          danmakuWeight = val.toInt();
                          plPlayerController.danmakuWeight.value =
                              danmakuWeight;
                          plPlayerController.putDanmakuSettings();
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                  const Text('按类型屏蔽'),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 18),
                    child: Row(
                      children: <Widget>[
                        for (final Map<String, dynamic> i
                            in blockTypesList) ...<Widget>[
                          ActionRowLineItem(
                            onTap: () async {
                              final bool isChoose =
                                  blockTypes.contains(i['value']);
                              if (isChoose) {
                                blockTypes.remove(i['value']);
                              } else {
                                blockTypes.add(i['value']);
                              }
                              plPlayerController.blockTypes = blockTypes;
                              plPlayerController.putDanmakuSettings();
                              setState(() {});
                              try {
                                final DanmakuOption currentOption =
                                    danmakuController.option;
                                final DanmakuOption updatedOption =
                                    currentOption.copyWith(
                                  hideTop: blockTypes.contains(5),
                                  hideBottom: blockTypes.contains(4),
                                  hideScroll: blockTypes.contains(2),
                                );
                                danmakuController.updateOption(updatedOption);
                              } catch (_) {}
                            },
                            text: i['label'],
                            selectStatus: blockTypes.contains(i['value']),
                          ),
                          const SizedBox(width: 10),
                        ]
                      ],
                    ),
                  ),
                  const Text('显示区域'),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 18),
                    child: Row(
                      children: [
                        for (final Map<String, dynamic> i in showAreas) ...[
                          ActionRowLineItem(
                            onTap: () {
                              showArea = i['value'];
                              plPlayerController.showArea = showArea;
                              plPlayerController.putDanmakuSettings();
                              setState(() {});
                              try {
                                final DanmakuOption currentOption =
                                    danmakuController.option;
                                final DanmakuOption updatedOption =
                                    currentOption.copyWith(area: i['value']);
                                danmakuController.updateOption(updatedOption);
                              } catch (_) {}
                            },
                            text: i['label'],
                            selectStatus: showArea == i['value'],
                          ),
                          const SizedBox(width: 10),
                        ],
                        const Spacer(),
                        ActionRowLineItem(
                          key: const Key('massiveMode'),
                          onTap: () {
                            massiveMode = !massiveMode;
                            plPlayerController.massiveMode = massiveMode;
                            plPlayerController.putDanmakuSettings();
                            setState(() {});
                            try {
                              final DanmakuOption currentOption =
                                  danmakuController.option;
                              final DanmakuOption updatedOption = currentOption
                                  .copyWith(massiveMode: massiveMode);
                              danmakuController.updateOption(updatedOption);
                            } catch (_) {}
                          },
                          text: "允许重叠",
                          selectStatus: massiveMode,
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                  Text('不透明度 ${opacityVal * 100}%'),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackShape: MSliderTrackShape(),
                        thumbColor: Theme.of(context).colorScheme.primary,
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        trackHeight: 10,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0),
                      ),
                      child: Slider(
                        min: 0,
                        max: 1,
                        value: opacityVal,
                        divisions: 10,
                        label: '${opacityVal * 100}%',
                        onChanged: (double val) {
                          opacityVal = val;
                          plPlayerController.opacityVal = opacityVal;
                          plPlayerController.putDanmakuSettings();
                          setState(() {});
                          try {
                            final DanmakuOption currentOption =
                                danmakuController.option;
                            final DanmakuOption updatedOption =
                                currentOption.copyWith(opacity: val);
                            danmakuController.updateOption(updatedOption);
                          } catch (_) {}
                        },
                      ),
                    ),
                  ),
                  Text('字体粗细 ${fontWeight + 1}（可能无法精确调节）'),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackShape: MSliderTrackShape(),
                        thumbColor: Theme.of(context).colorScheme.primary,
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        trackHeight: 10,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0),
                      ),
                      child: Slider(
                        min: 0,
                        max: 8,
                        value: fontWeight.toDouble(),
                        divisions: 8,
                        label: '${fontWeight + 1}',
                        onChanged: (double val) {
                          fontWeight = val.toInt();
                          plPlayerController.fontWeight = fontWeight;
                          plPlayerController.putDanmakuSettings();
                          setState(() {});
                          try {
                            final DanmakuOption currentOption =
                                danmakuController.option;
                            final DanmakuOption updatedOption =
                                currentOption.copyWith(fontWeight: fontWeight);
                            danmakuController.updateOption(updatedOption);
                          } catch (_) {}
                        },
                      ),
                    ),
                  ),
                  Text('描边粗细 $strokeWidth'),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackShape: MSliderTrackShape(),
                        thumbColor: Theme.of(context).colorScheme.primary,
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        trackHeight: 10,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0),
                      ),
                      child: Slider(
                        min: 0,
                        max: 3,
                        value: strokeWidth,
                        divisions: 6,
                        label: '$strokeWidth',
                        onChanged: (double val) {
                          strokeWidth = val;
                          plPlayerController.strokeWidth = val;
                          plPlayerController.putDanmakuSettings();
                          setState(() {});
                          try {
                            final DanmakuOption currentOption =
                                danmakuController.option;
                            final DanmakuOption updatedOption =
                                currentOption.copyWith(strokeWidth: val);
                            danmakuController.updateOption(updatedOption);
                          } catch (_) {}
                        },
                      ),
                    ),
                  ),
                  Text('字体大小 ${(fontSizeVal * 100).toStringAsFixed(1)}%'),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackShape: MSliderTrackShape(),
                        thumbColor: Theme.of(context).colorScheme.primary,
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        trackHeight: 10,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0),
                      ),
                      child: Slider(
                        min: 0.5,
                        max: 2.5,
                        value: fontSizeVal,
                        divisions: 20,
                        label: '${(fontSizeVal * 100).toStringAsFixed(1)}%',
                        onChanged: (double val) {
                          fontSizeVal = val;
                          plPlayerController.fontSizeVal = fontSizeVal;
                          plPlayerController.putDanmakuSettings();
                          setState(() {});
                          try {
                            final DanmakuOption currentOption =
                                danmakuController.option;
                            final DanmakuOption updatedOption =
                                currentOption.copyWith(
                              fontSize: (15 * fontSizeVal).toDouble(),
                            );
                            danmakuController.updateOption(updatedOption);
                          } catch (_) {}
                        },
                      ),
                    ),
                  ),
                  Text('弹幕时长 $danmakuDurationVal 秒'),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: 6,
                      left: 10,
                      right: 10,
                    ),
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackShape: MSliderTrackShape(),
                        thumbColor: Theme.of(context).colorScheme.primary,
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        trackHeight: 10,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0),
                      ),
                      child: Slider(
                        min: 1.2,
                        max: 4,
                        value: pow(danmakuDurationVal, 1 / 4) as double,
                        divisions: 28,
                        label: danmakuDurationVal.toString(),
                        onChanged: (double val) {
                          danmakuDurationVal = (pow(val, 4) as double).round();
                          plPlayerController.danmakuDurationVal =
                              danmakuDurationVal;
                          plPlayerController.putDanmakuSettings();
                          setState(() {});
                          try {
                            final DanmakuOption updatedOption =
                                danmakuController.option.copyWith(
                                    duration: (danmakuDurationVal /
                                            plPlayerController.playbackSpeed)
                                        .round());
                            danmakuController.updateOption(updatedOption);
                          } catch (_) {}
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

class MSliderTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    SliderThemeData? sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const double trackHeight = 3;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2 + 4;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
