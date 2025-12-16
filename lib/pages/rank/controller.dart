import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RankController extends GetxController {
  late TabController tabController;

  // 排行榜分类
  // 根据网页端哔哩哔哩排行榜的分类
  final List<Map<String, dynamic>> tabs = [
    {'label': '全站', 'rid': 0, 'tid': null},
    {'label': '动画', 'rid': 1, 'tid': null},
    {'label': '国创', 'rid': 168, 'tid': null},
    {'label': '音乐', 'rid': 3, 'tid': null},
    {'label': '舞蹈', 'rid': 129, 'tid': null},
    {'label': '游戏', 'rid': 4, 'tid': null},
    {'label': '知识', 'rid': 36, 'tid': null},
    {'label': '科技', 'rid': 188, 'tid': null},
    {'label': '运动', 'rid': 234, 'tid': null},
    {'label': '汽车', 'rid': 223, 'tid': null},
    {'label': '生活', 'rid': 160, 'tid': null},
    {'label': '美食', 'rid': 211, 'tid': null},
    {'label': '动物圈', 'rid': 217, 'tid': null},
    {'label': '鬼畜', 'rid': 119, 'tid': null},
    {'label': '时尚', 'rid': 155, 'tid': null},
    {'label': '娱乐', 'rid': 5, 'tid': null},
    {'label': '影视', 'rid': 181, 'tid': null},
    {'label': '原创', 'rid': 0, 'tid': null, 'type': 'origin'},
    {'label': '新人', 'rid': 0, 'tid': null, 'type': 'rookie'},
  ];

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
