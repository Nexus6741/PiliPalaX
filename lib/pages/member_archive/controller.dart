import 'package:PiliPalaX/utils/app_scheme.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/http/member.dart';
import 'package:PiliPalaX/models/space_archive/space_archive_item.dart';

// 合集分组信息
class SectionInfo {
  final int? id;
  final String title;
  final int? seasonId;

  SectionInfo({
    this.id,
    required this.title,
    this.seasonId,
  });
}

class MemberArchiveController extends GetxController {
  MemberArchiveController({
    required this.mid,
    this.type = 'video',
    this.seasonId,
    this.seriesId,
  });

  final int mid;
  final String type; // 'video', 'charging', 'season', 'series'
  final int? seasonId;
  final int? seriesId;

  int page = 0; // 使用page而不是pn，从0开始
  int count = 0;
  bool isEnd = false; // 是否已经到达末尾
  int? next; // 用于某些类型的分页
  String? firstAid; // 第一个视频的aid，用于向上加载
  String? lastAid; // 最后一个视频的aid，用于向下加载
  String episodicButtonText = "播放全部";
  String episodicButtonUri = "";
  RxMap<String, String> currentOrder = <String, String>{}.obs;
  List<Map<String, String>> orderList = [
    {'type': 'pubdate', 'label': '最新发布'},
    {'type': 'click', 'label': '最多播放'},
    {'type': 'stow', 'label': '最多收藏'},
  ];
  RxList<SpaceArchiveItem> archivesList = <SpaceArchiveItem>[].obs;

  // 合集分组相关
  RxList<SectionInfo> sections = <SectionInfo>[].obs;
  Rx<SectionInfo?> currentSection = Rx<SectionInfo?>(null);
  RxList<SpaceArchiveItem> allArchivesList = <SpaceArchiveItem>[].obs; // 存储所有视频

  @override
  void onInit() {
    super.onInit();
    currentOrder.value = orderList.first;
  }

  // 获取用户投稿
  Future getMemberArchive(String loadType) async {
    if (loadType == 'init' || loadType == 'refresh') {
      page = 0;
      firstAid = null;
      lastAid = null;
      next = null;
      isEnd = false;
    }
    if (loadType == 'refresh') {
      archivesList.clear();
      allArchivesList.clear();
    }

    // 如果已经到达末尾，直接返回
    if (loadType == 'onLoad' && isEnd) {
      print('Already reached the end, no more data to load');
      return {'status': true, 'msg': 'no more data'};
    }

    print('========== getMemberArchive Request ==========');
    print('Type: $type');
    print('Page: $page');
    print('Season ID: $seasonId');
    print('Series ID: $seriesId');
    print('Last AID: $lastAid');
    print('Next: $next');
    print('Is End: $isEnd');
    print('Load Type: $loadType');
    print('Current Section: ${currentSection.value?.title}');
    print('==============================================');

    // 使用新的spaceArchive API
    var res = await MemberHttp.spaceArchive(
      type: type,
      mid: mid,
      order: currentOrder['type']!,
      pn: type == 'charging' ? page : null,
      aid: type == 'video' ? lastAid : null, // 使用lastAid进行游标分页
      next: (type == 'season' || type == 'series')
          ? next
          : null, // 只有合集类型才使用next参数
      seasonId: seasonId,
      seriesId: seriesId,
    );

    if (res['status']) {
      final data = res['data'];

      print('========== getMemberArchive Response Data ==========');
      print('Data keys: ${data.keys}');
      print('Has has_next: ${data.containsKey('has_next')}');
      if (data.containsKey('has_next')) {
        print('has_next value: ${data['has_next']}');
      }
      print('Has next: ${data.containsKey('next')}');
      if (data.containsKey('next')) {
        print('next value: ${data['next']}');
      }
      print('Item count: ${data['item']?.length ?? 0}');
      if (data['item'] != null && (data['item'] as List).isNotEmpty) {
        print('First item title: ${(data['item'] as List).first['title']}');
        print('Last item title: ${(data['item'] as List).last['title']}');
      }
      print('Current archivesList length: ${archivesList.length}');

      // 检查是否有sections数据
      if (data.containsKey('sections')) {
        print('Has sections: ${data['sections']}');
      }
      print('==============================================');

      // 处理episodicButton
      if (data['episodic_button'] != null) {
        episodicButtonText = data['episodic_button']['text'] ?? "播放全部";
        episodicButtonUri = data['episodic_button']['uri'] ?? "";
      }

      // 处理sections（合集分组）
      if (page == 0 &&
          data['sections'] != null &&
          (data['sections'] as List).isNotEmpty) {
        sections.clear();
        // 添加"全部"选项
        sections.add(SectionInfo(
          id: null,
          title: '全部',
          seasonId: seasonId,
        ));

        // 添加各个分组
        for (var section in data['sections']) {
          sections.add(SectionInfo(
            id: section['id'],
            title: section['title'] ?? '',
            seasonId: section['season_id'],
          ));
        }

        // 默认选中第一个（全部）
        if (currentSection.value == null) {
          currentSection.value = sections.first;
        }

        print('Sections loaded: ${sections.map((s) => s.title).toList()}');
      }

      // 更新next字段（用于某些类型的分页）
      int? oldNext = next;
      next = data['next'];
      print('Next updated: $oldNext -> $next');

      // 处理count
      count = type == 'season'
          ? (data['item']?.length ?? -1)
          : (data['count'] ?? -1);

      // 处理视频列表
      List<dynamic>? items = data['item'];
      if (items != null && items.isNotEmpty) {
        List<SpaceArchiveItem> newList =
            items.map((item) => SpaceArchiveItem.fromJson(item)).toList();

        // 如果page != 0且已有数据，需要合并
        if (page != 0 && allArchivesList.isNotEmpty) {
          // 向下加载，添加到末尾
          allArchivesList.addAll(newList);
        } else {
          // 初始加载或刷新
          allArchivesList.value = newList;
        }

        // 更新firstAid和lastAid
        if (allArchivesList.isNotEmpty) {
          firstAid = allArchivesList.first.param;
          lastAid = allArchivesList.last.param;
          print('Updated firstAid: $firstAid, lastAid: $lastAid');
        }

        // 根据当前选中的section筛选视频
        _filterArchivesBySection();
      }

      // 检查是否还有更多数据 - 完全按照PiliPlus的逻辑
      // 在处理完数据后检查
      if (page == 0 || loadType != 'init') {
        // 对于video类型，检查has_next字段
        // 对于其他类型（season/series），检查next字段
        // 注意：next可能是null或0，都表示没有更多数据
        bool shouldEnd = (type == 'video'
                ? data['has_next'] == false
                : (data['next'] == null || data['next'] == 0)) ||
            data['item'] == null ||
            (data['item'] as List).isEmpty;

        print('========== isEnd Check ==========');
        print('page: $page, loadType: $loadType');
        print('type: $type');
        print('has_next: ${data['has_next']}');
        print('next: ${data['next']}');
        print(
            'item is null or empty: ${data['item'] == null || (data['item'] as List).isEmpty}');
        print('shouldEnd: $shouldEnd');
        print('=================================');

        if (shouldEnd) {
          isEnd = true;
        }
      }

      page += 1;

      return {'status': true};
    } else {
      SmartDialog.showToast(res['msg']);
      return {'status': false, 'msg': res['msg']};
    }
  }

  // 根据选中的section筛选视频
  void _filterArchivesBySection() {
    if (currentSection.value == null || currentSection.value!.id == null) {
      // 显示全部
      archivesList.value = allArchivesList;
    } else {
      // 根据sectionId筛选
      archivesList.value = allArchivesList.where((item) {
        return item.sectionId == currentSection.value!.id;
      }).toList();
    }
    print('Filtered archives: ${archivesList.length} items');
  }

  // 切换section
  void changeSection(SectionInfo section) {
    currentSection.value = section;
    _filterArchivesBySection();
  }

  toggleSort() async {
    List<String> typeList = orderList.map((e) => e['type']!).toList();
    int index = typeList.indexOf(currentOrder['type']!);
    if (index == orderList.length - 1) {
      currentOrder.value = orderList.first;
    } else {
      currentOrder.value = orderList[index + 1];
    }
    // 切换排序时重置状态
    isEnd = false;
    firstAid = null;
    lastAid = null;
    next = null;
    getMemberArchive('init');
  }

  episodicButton() async {
    if (episodicButtonUri.isNotEmpty) {
      PiliScheme.routePush(Uri.parse('https:$episodicButtonUri'));
    } else {
      SmartDialog.showToast('暂无播放链接');
    }
  }

  // 上拉加载
  Future onLoad() async {
    await getMemberArchive('onLoad');
  }

  Future onRefresh() async {
    await getMemberArchive('refresh');
  }
}
