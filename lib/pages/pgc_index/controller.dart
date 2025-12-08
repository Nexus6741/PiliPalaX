import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/http/pgc.dart';
import 'package:PiliPalaX/models/pgc/pgc_index_condition/data.dart';
import 'package:PiliPalaX/models/pgc/pgc_index_condition/sort.dart';
import 'package:PiliPalaX/models/pgc/pgc_index_result/list.dart';
import 'package:PiliPalaX/pages/common/common_controller.dart';
import 'package:get/get.dart';

class PgcIndexController
    extends CommonListController<List<PgcIndexItem>?, PgcIndexItem> {
  PgcIndexController({this.indexType});

  int? indexType; // 索引类型 (102=全部, 2=电影, 5=电视剧, 3=纪录片, 7=综艺)
  String tag = ''; // GetX tag for controller identification

  // 筛选条件相关
  late Rx<LoadingState<PgcIndexConditionData?>> conditionState =
      Rx<LoadingState<PgcIndexConditionData?>>(LoadingState.loading());
  late final RxBool isExpand = false.obs;
  RxMap<String, dynamic> indexParams = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // 初始化筛选条件
    getPgcIndexCondition();
    // 加载内容
    queryData();
  }

  /// 获取索引筛选条件
  Future<void> getPgcIndexCondition() async {
    conditionState.value = LoadingState.loading();
    // 番剧索引(indexType==null)使用seasonType=1
    // 影视索引(indexType!=null)不传seasonType，使用indexType区分类型
    var result = await PgcHttp.pgcIndexCondition(
      seasonType: indexType == null ? 1 : null,
      type: 0,
      indexType: indexType,
    );

    if (result['status']) {
      final data = result['data'] as PgcIndexConditionData;

      // 初始化默认筛选参数
      if (data.order?.isNotEmpty == true) {
        indexParams['order'] = data.order!.first.field;
      }
      if (data.filter?.isNotEmpty == true) {
        for (PgcConditionFilter item in data.filter!) {
          indexParams['${item.field}'] = item.values?.isNotEmpty == true
              ? item.values!.first.keyword
              : null;
        }
      }

      conditionState.value = Success(data);
    } else {
      conditionState.value = Error(result['msg']);
    }
  }

  /// 加载索引内容
  @override
  Future<LoadingState<List<PgcIndexItem>?>> customGetData() async {
    // 番剧索引(indexType==null)使用seasonType=1
    // 影视索引(indexType!=null)不传seasonType，使用indexType区分类型
    var result = await PgcHttp.pgcIndexResult(
      page: page,
      params: indexParams,
      seasonType: indexType == null ? 1 : null,
      type: 0,
      indexType: indexType,
    );

    if (result['status']) {
      return Success(result['data'].list as List<PgcIndexItem>?);
    } else {
      return Error(result['msg']);
    }
  }

  /// 更新筛选参数
  void updateIndexParams(String key, dynamic value) {
    indexParams[key] = value;
    // 重置页码并重新加载
    page = 1;
    queryData();
  }

  /// 更新排序选项和排序方向
  /// [order] 排序字段
  /// [sort] 排序方向：0=降序, 1=升序
  void updateOrderSort(String order, int sort) {
    indexParams['order'] = order;
    indexParams['sort'] = sort;
    // 重置页码并重新加载
    page = 1;
    queryData();
  }

  /// 切换筛选条件展开/收起
  void toggleExpand() {
    isExpand.value = !isExpand.value;
  }
}
