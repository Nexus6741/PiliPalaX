import 'dart:convert';
import 'dart:developer';
import 'package:PiliPalaX/http/constants.dart';
import 'package:PiliPalaX/http/init.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:PiliPalaX/http/member.dart';
import 'package:PiliPalaX/http/user.dart';
import 'package:PiliPalaX/http/video.dart';
import 'package:PiliPalaX/models/member/space_data.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import 'package:PiliPalaX/pages/video/introduction/widgets/group_panel.dart';

class MemberController extends GetxController with GetTickerProviderStateMixin {
  int? mid;
  MemberController({this.mid});

  // 使用新的SpaceData模型
  Rx<SpaceData?> spaceData = Rx<SpaceData?>(null);

  // 便捷访问器
  SpaceCard? get card => spaceData.value?.card;
  SpaceImages? get images => spaceData.value?.images;
  SpaceLive? get live => spaceData.value?.live;
  List<SpaceTab2>? get tab2 => spaceData.value?.tab2;
  int? get silence => spaceData.value?.silence;

  RxString face = ''.obs;
  String? heroTag;
  Box userInfoCache = GStorage.userInfo;
  late int ownerMid;
  bool specialFollowed = false;
  dynamic userInfo;
  RxInt relation = 0.obs; // 关注状态：0-未关注, 1-悄悄关注, 2-已关注, 6-已互关, 128-已拉黑, -10-特别关注
  RxString relationText = '关注'.obs;
  String? wwebid;
  late TabController tabController;

  // 加载状态
  RxBool isLoading = true.obs;
  RxString errorMsg = ''.obs;

  @override
  void onInit() async {
    super.onInit();
    mid = mid ?? int.parse(Get.parameters['mid']!);
    userInfo = userInfoCache.get('userInfoCache');
    ownerMid = userInfo?.mid ?? -1;
    face.value = Get.arguments?['face'] ?? '';
    heroTag = Get.arguments?['heroTag'] ?? '';

    // 初始化TabController，默认3个Tab，后续根据API返回动态调整
    tabController = TabController(length: 3, vsync: this);

    // 加载数据
    await loadSpaceData();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  // 加载用户空间数据
  Future<void> loadSpaceData() async {
    try {
      isLoading.value = true;
      errorMsg.value = '';

      // 获取wwebid
      await getWwebid();

      // 调用新的space接口
      var res = await MemberHttp.space(
        mid: mid!,
        fromViewAid: Get.parameters['from_view_aid'],
      );

      if (res['status']) {
        spaceData.value = res['data'] as SpaceData;
        face.value = card?.face ?? '';

        // 设置关系状态
        if (spaceData.value?.relation != null) {
          if (spaceData.value!.relation == -1) {
            relation.value = 128; // 已拉黑
          } else {
            relation.value = card?.relation?.isFollow == 1
                ? (spaceData.value?.relSpecial == 1
                    ? -10
                    : card?.relation?.status ?? 2)
                : 0;
          }
        }

        // 更新关系文本
        updateRelationText();

        // 配置动态Tab
        configureTabs();

        // 查询详细关系（如果需要）
        if (userInfo != null && mid != ownerMid) {
          await relationSearch();
        }
      } else {
        errorMsg.value = res['msg'] ?? '加载失败';
        SmartDialog.showToast(errorMsg.value);
      }
    } catch (e) {
      errorMsg.value = '加载失败: $e';
      log('loadSpaceData error: $e');
      SmartDialog.showToast(errorMsg.value);
    } finally {
      isLoading.value = false;
    }
  }

  // 配置动态Tab
  void configureTabs() {
    if (tab2 == null || tab2!.isEmpty) {
      // 使用默认Tab配置
      return;
    }

    // 过滤掉不支持的Tab
    final supportedTabs = tab2!.where((tab) {
      return ['home', 'dynamic', 'contribute', 'bangumi', 'favorite']
          .contains(tab.param);
    }).toList();

    if (supportedTabs.isEmpty) {
      return;
    }

    // 重新创建TabController
    tabController.dispose();

    // 确定初始Tab索引
    int initialIndex = 0;
    final defaultTab = spaceData.value?.defaultTab;
    if (defaultTab != null) {
      final index = supportedTabs.indexWhere((tab) => tab.param == defaultTab);
      if (index != -1) {
        initialIndex = index;
      }
    }

    tabController = TabController(
      length: supportedTabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  Future getWwebid() async {
    try {
      dynamic response = await Request().get(
        '${HttpString.spaceBaseUrl}/$mid',
        extra: {'ua': 'pc'},
      );
      dom.Document document = html_parser.parse(response.data);
      dom.Element? scriptElement =
          document.querySelector('script#__RENDER_DATA__');
      if (scriptElement != null) {
        wwebid =
            jsonDecode(Uri.decodeComponent(scriptElement.text))['access_id'];
      }
    } catch (e) {
      log('failed to get wwebid: $e');
    }
  }

  // 更新关系文本
  void updateRelationText() {
    switch (relation.value) {
      case 1:
        relationText.value = '悄悄关注';
        break;
      case 2:
        relationText.value = '已关注';
        break;
      case 6:
        relationText.value = '已互关';
        break;
      case 128:
        relationText.value = '已拉黑';
        break;
      case -10:
        relationText.value = '特别关注';
        break;
      default:
        relationText.value = '关注';
    }

    if (specialFollowed) {
      relationText.value += ' 🔔';
    }
  }

  // 关注/取关up
  Future actionRelationMod(BuildContext context) async {
    if (userInfo == null) {
      SmartDialog.showToast('账号未登录');
      return;
    }

    // 如果是自己，跳转到编辑资料
    if (mid == ownerMid) {
      Get.toNamed('/webview', parameters: {
        'url': 'https://account.bilibili.com/account/home',
        'pageTitle': '个人中心',
        'type': 'url'
      });
      return;
    }

    if (relation.value == 128) {
      blockUser(context);
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('操作'),
          actions: [
            if (relation.value != 0 && relation.value != 128) ...[
              TextButton(
                onPressed: () async {
                  final res = await MemberHttp.addUsers(
                      mid, specialFollowed ? '0' : '-10');
                  SmartDialog.showToast(res['msg']);
                  if (res['status']) {
                    specialFollowed = !specialFollowed;
                    updateRelationText();
                  }
                  Get.back();
                },
                child: Text(specialFollowed ? '移除特别关注' : '加入特别关注'),
              ),
              TextButton(
                onPressed: () async {
                  await Get.bottomSheet(
                    GroupPanel(mid: mid),
                    isScrollControlled: true,
                  );
                  Get.back();
                },
                child: const Text('设置分组'),
              ),
            ],
            TextButton(
              onPressed: () async {
                var res = await VideoHttp.relationMod(
                  mid: mid!,
                  act: relation.value != 0 ? 2 : 1,
                  reSrc: 11,
                );
                SmartDialog.showToast(res['status'] ? "操作成功" : res['msg']);
                if (res['status']) {
                  relation.value = relation.value != 0 ? 0 : 2;
                  updateRelationText();
                }
                Get.back();
              },
              child: Text(relation.value != 0 ? '取消关注' : '关注'),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                '取消',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
          ],
        );
      },
    );

    // 延迟更新关系状态
    await Future.delayed(const Duration(milliseconds: 1000), () async {
      await relationSearch();
    });
  }

  // 关系查询
  Future relationSearch() async {
    if (userInfo == null) return;
    if (mid == ownerMid) return;

    var res = await UserHttp.hasFollow(mid!);
    if (res['status']) {
      relation.value = res['data']['attribute'];

      if (res['data']['special'] == 1) {
        specialFollowed = true;
        if (relation.value != 0 && relation.value != 128) {
          relation.value = -10; // 特别关注
        }
      } else {
        specialFollowed = false;
      }

      updateRelationText();
    } else {
      log('relationSearch error: ${res['msg']}');
    }
  }

  // 拉黑用户
  Future blockUser(BuildContext context) async {
    if (userInfo == null) {
      SmartDialog.showToast('账号未登录');
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: Text(relation.value != 128 ? '确定拉黑UP主?' : '从黑名单移除UP主'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                '点错了',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                var res = await VideoHttp.relationMod(
                  mid: mid!,
                  act: relation.value != 128 ? 5 : 6,
                  reSrc: 11,
                );
                if (res['status']) {
                  relation.value = relation.value != 128 ? 128 : 0;
                  updateRelationText();
                  await relationSearch();
                }
              },
              child: const Text('确认'),
            )
          ],
        );
      },
    );
  }

  // 移除粉丝
  Future removeFan() async {
    if (userInfo == null) {
      SmartDialog.showToast('账号未登录');
      return;
    }

    final res = await VideoHttp.relationMod(mid: mid!, act: 7, reSrc: 11);
    if (res['status']) {
      // 更新关系状态
      if (relation.value == 6) {
        relation.value = 2; // 从互关变为已关注
      }
      updateRelationText();
      SmartDialog.showToast('移除成功');
    } else {
      SmartDialog.showToast(res['msg']);
    }
  }

  void shareUser() {
    final name = card?.name ?? '';
    Share.share('$name - https://space.bilibili.com/$mid');
  }

  // 刷新数据
  Future<void> refresh() async {
    await loadSpaceData();
  }
}
