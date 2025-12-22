import 'package:get/get.dart';
import 'package:PiliPalaX/http/loading_state.dart';

abstract class LogController<R, T> extends GetxController {
  late Rx<LoadingState<List<T>?>> loadingState;

  @override
  void onInit() {
    super.onInit();
    loadingState = Rx<LoadingState<List<T>?>>(LoadingState.loading());
    queryData();
  }

  String get title;
  T get header;
  List<LogColumnData> getFlexAndText(T item);

  Future<void> queryData() async {
    print('========== LogController queryData START ==========');
    print('Controller type: $runtimeType');
    loadingState.value = LoadingState.loading();
    try {
      print('Calling customGetData()...');
      var result = await customGetData();
      print('customGetData() result: $result');

      if (result['status']) {
        final data = result['data'];
        print('Data type: ${data.runtimeType}');
        print('Calling getDataList()...');
        final list = getDataList(data);
        print('List count: ${list?.length ?? 0}');
        loadingState.value = Success<List<T>?>(list);
        print('LoadingState set to Success');
      } else {
        print('API returned error: ${result['msg']}');
        loadingState.value = Error<List<T>?>(result['msg'] ?? '加载失败');
      }
    } catch (e, stackTrace) {
      print('Exception in queryData: $e');
      print('StackTrace: $stackTrace');
      loadingState.value = Error<List<T>?>(e.toString());
    }
    print('========== LogController queryData END ==========');
  }

  Future<Map<String, dynamic>> customGetData();
  List<T>? getDataList(dynamic data);

  Future<void> onReload() async {
    await queryData();
  }
}

class LogColumnData {
  final int flex;
  final String text;

  LogColumnData(this.flex, this.text);
}
