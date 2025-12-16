import 'package:get/get.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/http/pgc.dart';
import 'package:PiliPalaX/models/pgc/rank_item.dart';

enum RankType {
  bangumi, // 番剧+国创
  cinema, // 影视（电影+电视剧+纪录片+综艺）
}

class PgcRankController extends GetxController {
  PgcRankController({this.rankType = RankType.bangumi});

  final RankType rankType;

  // 当前选中的tab索引
  final RxInt currentTabIndex = 0.obs;

  // 排行榜数据缓存 (seasonType -> LoadingState)
  final RxMap<int, Rx<LoadingState<List<PgcRankItem>>>> rankStates = RxMap();

  // 获取当前Tab对应的seasonType
  List<int> get seasonTypes {
    if (rankType == RankType.bangumi) {
      return [1, 4]; // 番剧、国创
    } else {
      return [2, 5, 3, 7]; // 电影、电视剧、纪录片、综艺
    }
  }

  @override
  void onInit() {
    super.onInit();
    // 初始化所有tab的状态
    for (var seasonType in seasonTypes) {
      rankStates[seasonType] =
          Rx<LoadingState<List<PgcRankItem>>>(LoadingState.loading());
    }
    // 加载第一个tab的数据
    loadRank(seasonTypes[0]);
  }

  /// 切换Tab
  void switchTab(int index) {
    currentTabIndex.value = index;
    final seasonType = seasonTypes[index];
    if (rankStates[seasonType]!.value is! Success) {
      loadRank(seasonType);
    }
  }

  /// 加载排行榜
  Future<void> loadRank(int seasonType) async {
    rankStates[seasonType]!.value = LoadingState.loading();
    final result = await PgcHttp.pgcRankList(seasonType: seasonType, day: 3);

    if (result['status']) {
      final list = (result['data'] as List)
          .map((item) => PgcRankItem.fromJson(item))
          .toList();
      rankStates[seasonType]!.value = Success(list);
    } else {
      rankStates[seasonType]!.value = Error(result['msg']);
    }
  }

  /// 刷新当前Tab的数据
  Future<void> onRefresh() async {
    final seasonType = seasonTypes[currentTabIndex.value];
    await loadRank(seasonType);
  }
}
