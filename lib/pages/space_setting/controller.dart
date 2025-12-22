import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/http/user.dart';
import 'package:PiliPalaX/models/space_setting/privacy.dart';

class SpaceSettingController extends GetxController {
  Rx<LoadingState<Privacy?>> loadingState =
      Rx<LoadingState<Privacy?>>(LoadingState.loading());
  bool? hasMod;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  void onClose() {
    onMod();
    super.onClose();
  }

  Future<void> queryData() async {
    print('========== SpaceSetting queryData START ==========');
    loadingState.value = LoadingState.loading();
    try {
      print('Calling UserHttp.spaceSetting()...');
      var result = await UserHttp.spaceSetting();
      print('UserHttp.spaceSetting() result: $result');

      if (result['status']) {
        final Privacy? privacy = result['data'];
        print('Privacy data: ${privacy != null ? "exists" : "null"}');
        if (privacy != null) {
          print('List1 count: ${privacy.list1.length}');
          print('List2 count: ${privacy.list2.length}');
          print('List3 count: ${privacy.list3.length}');
        }
        loadingState.value = Success<Privacy?>(privacy);
        print('LoadingState set to Success');
      } else {
        print('API returned error: ${result['msg']}');
        loadingState.value = Error<Privacy?>(result['msg'] ?? '加载失败');
      }
    } catch (e, stackTrace) {
      print('Exception in queryData: $e');
      print('StackTrace: $stackTrace');
      loadingState.value = Error<Privacy?>(e.toString());
    }
    print('========== SpaceSetting queryData END ==========');
  }

  Future<void> onReload() async {
    await queryData();
  }

  Future<void> onMod() async {
    if ((hasMod ?? false) && loadingState.value.isSuccess) {
      Privacy? data = loadingState.value.data;
      if (data != null) {
        var res = await UserHttp.spaceSettingMod(
          {
            for (var e in data.list1) e.key: e.value ?? 0,
            for (var e in data.list2) e.key: e.value ?? 0,
            for (var e in data.list3) e.key: e.value ?? 0,
          },
        );
        if (!res['status']) {
          SmartDialog.showToast(res['msg'] ?? '保存失败');
        } else {
          SmartDialog.showToast('保存成功');
        }
      }
    }
  }
}
