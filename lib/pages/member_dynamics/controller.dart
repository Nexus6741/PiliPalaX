import 'package:get/get.dart';
import 'package:PiliPalaX/http/member.dart';
import 'package:PiliPalaX/models/dynamics/result.dart';

class MemberDynamicsController extends GetxController {
  MemberDynamicsController({required this.mid});
  final int mid;
  String offset = '';
  bool isEnd = false;
  bool isLoading = false;
  RxList<DynamicItemModel> dynamicsList = <DynamicItemModel>[].obs;
  Rx<LoadingState> loadingState = Rx<LoadingState>(LoadingState.loading());

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  Future<void> queryData([bool isRefresh = true]) async {
    if (isLoading || (!isRefresh && isEnd)) {
      return;
    }

    isLoading = true;

    if (isRefresh) {
      offset = '';
      isEnd = false;
    }

    if (offset == '-1') {
      isEnd = true;
      isLoading = false;
      return;
    }

    var res = await MemberHttp.memberDynamic(
      offset: offset,
      mid: mid,
    );

    if (res['status']) {
      DynamicsDataModel data = res['data'];
      List<DynamicItemModel> items = data.items ?? [];

      if (isRefresh) {
        dynamicsList.value = items;
      } else {
        dynamicsList.addAll(items);
      }

      offset = data.offset?.isNotEmpty == true ? data.offset! : '-1';
      isEnd = !(data.hasMore ?? false) || offset == '-1';
      loadingState.value = LoadingState.success();
    } else {
      if (isRefresh) {
        loadingState.value = LoadingState.error(res['msg']);
      }
    }

    isLoading = false;
  }

  // 上拉加载
  Future<void> onLoad() async {
    await queryData(false);
  }

  // 下拉刷新
  Future<void> onRefresh() async {
    await queryData(true);
  }

  Future<void> onReload() async {
    loadingState.value = LoadingState.loading();
    await queryData(true);
  }
}

class LoadingState {
  final LoadingStateType type;
  final String? errMsg;

  LoadingState.loading()
      : type = LoadingStateType.loading,
        errMsg = null;
  LoadingState.success()
      : type = LoadingStateType.success,
        errMsg = null;
  LoadingState.error(this.errMsg) : type = LoadingStateType.error;

  bool get isLoading => type == LoadingStateType.loading;
  bool get isSuccess => type == LoadingStateType.success;
  bool get isError => type == LoadingStateType.error;
}

enum LoadingStateType {
  loading,
  success,
  error,
}
