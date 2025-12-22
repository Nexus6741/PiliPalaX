import 'package:get/get.dart';
import 'package:PiliPalaX/http/loading_state.dart';
import 'package:PiliPalaX/http/login.dart';
import 'package:PiliPalaX/models/login_devices/login_device.dart';

class LoginDevicesController extends GetxController {
  Rx<LoadingState<List<LoginDevice>?>> loadingState =
      Rx<LoadingState<List<LoginDevice>?>>(LoadingState.loading());

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  Future<void> queryData() async {
    print('========== LoginDevices queryData START ==========');
    loadingState.value = LoadingState.loading();
    try {
      print('Calling LoginHttp.loginDevices()...');
      var result = await LoginHttp.loginDevices();
      print('LoginHttp.loginDevices() result: $result');

      if (result['status']) {
        final List<LoginDevice>? devices = result['data'];
        print('Devices count: ${devices?.length ?? 0}');
        if (devices != null && devices.isNotEmpty) {
          for (var i = 0; i < devices.length; i++) {
            print('Device $i: ${devices[i].deviceName}');
          }
        }
        loadingState.value = Success<List<LoginDevice>?>(devices);
        print('LoadingState set to Success');
      } else {
        print('API returned error: ${result['msg']}');
        loadingState.value = Error<List<LoginDevice>?>(result['msg'] ?? '加载失败');
      }
    } catch (e, stackTrace) {
      print('Exception in queryData: $e');
      print('StackTrace: $stackTrace');
      loadingState.value = Error<List<LoginDevice>?>(e.toString());
    }
    print('========== LoginDevices queryData END ==========');
  }

  Future<void> onRefresh() async {
    await queryData();
  }

  Future<void> onReload() async {
    await queryData();
  }
}
