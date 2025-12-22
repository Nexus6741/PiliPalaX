import 'package:PiliPalaX/http/user.dart';
import 'package:PiliPalaX/models/exp_log/exp_log_item.dart';
import 'package:PiliPalaX/pages/log_table/controller.dart';

class ExpLogController extends LogController<dynamic, ExpLogItem> {
  @override
  List<ExpLogItem>? getDataList(dynamic data) {
    if (data is Map<String, dynamic> && data['list'] != null) {
      return (data['list'] as List).map((e) => ExpLogItem.fromJson(e)).toList();
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> customGetData() => UserHttp.expLog();

  @override
  List<LogColumnData> getFlexAndText(ExpLogItem item) {
    return [
      LogColumnData(3, item.time),
      LogColumnData(2, item.delta),
      LogColumnData(3, item.reason),
    ];
  }

  @override
  final ExpLogItem header = const ExpLogItem(
    time: '时间',
    delta: '变化',
    reason: '原因',
  );

  @override
  final String title = '经验记录';
}
