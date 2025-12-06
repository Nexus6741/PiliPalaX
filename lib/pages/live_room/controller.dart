import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:PiliPalaX/http/constants.dart';
import 'package:PiliPalaX/http/live.dart';
import 'package:PiliPalaX/models/live/room_info.dart';
import 'package:PiliPalaX/models/live/live_dm_info/data.dart';
import 'package:PiliPalaX/models/live/live_danmaku/danmaku_msg.dart';
import 'package:PiliPalaX/plugin/pl_player/index.dart';
import 'package:PiliPalaX/tcp/live.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:PiliPalaX/utils/utils.dart';
import '../../models/live_new/live_room_info_h5/data.dart';
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
  Rx<RoomInfoH5Data?> roomInfoH5 = Rx<RoomInfoH5Data?>(null);
  final RxnString watchedShowText = RxnString();
  final RxnString onlineCountText = RxnString();
  final Rx<int?> liveStartTime = Rx<int?>(null);
  Timer? liveTimer;
  final RxInt likeClickTime = 0.obs;
  Timer? likeClickTimer;
  // late bool enableCDN;

  RxInt currentQn = 10000.obs;
  RxString currentQnDesc = '原画'.obs;
  RxList<Map> acceptQnList = <Map>[].obs;

  bool get isLogin => GStorage.userInfo.get('userInfoCache') != null;
  int get myMid => GStorage.userInfo.get('userInfoCache')?.mid ?? 0;

  // 弹幕相关
  DanmakuController? danmakuController;
  LiveDmInfoData? dmInfo;
  RxList<DanmakuMsg> messages = <DanmakuMsg>[].obs;
  RxBool disableAutoScroll = false.obs;
  LiveMessageStream? _msgStream;
  late final ScrollController dmScrollController = ScrollController()
    ..addListener(_scrollListener);

  // 弹幕设置
  RxBool showDanmaku = true.obs;

  Widget get watchedWidget => Obx(() {
        final text = watchedShowText.value;
        if (text == null || text.isEmpty) {
          return const SizedBox.shrink();
        }
        return Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        );
      });

  Widget get onlineWidget => Obx(() {
        final text = onlineCountText.value;
        if (text == null || text.isEmpty) {
          return const SizedBox.shrink();
        }
        return Text(
          '高能观众($text)',
          style: const TextStyle(fontSize: 12, color: Colors.white),
        );
      });

  Widget get timeWidget => Obx(() {
        final start = liveStartTime.value;
        if (start == null || start <= 0) {
          return const SizedBox.shrink();
        }
        final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final passed = nowSeconds - start;
        if (passed <= 0) {
          return const SizedBox.shrink();
        }
        final duration = Duration(seconds: passed);
        return Text(
          '开播${_formatDuration(duration)}',
          style: const TextStyle(fontSize: 12, color: Colors.white),
        );
      });

  void startLiveTimer() {
    liveTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      liveStartTime.refresh();
    });
  }

  void cancelLiveTimer() {
    liveTimer?.cancel();
    liveTimer = null;
  }

  void _updateWatchedShow(String? text) {
    if (text == null || text.isEmpty) {
      watchedShowText.value = null;
    } else {
      watchedShowText.value = text;
    }
  }

  void _updateOnlineCount(int? count) {
    if (count == null) {
      onlineCountText.value = null;
      return;
    }
    onlineCountText.value = Utils.numFormat(count);
  }

  void _updateLiveStartTime(int? timestamp) {
    if (timestamp == null || timestamp <= 0) {
      return;
    }
    liveStartTime.value = timestamp;
    startLiveTimer();
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours >= 1) {
      final minutes = duration.inMinutes.remainder(60);
      final minutesText = minutes == 0 ? '' : '$minutes分钟';
      return '${duration.inHours}小时$minutesText';
    }
    if (duration.inMinutes >= 1) {
      final seconds = duration.inSeconds.remainder(60);
      final secondsText = seconds == 0 ? '' : '$seconds秒';
      return '${duration.inMinutes}分钟$secondsText';
    }
    return '${duration.inSeconds}秒';
  }

  @override
  void onInit() {
    super.onInit();
    roomId = int.parse(Get.parameters['roomid']!);
    final args = Get.arguments;
    heroTag = Utils.makeHeroTag(roomId);
    if (args is Map) {
      liveItem = args['liveItem'];
      final argHeroTag = args['heroTag'];
      if (argHeroTag is String && argHeroTag.isNotEmpty) {
        heroTag = argHeroTag;
      }
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
      serviceId: heroTag,
    );
  }

  Future queryLiveInfo() async {
    debugPrint(
        '[LiveRoom] queryLiveInfo called, roomId: $roomId, qn: ${currentQn.value}');
    var res = await LiveHttp.liveRoomInfo(roomId: roomId, qn: currentQn.value);
    debugPrint(
        '[LiveRoom] liveRoomInfo result: status=${res['status']}, msg=${res['msg']}');
    if (res['status']) {
      try {
        RoomInfoModel data = res['data'];

        // 检查直播状态
        if (data.liveStatus != 1) {
          debugPrint(
              '[LiveRoom] Live is not streaming, status: ${data.liveStatus}');
          return res;
        }

        // 检查 playurlInfo
        if (data.playurlInfo?.playurl == null) {
          debugPrint('[LiveRoom] playurlInfo or playurl is null');
          return res;
        }

        if (data.liveTime != null) {
          _updateLiveStartTime(data.liveTime);
        }

        final playurl = data.playurlInfo!.playurl!;

        // 解析画质描述
        List<GQnDesc>? qnDesc = playurl.gQnDesc;
        if (qnDesc != null && qnDesc.isNotEmpty) {
          debugPrint('[LiveRoom] qnDesc count: ${qnDesc.length}');
          acceptQnList.value =
              qnDesc.map((e) => {'code': e.qn, 'desc': e.desc}).toList();
          var current = qnDesc.firstWhere((e) => e.qn == currentQn.value,
              orElse: () => qnDesc.first);
          currentQnDesc.value = current.desc ?? '未知';
        }

        // 解析视频流
        if (playurl.stream == null || playurl.stream!.isEmpty) {
          debugPrint('[LiveRoom] stream is null or empty');
          return res;
        }

        final stream = playurl.stream!.first;
        if (stream.format == null || stream.format!.isEmpty) {
          debugPrint('[LiveRoom] format is null or empty');
          return res;
        }

        final format = stream.format!.first;
        if (format.codec == null || format.codec!.isEmpty) {
          debugPrint('[LiveRoom] codec is null or empty');
          return res;
        }

        List<CodecItem> codec = format.codec!;
        debugPrint('[LiveRoom] codec count: ${codec.length}');
        CodecItem item = codec.first;

        // 使用 getLiveCdnUrl 获取直播流 URL
        String videoUrl = VideoUtils.getLiveCdnUrl(item);
        debugPrint('[LiveRoom] videoUrl: $videoUrl');

        if (videoUrl.isEmpty) {
          debugPrint('[LiveRoom] videoUrl is empty');
          return res;
        }

        await playerInit(videoUrl);
        debugPrint('[LiveRoom] playerInit completed');

        // 延迟初始化弹幕，确保 DanmakuScreen 已渲染
        Future.delayed(const Duration(milliseconds: 500), () {
          startLiveMsg();
        });

        return res;
      } catch (e, stackTrace) {
        debugPrint('[LiveRoom] Error parsing response: $e');
        debugPrint('[LiveRoom] StackTrace: $stackTrace');
      }
    } else {
      debugPrint('[LiveRoom] liveRoomInfo failed: ${res['msg']}');
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
      roomInfoH5.value = res['data'] as RoomInfoH5Data?;
      final data = roomInfoH5.value;
      _updateWatchedShow(data?.watchedShow?.textLarge);
      _updateOnlineCount(data?.roomInfo?.online);
      _updateLiveStartTime(data?.roomInfo?.liveStartTime);
    }
    return res;
  }

  // ==================== 弹幕功能 ====================

  void _scrollListener() {
    final userScrollDirection = dmScrollController.position.userScrollDirection;
    if (userScrollDirection == ScrollDirection.forward) {
      disableAutoScroll.value = true;
    } else if (userScrollDirection == ScrollDirection.reverse) {
      final pos = dmScrollController.position;
      if (pos.maxScrollExtent - pos.pixels <= 100) {
        disableAutoScroll.value = false;
      }
    }
  }

  void scrollToBottom([_]) {
    if (dmScrollController.hasClients) {
      dmScrollController.animateTo(
        dmScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.linearToEaseOut,
      );
    }
  }

  void jumpToBottom() {
    if (dmScrollController.hasClients) {
      dmScrollController.jumpTo(dmScrollController.position.maxScrollExtent);
    }
  }

  void closeLiveMsg() {
    _msgStream?.close();
    _msgStream = null;
  }

  Future<void> prefetch() async {
    final res = await LiveHttp.liveRoomDanmaPrefetch(roomId: roomId);
    if (res['status']) {
      final data = res['data'];
      if (data is List) {
        try {
          messages.addAll(
            data.cast<Map<String, dynamic>>().map(DanmakuMsg.fromPrefetch),
          );
          WidgetsBinding.instance.addPostFrameCallback(scrollToBottom);
        } catch (_) {}
      }
    }
  }

  void startLiveMsg() {
    debugPrint('[LiveDanmaku] startLiveMsg called, roomId: $roomId');
    if (messages.isEmpty) {
      prefetch();
    }
    if (_msgStream != null) {
      debugPrint('[LiveDanmaku] _msgStream already exists, skipping');
      return;
    }
    if (dmInfo != null) {
      debugPrint('[LiveDanmaku] dmInfo exists, calling initDm');
      initDm(dmInfo!);
      return;
    }
    debugPrint('[LiveDanmaku] Fetching danmaku token...');
    LiveHttp.liveRoomGetDanmakuToken(roomId: roomId).then((res) {
      debugPrint(
          '[LiveDanmaku] Token response: status=${res['status']}, msg=${res['msg']}');
      if (res['status']) {
        dmInfo = res['data'];
        debugPrint(
            '[LiveDanmaku] Token: ${dmInfo?.token?.substring(0, 20)}..., hosts: ${dmInfo?.hostList?.length}');
        initDm(dmInfo!);
      } else {
        debugPrint('[LiveDanmaku] Failed to get token: ${res['msg']}');
      }
    }).catchError((e) {
      debugPrint('[LiveDanmaku] Error getting token: $e');
    });
  }

  void initDm(LiveDmInfoData info) {
    debugPrint('[LiveDanmaku] initDm called');
    if (info.hostList == null || info.hostList!.isEmpty) {
      debugPrint('[LiveDanmaku] hostList is null or empty');
      return;
    }
    final servers = info.hostList!
        .map((host) => 'wss://${host.host}:${host.wssPort}/sub')
        .toList();
    debugPrint('[LiveDanmaku] Connecting to servers: $servers');
    debugPrint('[LiveDanmaku] uid: $myMid, roomId: $roomId');
    _msgStream = LiveMessageStream(
      streamToken: info.token ?? '',
      roomId: roomId,
      uid: myMid,
      servers: servers,
    )
      ..addEventListener(_danmakuListener)
      ..init();
    debugPrint('[LiveDanmaku] LiveMessageStream created and initialized');
  }

  void _handleDanmuMsg(dynamic obj) {
    try {
      final info = obj['info'];
      if (info == null || info.isEmpty) {
        debugPrint('[LiveDanmaku] DANMU_MSG: info is null or empty');
        return;
      }

      final first = info[0];
      String? name;
      int? uid;
      int color = 16777215; // 默认白色
      Map<String, BaseEmote>? emoteMap;
      BaseEmote? uemote;

      // 优先从 info[0][13] 获取第三方表情信息（新格式）
      if (first.length > 13 && first[13] != null && first[13] is Map) {
        try {
          uemote = BaseEmote.fromJson(
            Map<String, dynamic>.from(first[13] as Map),
          );
        } catch (_) {}
      }

      // 尝试从 info[0][15] 获取用户信息（新格式）
      if (first.length > 15 && first[15] != null) {
        final content = first[15];
        if (content is Map) {
          // 解析 extra 获取颜色和官方默认表情
          if (content['extra'] != null) {
            try {
              final Map<String, dynamic> extra = jsonDecode(content['extra']);
              color = extra['color'] ?? 16777215;
              if (extra['emots'] is Map) {
                emoteMap = (extra['emots'] as Map).map(
                  (key, value) => MapEntry(
                    key.toString(),
                    BaseEmote.fromJson(
                        Map<String, dynamic>.from(value as Map)),
                  ),
                );
              }
              // 如果 info[0][13] 没有获取到，尝试从 extra 获取（备用方案）
              if (uemote == null &&
                  extra['emoticon_unique'] != null &&
                  extra['emoticon_unique'].toString().isNotEmpty &&
                  extra['url'] != null) {
                uemote = BaseEmote.fromJson({
                  'emoticon_unique': extra['emoticon_unique'],
                  'url': extra['url'],
                  'width': extra['width'],
                  'height': extra['height'],
                });
              }
            } catch (_) {}
          }
          // 获取用户信息
          final user = content['user'];
          if (user != null) {
            uid = user['uid'];
            final base = user['base'];
            if (base != null) {
              name = base['name'];
            }
          }
        }
      }

      // 弹幕内容在 info[1]
      final String msg = info[1] ?? '';

      // 如果新格式获取用户信息失败，从 info[2] 获取（旧格式）
      if (name == null && info.length > 2 && info[2] is List) {
        final userInfo = info[2];
        if (userInfo.length > 1) {
          uid = uid ?? userInfo[0];
          name = userInfo[1]?.toString();
        }
      }

      name = name ?? '匿名用户';
      uid = uid ?? 0;

      debugPrint('[LiveDanmaku] DANMU_MSG: $name: $msg');

      messages.add(
        DanmakuMsg(
          name: name,
          uid: uid,
          text: msg,
          emots: emoteMap,
          uemote: uemote,
        ),
      );

      // 添加到弹幕控制器
      debugPrint(
          '[LiveDanmaku] showDanmaku: ${showDanmaku.value}, danmakuController: $danmakuController');
      if (showDanmaku.value && danmakuController != null) {
        final danmakuColor = _decimalToColor(color);
        danmakuController!.addDanmaku(DanmakuContentItem(
          msg,
          color: danmakuColor,
        ));
        debugPrint('[LiveDanmaku] Added danmaku to controller: $msg');
      } else {
        debugPrint(
            '[LiveDanmaku] Skipped adding danmaku: showDanmaku=${showDanmaku.value}, controller=${danmakuController != null}');
      }

      if (!disableAutoScroll.value) {
        Future.delayed(const Duration(milliseconds: 100), scrollToBottom);
      }
    } catch (e, stackTrace) {
      debugPrint('[LiveDanmaku] Error parsing DANMU_MSG: $e');
      debugPrint('[LiveDanmaku] StackTrace: $stackTrace');
    }
  }

  void _danmakuListener(dynamic obj) {
    try {
      final String cmd = obj['cmd'] ?? '';
      debugPrint('[LiveDanmaku] Received cmd: $cmd');

      // 处理弹幕消息（支持带版本后缀的格式，如 DANMU_MSG:4:0:2:2:2:0）
      if (cmd == 'DANMU_MSG' || cmd.startsWith('DANMU_MSG:')) {
        _handleDanmuMsg(obj);
        return;
      }

      switch (cmd) {
        case 'INTERACT_WORD':
          // 用户进入直播间 - 只保留最后一条，始终在最底部
          final data = obj['data'];
          final msgType = data['msg_type'] ?? 1;
          // msg_type: 1=进场, 2=关注, 3=分享
          if (msgType != 1) break; // 只处理进场消息

          final uname = data['uname'] ?? '';
          final userUid = data['uid'] ?? 0;

          debugPrint('[LiveDanmaku] INTERACT_WORD: uname=$uname, uid=$userUid');

          if (uname.toString().isEmpty) break;

          // 先移除已有的进入直播间消息
          messages.removeWhere((m) => m.isSystem && m.text == '进入直播间');

          // 再添加到最后，确保始终在底部
          messages.add(
            DanmakuMsg(
              name: uname.toString(),
              uid: userUid is int ? userUid : 0,
              text: '进入直播间',
              isSystem: true,
            ),
          );
          break;

        case 'INTERACT_WORD_V2':
          // V2 版本使用 protobuf 编码，需要解析 base64 的 pb 字段
          final data = obj['data'];
          final pbBase64 = data['pb'];

          if (pbBase64 == null || pbBase64.toString().isEmpty) break;

          try {
            // 解码 base64
            final pbBytes = base64Decode(pbBase64.toString());

            // 简单解析 protobuf 提取用户名
            // 结构: field1=uid(varint), field2=uname(string)
            String uname = '';
            int userUid = 0;

            int i = 0;
            while (i < pbBytes.length) {
              if (i >= pbBytes.length) break;

              final tag = pbBytes[i];
              final fieldNum = tag >> 3;
              final wireType = tag & 0x07;
              i++;

              if (wireType == 0) {
                // Varint
                int value = 0;
                int shift = 0;
                while (i < pbBytes.length) {
                  final b = pbBytes[i];
                  i++;
                  value |= (b & 0x7f) << shift;
                  if ((b & 0x80) == 0) break;
                  shift += 7;
                }
                if (fieldNum == 1) {
                  userUid = value;
                }
              } else if (wireType == 2) {
                // Length-delimited (string/bytes)
                int length = 0;
                int shift = 0;
                while (i < pbBytes.length) {
                  final b = pbBytes[i];
                  i++;
                  length |= (b & 0x7f) << shift;
                  if ((b & 0x80) == 0) break;
                  shift += 7;
                }
                if (fieldNum == 2 && i + length <= pbBytes.length) {
                  // 字段2是用户名
                  uname = utf8.decode(pbBytes.sublist(i, i + length),
                      allowMalformed: true);
                }
                i += length;
              } else {
                // 其他类型，跳过
                break;
              }

              // 只需要前两个字段
              if (userUid > 0 && uname.isNotEmpty) break;
            }

            debugPrint(
                '[LiveDanmaku] INTERACT_WORD_V2 parsed: uname=$uname, uid=$userUid');

            if (uname.isEmpty) break;

            // 先移除已有的进入直播间消息
            messages.removeWhere((m) => m.isSystem && m.text == '进入直播间');

            // 再添加到最后，确保始终在底部
            messages.add(
              DanmakuMsg(
                name: uname,
                uid: userUid,
                text: '进入直播间',
                isSystem: true,
              ),
            );
          } catch (e) {
            debugPrint('[LiveDanmaku] INTERACT_WORD_V2 parse error: $e');
          }
          break;

        case 'SEND_GIFT':
          // 送礼物
          final data = obj['data'];
          messages.add(
            DanmakuMsg(
              name: data['uname'],
              uid: data['uid'],
              text: '送出 ${data['giftName']} x${data['num']}',
              isGift: true,
            ),
          );
          if (!disableAutoScroll.value) {
            Future.delayed(const Duration(milliseconds: 100), scrollToBottom);
          }
          break;
        case 'WATCHED_CHANGE':
          final data = obj['data'];
          final text = data is Map ? data['text_large'] : null;
          if (text is String) {
            _updateWatchedShow(text);
          }
          break;
        case 'ONLINE_RANK_COUNT':
          final data = obj['data'];
          final count = data is Map ? data['count'] : null;
          if (count is num) {
            _updateOnlineCount(count.toInt());
          }
          break;
        case 'ROOM_CHANGE':
          final data = obj['data'];
          final title = data is Map ? data['title'] : null;
          if (title is String) {
            roomInfoH5.update((val) {
              val?.roomInfo?.title = title;
            });
            roomInfoH5.refresh();
          }
          break;
      }
    } catch (e, stackTrace) {
      debugPrint('[LiveDanmaku] 弹幕解析错误: $e');
      debugPrint('[LiveDanmaku] StackTrace: $stackTrace');
    }
  }

  Color _decimalToColor(int decimal) {
    return Color(decimal).withOpacity(1.0);
  }

  void toggleDanmaku() {
    showDanmaku.value = !showDanmaku.value;
    if (!showDanmaku.value) {
      danmakuController?.clear();
    }
  }

  void cancelLikeTimer() {
    likeClickTimer?.cancel();
    likeClickTimer = null;
  }

  void onLikeTapDown([_]) {
    cancelLikeTimer();
    likeClickTime.value++;
  }

  void onLikeTapUp([_]) {
    likeClickTimer ??= Timer(const Duration(milliseconds: 800), () => onLike());
  }

  Future<void> onLike() async {
    if (likeClickTime.value <= 0) {
      return;
    }
    if (!isLogin) {
      SmartDialog.showToast('请先登录');
      likeClickTime.value = 0;
      cancelLikeTimer();
      return;
    }
    final res = await LiveHttp.liveLikeReport(
      clickTime: likeClickTime.value,
      roomId: roomId,
      uid: myMid,
      anchorId: roomInfoH5.value?.roomInfo?.uid,
    );
    if (res['status']) {
      SmartDialog.showToast('点赞成功');
    } else if (res['msg'] != null) {
      SmartDialog.showToast(res['msg']);
    }
    likeClickTime.value = 0;
    cancelLikeTimer();
  }

  Future<void> sendDanmaku(String msg) async {
    if (msg.isEmpty) return;
    final res = await LiveHttp.sendLiveMsg(
      roomId: roomId,
      msg: msg,
    );
    if (res['status']) {
      // 发送成功
    }
  }

  @override
  void onClose() {
    closeLiveMsg();
    cancelLikeTimer();
    cancelLiveTimer();
    messages.clear();
    dmScrollController
      ..removeListener(_scrollListener)
      ..dispose();
    danmakuController?.clear();
    super.onClose();
  }
}
