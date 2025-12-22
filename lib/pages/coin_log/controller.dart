import 'package:PiliPalaX/http/user.dart';
import 'package:PiliPalaX/models/coin_log/coin_log_item.dart';
import 'package:PiliPalaX/pages/log_table/controller.dart';

class CoinLogController extends LogController<dynamic, CoinLogItem> {
  @override
  List<CoinLogItem>? getDataList(dynamic data) {
    if (data is Map<String, dynamic> && data['list'] != null) {
      return (data['list'] as List)
          .map((e) => CoinLogItem.fromJson(e))
          .toList();
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> customGetData() => UserHttp.coinLog();

  @override
  List<LogColumnData> getFlexAndText(CoinLogItem item) {
    return [
      LogColumnData(3, item.time),
      LogColumnData(2, item.delta),
      LogColumnData(3, item.reason),
    ];
  }

  @override
  final CoinLogItem header = const CoinLogItem(
    time: '时间',
    delta: '变化',
    reason: '原因',
  );

  @override
  final String title = '硬币记录';
}
