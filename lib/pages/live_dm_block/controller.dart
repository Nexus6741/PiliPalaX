import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/http/live.dart';

class LiveDmBlockController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final roomId = Get.parameters['roomId'];

  late final TabController tabController = TabController(
    length: 2,
    vsync: this,
  );

  final RxList<String> keywordList = <String>[].obs;
  final RxList<Map<String, dynamic>> shieldUserList =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> queryData() async {
    isLoading.value = true;
    try {
      var res = await LiveHttp.getLiveShieldInfo(roomId);
      if (res['status']) {
        final data = res['data'];
        if (data != null) {
          keywordList.value = List<String>.from(data['keyword_list'] ?? []);
          shieldUserList.value =
              List<Map<String, dynamic>>.from(data['shield_user_list'] ?? []);
        }
      } else {
        SmartDialog.showToast(res['msg'] ?? '获取屏蔽信息失败');
      }
    } catch (e) {
      SmartDialog.showToast('获取屏蔽信息失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addKeyword(String keyword) async {
    if (keyword.isEmpty) return;
    var res = await LiveHttp.addShieldKeyword(keyword: keyword);
    if (res['status']) {
      keywordList.insert(0, keyword);
      SmartDialog.showToast('添加成功');
    } else {
      SmartDialog.showToast(res['msg'] ?? '添加失败');
    }
  }

  Future<void> removeKeyword(int index, String keyword) async {
    var res = await LiveHttp.delShieldKeyword(keyword: keyword);
    if (res['status']) {
      keywordList.removeAt(index);
      SmartDialog.showToast('删除成功');
    } else {
      SmartDialog.showToast(res['msg'] ?? '删除失败');
    }
  }

  Future<void> addShieldUser(String uid) async {
    if (uid.isEmpty) return;
    var res = await LiveHttp.liveShieldUser(
      uid: uid,
      roomid: roomId,
      type: 1,
    );
    if (res['status']) {
      final data = res['data'];
      shieldUserList.insert(0, {
        'uid': data['uid'],
        'uname': data['uname'],
      });
      SmartDialog.showToast('添加成功');
    } else {
      SmartDialog.showToast(res['msg'] ?? '添加失败');
    }
  }

  Future<void> removeShieldUser(int index, dynamic uid) async {
    var res = await LiveHttp.liveShieldUser(
      uid: uid,
      roomid: roomId,
      type: 0,
    );
    if (res['status']) {
      shieldUserList.removeAt(index);
      SmartDialog.showToast('删除成功');
    } else {
      SmartDialog.showToast(res['msg'] ?? '删除失败');
    }
  }
}
