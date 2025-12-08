import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/http/pgc.dart';
import 'package:PiliPalaX/models/pgc/fav_pgc/data.dart';
import 'package:PiliPalaX/models/pgc/fav_pgc/list.dart';
import 'package:PiliPalaX/models/pgc/pgc_index_result/list.dart';
import 'package:PiliPalaX/pages/common/common_controller.dart';
import 'package:PiliPalaX/utils/extension.dart';
import 'package:PiliPalaX/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

enum PgcTabType {
  bangumi, // 番剧
  cinema, // 影视
}

class PgcController
    extends CommonListController<List<PgcIndexItem>?, PgcIndexItem> {
  PgcController({required this.tabType});

  final PgcTabType tabType;

  // 用户信息
  Box userInfoCache = GStorage.userInfo;
  late bool isLogin;
  late int? mid;

  @override
  void onInit() {
    super.onInit();

    final userInfo = userInfoCache.get('userInfoCache');
    isLogin = userInfo != null;
    mid = userInfo?.mid;

    // 初始化数据
    queryData();
    if (isLogin) {
      queryPgcFollow();
      followController = ScrollController();
    }
  }

  @override
  Future<void> onRefresh() {
    if (isLogin) {
      followPage = 1;
      followEnd = false;
      queryPgcFollow();
    }
    return super.onRefresh();
  }

  // ==================== 追剧相关 ====================
  late int followPage = 1;
  late RxInt followCount = (-1).obs;
  late bool followLoading = false;
  late bool followEnd = false;
  late Rx<LoadingState<List<FavPgcItemModel>?>> followState =
      Rx<LoadingState<List<FavPgcItemModel>?>>(LoadingState.loading());
  ScrollController? followController;

  /// 获取追剧列表
  Future<void> queryPgcFollow([bool isRefresh = true]) async {
    if (!isLogin || followLoading || (!isRefresh && followEnd)) {
      return;
    }

    followLoading = true;

    var result = await PgcHttp.favPgc(
      mid: mid!,
      type: tabType == PgcTabType.bangumi ? 1 : 2, // 1=番剧, 2=影视
      pn: followPage,
    );

    if (result['status']) {
      final FavPgcData data = result['data'];
      final List<FavPgcItemModel>? list = data.list;
      followCount.value = data.total ?? -1;

      if (list == null || list.isEmpty) {
        followEnd = true;
        if (isRefresh) {
          followState.value = Success(list);
        }
        followLoading = false;
        return;
      }

      if (isRefresh) {
        if (list.length >= followCount.value) {
          followEnd = true;
        }
        followState.value = Success(list);
        followController?.animToTop();
      } else if (followState.value.isSuccess) {
        final currentList = followState.value.data!..addAll(list);
        if (currentList.length >= followCount.value) {
          followEnd = true;
        }
        followState.refresh();
      }
      followPage++;
    } else if (isRefresh) {
      followState.value = Error(result['msg']);
    }

    followLoading = false;
  }

  // ==================== 推荐内容相关 ====================

  @override
  Future<LoadingState<List<PgcIndexItem>?>> customGetData() async {
    var result = await PgcHttp.pgcIndex(
      page: page,
      indexType: tabType == PgcTabType.cinema ? 102 : null, // 102=全部影视, null=番剧
    );

    if (result['status']) {
      return Success(result['data'] as List<PgcIndexItem>?);
    } else {
      return Error(result['msg']);
    }
  }

  @override
  void onClose() {
    followController?.dispose();
    super.onClose();
  }
}
